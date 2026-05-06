///|
/// UserAgent — durable per-user agent with caching.
/// Handles HTTP requests directly via mount path /users/{user_id}.
/// Forks QueryFork for all blocking SurrealDB I/O.
#derive.agent
#derive.mount("/users/{user_id}")
#derive.mount_cors("*")
struct UserAgent {
  user_id : String
  // Cache: key → (json_data, timestamp_ms, ttl_ms)
  cache : Map[String, (String, UInt64, UInt64)]
  // Token cache: token_prefix → (user_id, role, validated_at, ttl_ms)
  token_cache : Map[String, (String, String, UInt64, UInt64)]
}

///|
fn UserAgent::new(user_id : String) -> UserAgent {
  { user_id, cache: {}, token_cache: {} }
}

// --- Auth ---

///|
/// Validate token via AuthAgent RPC. Returns (user_id, role).
/// Uses local token_cache to avoid repeated AuthAgent calls.
fn validate_token_cached(self : Self, token : String) -> (String, String) raise @common.AgentError {
  // Check local token cache
  let prefix = if token.length() > 20 {
    token[0:20]
  } else {
    token
  }
  match self.token_cache.get(prefix) {
    Some((cached_user, cached_role, validated_at, ttl_ms)) => {
      let now = @wallClock.now()
      if now - validated_at < ttl_ms {
        return (cached_user, cached_role)
      }
    }
    None => ()
  }

  // Cache miss or stale — validate via AuthAgent
  let ctor_data = @rpcTypes.DataValue::Tuple([])
  let client = @rpc.AgentClient::get("AuthAgent", ctor_data)
  defer client.drop()
  let result = client.invoke_and_await(
    "validate_token",
    @rpcTypes.DataValue::Tuple([@schema.to_element_value_as(token)]),
  )
  let elements = @extractor.extract_tuple(result)
  let user_id = @schema.from_element_value_as(elements[0])
  let role = @schema.from_element_value_as(elements[1])
  
  // Cache result for 60 seconds
  let now = @wallClock.now()
  self.token_cache[prefix] = (user_id, role, now, 60_000)
  (user_id, role)
}

///|
/// Verify that the authenticated user matches this agent's identity.
fn require_self(self : Self, token : String) -> String raise @common.AgentError {
  let (user_id, _role) = self.validate_token_cached(token)
  if user_id != self.user_id {
    raise @common.AgentError::InvalidInput("Unauthorized: token does not match user")
  }
  user_id
}

///|
/// Verify that the user has the required role.
fn require_role(self : Self, token : String, allowed : Array[String]) -> String raise @common.AgentError {
  let (user_id, role) = self.validate_token_cached(token)
  if user_id != self.user_id {
    raise @common.AgentError::InvalidInput("Unauthorized: token does not match user")
  }
  let mut found = false
  for r in allowed {
    if r == role {
      found = true
      break
    }
  }
  if not found {
    raise @common.AgentError::InvalidInput("Forbidden: insufficient permissions")
  }
  user_id
}

// --- Cache ---

///|
fn cache_get(self : Self, key : String) -> String? {
  match self.cache.get(key) {
    Some((data, fetched_at, ttl_ms)) => {
      let now = @wallClock.now()
      if now - fetched_at < ttl_ms {
        Some(data)
      } else {
        None
      }
    }
    None => None
  }
}

///|
fn cache_set(self : Self, key : String, data : String, ttl_ms : UInt64) -> Unit {
  let now = @wallClock.now()
  self.cache[key] = (data, now, ttl_ms)
}

///|
fn cache_invalidate(self : Self, key : String) -> Unit {
  self.cache.remove(key)
}

// --- Query forking ---

