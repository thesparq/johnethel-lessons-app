///|
/// User agent — durable per-user instance with caching.
#derive.agent
struct UserAgent {
  user_id : String
  role : String
  // Cache: key → (json_data, expiry_seconds)
  cache : Map[String, (String, UInt64)]
}

///|
fn UserAgent::new(user_id : String, role : String) -> UserAgent {
  { user_id, role, cache: {} }
}

///|
fn UserAgent::cache_get(self : Self, key : String) -> String? {
  match self.cache.get(key) {
    Some((data, expiry)) => {
      let now = @wallClock.now().seconds
      if now < expiry {
        Some(data)
      } else {
        self.cache.remove(key)
        None
      }
    }
    None => None
  }
}

///|
fn UserAgent::cache_set(self : Self, key : String, data : String, ttl_secs : UInt64) -> Unit {
  let expiry = @wallClock.now().seconds + ttl_secs
  self.cache[key] = (data, expiry)
}

///|
fn UserAgent::cache_invalidate(self : Self, key : String) -> Unit {
  self.cache.remove(key)
}

///|
fn get_env(name : String) -> String {
  let envs = @environment.get_environment()
  for pair in envs {
    if pair.0 == name {
      return pair.1
    }
  }
  ""
}

///|
fn base64_encode(s : String) -> String {
  let bytes = Bytes::from_fixedarray(str_to_bytes(s))
  @base64.encode(bytes.view())
}

///|
fn str_to_bytes(s : String) -> FixedArray[Byte] {
  let bytes = FixedArray::make(s.length(), b'\x00')
  for i = 0; i < s.length(); i = i + 1 {
    bytes[i] = s[i].to_int().to_byte()
  }
  bytes
}

///|
fn bytes_to_str(bytes : FixedArray[Byte]) -> String {
  String::from_array(bytes.map(fn(b) { b.to_int().unsafe_to_char() }))
}

///|
fn surreal_url_parts() -> (@httpTypes.Scheme, String, String) {
  let url = get_env("SURREALDB_URL")
  let scheme = if url.has_prefix("https://") {
    @httpTypes.Scheme::Https
  } else {
    @httpTypes.Scheme::Http
  }
  let rest = if url.has_prefix("https://") {
    url["https://".length():].to_owned()
  } else if url.has_prefix("http://") {
    url["http://".length():].to_owned()
  } else {
    url
  }
  let parts = rest.split("/").to_array()
  let authority = parts[0].to_owned()
  let base_path = if parts.length() > 1 {
    let tail = parts[1:].iter().map(fn(sv) { sv.to_owned() }).to_array()
    "/" + tail.join("/")
  } else {
    ""
  }
  (scheme, authority, base_path + "/sql")
}

///|
fn surrealdb_query(sql : String) -> Result[Json, String] {
  let (scheme, authority, path) = surreal_url_parts()
  let _token = get_env("SURREALDB_TOKEN")
  let ns = get_env("SURREALDB_NS")
  let db = get_env("SURREALDB_DB")

  let headers = @httpTypes.Fields::fields()
  let db_user = get_env("SURREALDB_USER")
  let auth_value = if db_user != "" {
    "Basic " + base64_encode(db_user + ":" + _token)
  } else {
    "Bearer " + _token
  }
  let _ = headers.append("Authorization", str_to_bytes(auth_value))
  let _ = headers.append("surreal-ns", str_to_bytes(ns))
  let _ = headers.append("surreal-db", str_to_bytes(db))
  let _ = headers.append("Content-Type", str_to_bytes("text/plain"))
  let _ = headers.append("Accept", str_to_bytes("application/json"))

  let request = @httpTypes.OutgoingRequest::outgoing_request(headers)
  let _ = request.set_method(@httpTypes.Method::Post)
  let _ = request.set_scheme(Some(scheme))
  let _ = request.set_authority(Some(authority))
  let _ = request.set_path_with_query(Some(path))

  let body = request.body().unwrap()
  let output_stream = body.write().unwrap()
  let body_bytes = str_to_bytes(sql)
  output_stream.blocking_write_and_flush(body_bytes).unwrap()
  output_stream.drop()
  let _ = @httpTypes.OutgoingBody::finish(body, None)

  match @http.handle(request, None) {
    Err(e) => Err("HTTP request failed: " + e.to_string())
    Ok(future) => {
      let pollable = future.subscribe()
      pollable.block()
      match future.get() {
        Some(Ok(Ok(response))) => {
          let status = response.status()
          let incoming_body = response.consume().unwrap()
          let stream = incoming_body.stream().unwrap()
          let bytes = stream.blocking_read(1048576UL).unwrap()
          stream.drop()
          let _ = @httpTypes.IncomingBody::finish(incoming_body)
          let body_str = bytes_to_str(bytes)
          if status >= 200 && status < 300 {
            let json = @json.parse(body_str) catch {
              _ => return Err("Failed to parse JSON response")
            }
            Ok(json)
          } else {
            Err("HTTP " + status.to_string() + ": " + body_str)
          }
        }
        Some(Ok(Err(e))) => Err("HTTP error: " + e.to_string())
        Some(Err(_)) => Err("Response already consumed")
        None => Err("Response not ready")
      }
    }
  }
}

