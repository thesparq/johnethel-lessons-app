///|
/// User agent — durable per-user instance
#derive.agent
struct UserAgent {
  user_id : String
  role : String
}

///|
fn UserAgent::new(user_id : String, role : String) -> UserAgent {
  { user_id, role }
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
  let token = get_env("SURREALDB_TOKEN")
  let ns = get_env("SURREALDB_NS")
  let db = get_env("SURREALDB_DB")

  let headers = @httpTypes.Fields::fields()
  let _ = headers.append("Authorization", str_to_bytes("Basic cm9vdDpyb290"))
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
fn extract_result(response : Json) -> Result[Json, String] {
  match response {
    Json::Array(arr) => {
      if arr.length() == 0 {
        return Err("Empty response array")
      }
      match arr[0] {
        Json::Object(obj) => {
          match obj.get("result") {
            Some(result) => Ok(result)
            None => Err("Missing 'result' field")
          }
        }
        _ => Err("Expected object in response array")
      }
    }
    _ => Err("Expected array response")
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
pub fn UserAgent::get_subjects(self : Self) -> String {
  let _ = self
  let sql = "SELECT subject FROM lesson_content GROUP BY subject;"
  match surrealdb_query(sql) {
    Ok(json) => {
      match extract_result(json) {
        Ok(result) => result.stringify()
        Err(e) => "{\"error\":\"" + e + "\"}"
      }
    }
    Err(e) => "{\"error\":\"" + e + "\"}"
  }
}

///|
pub fn UserAgent::get_lessons(self : Self, subject : String) -> String {
  let _ = self
  let sql = "SELECT id, topic_title, week, term, subject FROM lesson_content WHERE subject = '" + subject + "' ORDER BY week;"
  match surrealdb_query(sql) {
    Ok(json) => {
      match extract_result(json) {
        Ok(result) => result.stringify()
        Err(e) => "{\"error\":\"" + e + "\"}"
      }
    }
    Err(e) => "{\"error\":\"" + e + "\"}"
  }
}

///|
pub fn UserAgent::get_lesson(self : Self, lesson_id : String) -> String raise @common.AgentError {
  let sql = "SELECT * FROM " + lesson_id + ";"
  match surrealdb_query(sql) {
    Ok(json) => {
      match extract_result(json) {
        Ok(result) => {
          match result {
            Json::Array(arr) => {
              if arr.length() > 0 {
                let filtered = filter_lesson_fields(arr[0])
                let active = admin_is_lesson_active(lesson_id)
                let final_json = match filtered {
                  Json::Object(obj) => {
                    obj["active"] = Json::boolean(active)
                    Json::object(obj)
                  }
                  _ => filtered
                }
                Json::array([final_json]).stringify()
              } else {
                "[]"
              }
            }
            _ => result.stringify()
          }
        }
        Err(e) => "{\"error\":\"" + e + "\"}"
      }
    }
    Err(e) => "{\"error\":\"" + e + "\"}"
  }
}

///|
/// Query global toggle state from AdminAgent singleton.
fn admin_is_lesson_active(lesson_id : String) -> Bool raise @common.AgentError {
  let ctor_data = @rpcTypes.DataValue::Tuple([])
  let client = @rpc.AgentClient::get("AdminAgent", ctor_data)
  defer client.drop()
  let result = client.invoke_and_await(
    "is_lesson_active",
    @rpcTypes.DataValue::Tuple([@schema.to_element_value_as(lesson_id)]),
  )
  let elements = @extractor.extract_tuple(result)
  @schema.from_element_value_as(elements[0])
}

///|
fn main {

}