///|
/// Fork a QueryFork to execute SQL and return the JSON result string.
fn fork_query(self : Self, sql : String) -> String raise @common.AgentError {
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
/// Execute SQL and extract the "result" field from SurrealDB response.
fn query_result(self : Self, sql : String) -> Json raise @common.AgentError {
  let response_str = self.fork_query(sql)
  let response_json = @json.parse(response_str) catch {
    _ => raise @common.AgentError::InvalidInput("Failed to parse query response")
  }
  match response_json {
    Json::Array(arr) => {
      if arr.length() == 0 {
        raise @common.AgentError::InvalidInput("Empty query response")
      }
      match arr[0] {
        Json::Object(obj) => {
          match obj.get("result") {
            Some(result) => result
            None => raise @common.AgentError::InvalidInput("Missing result field")
          }
        }
        _ => raise @common.AgentError::InvalidInput("Unexpected response format")
      }
    }
    _ => raise @common.AgentError::InvalidInput("Expected array response")
  }
}

// --- Field filtering ---

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

// --- Validation ---

///|
fn validate_lesson_id(id : String) -> Bool {
  let parts = id.split(":").to_array()
  parts.length() == 2 && parts[0] == "lesson_content"
}

// --- HTTP Endpoints ---

///|
/// List all subjects — open to everyone.
#derive.endpoint(get="/subjects")
#derive.endpoint_header("Authorization", "auth_header")
pub fn UserAgent::get_subjects(self : Self, auth_header : String) -> String raise @common.AgentError {
  let _ = self.require_self(auth_header)
  
  // Check cache
  match self.cache_get("subjects") {
    Some(cached) => return cached
    None => ()
  }
  
  // Cache miss — fork QueryFork
  let sql = "SELECT subject FROM lesson_content GROUP BY subject;"
  let result = self.query_result(sql)
  let json_str = result.stringify()
  self.cache_set("subjects", json_str, 600_000)  // 10 min TTL
  json_str
}

///|
/// List lessons for a subject — open to everyone.
#derive.endpoint(get="/subjects/{subject}/lessons")
#derive.endpoint_header("Authorization", "auth_header")
pub fn UserAgent::get_lessons(self : Self, subject : String, auth_header : String) -> String raise @common.AgentError {
  let _ = self.require_self(auth_header)
  let cache_key = "list:" + subject
  
  match self.cache_get(cache_key) {
    Some(cached) => return cached
    None => ()
  }
  
  let sql = "SELECT id, topic_title, week, term, subject FROM lesson_content WHERE subject = '" + subject + "' ORDER BY week;"
  let result = self.query_result(sql)
  let json_str = result.stringify()
  self.cache_set(cache_key, json_str, 600_000)  // 10 min TTL
  json_str
}

///|
/// Get full lesson content — open to everyone.
#derive.endpoint(get="/lessons/{lesson_id}")
#derive.endpoint_header("Authorization", "auth_header")
pub fn UserAgent::get_lesson(self : Self, lesson_id : String, auth_header : String) -> String raise @common.AgentError {
  let _ = self.require_self(auth_header)
  
  if not validate_lesson_id(lesson_id) {
    raise @common.AgentError::InvalidInput("Invalid lesson ID format")
  }
  
  let cache_key = "content:" + lesson_id
  match self.cache_get(cache_key) {
    Some(cached) => return cached
    None => ()
  }
  
  let sql = "SELECT * FROM " + lesson_id + ";"
  let result = self.query_result(sql)
  let json_str = match result {
    Json::Array(arr) => {
      if arr.length() > 0 {
        let filtered = filter_lesson_fields(arr[0])
        Json::array([filtered]).stringify()
      } else {
        "[]"
      }
    }
    _ => result.stringify()
  }
  self.cache_set(cache_key, json_str, 300_000)  // 5 min TTL
  json_str
}

///|
/// Toggle lesson active state (teacher only).
#derive.endpoint(post="/lessons/{lesson_id}/toggle")
#derive.endpoint_header("Authorization", "auth_header")
pub fn UserAgent::toggle_lesson(self : Self, lesson_id : String, auth_header : String) -> String raise @common.AgentError {
  let _ = self.require_role(auth_header, ["teacher", "admin"])
  
  if not validate_lesson_id(lesson_id) {
    raise @common.AgentError::InvalidInput("Invalid lesson ID format")
  }
  
  // Read current state
  let select_sql = "SELECT active FROM " + lesson_id + ";"
  let result = self.query_result(select_sql)
  let current = match result {
    Json::Array(arr) => {
      if arr.length() > 0 {
        match arr[0] {
          Json::Object(obj) => {
            match obj.get("active") {
              Some(Json::True) => true
              Some(Json::False) => false
              _ => true
            }
          }
          _ => true
        }
      } else {
        true
      }
    }
    _ => true
  }
  
  // Update to opposite
  let next = not(current)
  let update_sql = "UPDATE " + lesson_id + " SET active = " + next.to_string() + ";"
  let _ = self.fork_query(update_sql)
  
  // Invalidate cache
  self.cache_invalidate("content:" + lesson_id)
  
  "{\"toggled\":" + next.to_string() + ",\"active\":" + next.to_string() + "}"
}

///|
fn main {

}