///|
fn filter_lesson_steps(steps : Json) -> Json {
  match steps {
    Json::Array(arr) => {
      let filtered : Array[Json] = []
      for step in arr {
        match step {
          Json::Object(obj) => {
            let new_obj : Map[String, Json] = {}
            for pair in obj {
              if pair.0 != "teacher_actions" && pair.0 != "assessment" {
                new_obj[pair.0] = pair.1
              }
            }
            filtered.push(Json::object(new_obj))
          }
          _ => filtered.push(step)
        }
      }
      Json::array(filtered)
    }
    _ => steps
  }
}

///|
fn filter_lesson_fields(lesson : Json) -> Json {
  match lesson {
    Json::Object(obj) => {
      let new_obj : Map[String, Json] = {}
      for pair in obj {
        let key = pair.0
        let value = pair.1
        if key == "teacher_tips" || key == "formative_assessment" || key == "summative_assessment" || key == "remediation" {
          continue
        }
        if key == "lesson_steps" {
          new_obj[key] = filter_lesson_steps(value)
        } else {
          new_obj[key] = value
        }
      }
      Json::object(new_obj)
    }
    _ => lesson
  }
}

///|
/// Spawn a QueryFork to execute SQL and return the raw JSON string.
fn fork_query(sql : String) -> String raise @common.AgentError {
  let ctor_data = @rpcTypes.DataValue::Tuple([@schema.to_element_value_as(sql)])
  let client = @rpc.AgentClient::get("QueryFork", ctor_data)
  defer client.drop()
  let result = client.invoke_and_await(
    "execute",
    @rpcTypes.DataValue::Tuple([]),
  )
  let elements = @extractor.extract_tuple(result)
  @schema.from_element_value_as(elements[0])
}

///|
/// Execute SQL via QueryFork and extract the "result" field.
fn query_result(sql : String) -> Result[Json, String] {
  let json_str = fork_query(sql) catch {
    e => return Err(e.to_string())
  }
  let response = @json.parse(json_str) catch {
    _ => return Err("Failed to parse query response")
  }
  match response {
    Json::Array(arr) => {
      if arr.length() == 0 {
        return Err("Empty query response")
      }
      match arr[0] {
        Json::Object(obj) => {
          match obj.get("result") {
            Some(result) => Ok(result)
            None => Err("Missing result field")
          }
        }
        _ => Err("Unexpected response format")
      }
    }
    _ => Err("Expected array response")
  }
}

///|
/// Validate that a lesson ID matches the expected format (lesson_content:N)
fn validate_lesson_id(id : String) -> Bool {
  let prefix = "lesson_content:"
  if id.length() <= prefix.length() { return false }
  if id[:prefix.length()] != prefix { return false }
  let suffix = id[prefix.length():]
  let chars = suffix.to_array()
  if chars.length() == 0 { return false }
  for c in chars {
    if c < '0' || c > '9' { return false }
  }
  true
}

///|
fn is_safe_subject_char(c : Char) -> Bool {
  (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || (c >= '0' && c <= '9') || c == ' ' || c == '-'
}

///|
fn validate_subject_name(name : String) -> Bool {
  let chars = name.to_array()
  if chars.length() == 0 { return false }
  for c in chars {
    if !is_safe_subject_char(c) { return false }
  }
  true
}

///|
pub fn UserAgent::get_subjects(self : Self) -> String {
  let cache_key = "subjects"
  match self.cache_get(cache_key) {
    Some(cached) => return cached
    None => ()
  }
  let sql = "SELECT subject FROM lesson_content GROUP BY subject;"
  match query_result(sql) {
    Ok(result) => {
      let json_str = result.stringify()
      self.cache_set(cache_key, json_str, 600)
      json_str
    }
    Err(e) => "{\"error\":\"" + e + "\"}"
  }
}

///|
pub fn UserAgent::get_lessons(self : Self, subject : String) -> String {
  if !validate_subject_name(subject) { return "{\"error\":\"Invalid subject name\"}" }
  let cache_key = "list:" + subject
  match self.cache_get(cache_key) {
    Some(cached) => return cached
    None => ()
  }
  let sql = "SELECT id, topic_title, week, term, subject, active FROM lesson_content WHERE subject = '" + subject + "' ORDER BY week;"
  match query_result(sql) {
    Ok(result) => {
      let json_str = if self.role == "student" {
        match result {
          Json::Array(arr) => {
            let filtered = arr.filter(fn(item) {
              match item {
                Json::Object(obj) => {
                  match obj.get("active") {
                    Some(Json::False) => false
                    _ => true
                  }
                }
                _ => true
              }
            })
            Json::array(filtered).stringify()
          }
          _ => result.stringify()
        }
      } else {
        result.stringify()
      }
      self.cache_set(cache_key, json_str, 600)
      json_str
    }
    Err(e) => "{\"error\":\"" + e + "\"}"
  }
}

///|
pub fn UserAgent::get_lesson(self : Self, lesson_id : String) -> String {
  if !validate_lesson_id(lesson_id) { return "{\"error\":\"Invalid lesson ID\"}" }
  let cache_key = "content:" + lesson_id
  match self.cache_get(cache_key) {
    Some(cached) => return cached
    None => ()
  }
  let sql = "SELECT * FROM " + lesson_id + ";"
  match query_result(sql) {
    Ok(result) => {
      let json_str = match result {
        Json::Array(arr) => {
          if arr.length() > 0 {
            if self.role == "student" {
              let filtered = filter_lesson_fields(arr[0])
              Json::array([filtered]).stringify()
            } else {
              Json::array([arr[0]]).stringify()
            }
          } else {
            "[]"
          }
        }
        _ => result.stringify()
      }
      self.cache_set(cache_key, json_str, 300)
      json_str
    }
    Err(e) => "{\"error\":\"" + e + "\"}"
  }
}

///|
/// Toggle lesson active state (teacher or admin only).
/// Updates SurrealDB directly. Returns new active value.
pub fn UserAgent::toggle_lesson(self : Self, lesson_id : String) -> Bool {
  if !validate_lesson_id(lesson_id) { return false }
  if self.role != "teacher" && self.role != "admin" { return false }
  // Read current state and subject
  let select_sql = "SELECT active, subject FROM " + lesson_id + ";"
  let (current, subject) = match query_result(select_sql) {
    Ok(result) => {
      match result {
        Json::Array(arr) => {
          if arr.length() > 0 {
            match arr[0] {
              Json::Object(obj) => {
                let active = match obj.get("active") {
                  Some(Json::True) => true
                  Some(Json::False) => false
                  _ => true
                }
                let subject = match obj.get("subject") {
                  Some(Json::String(s)) => s
                  _ => ""
                }
                (active, subject)
              }
              _ => return false
            }
          } else {
            return false
          }
        }
        _ => return false
      }
    }
    Err(_) => return false
  }
  // Update to opposite
  let next = !current
  let update_sql = "UPDATE " + lesson_id + " SET active = " + next.to_string() + ";"
  let _ = fork_query(update_sql) catch {
    _ => return false
  }
  // Invalidate caches
  self.cache_invalidate("content:" + lesson_id)
  if subject != "" {
    self.cache_invalidate("list:" + subject)
  }
  next
}

///|
fn main {

}
