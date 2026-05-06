///|
/// Toggle fork — ephemeral worker spawned per toggle request.
/// Dies after handling the request. Offloads work from AdminAgent.
#derive.agent("ephemeral")
struct ToggleFork {
  lesson_id : String
}

///|
fn ToggleFork::new(lesson_id : String) -> ToggleFork {
  { lesson_id }
}

///|
pub fn ToggleFork::execute(self : Self) -> Bool raise @common.AgentError {
  admin_toggle_lesson(self.lesson_id)
}

///|
/// API entry point agent — ephemeral, one per request
#derive.agent("ephemeral")
#derive.mount("/")
#derive.mount_cors("*")
struct ApiAgent {}

///|
fn ApiAgent::new() -> ApiAgent {
  ApiAgent::{}
}

///|
/// Extract Bearer token from Authorization header (or use raw value)
fn extract_token(auth_header : String) -> String {
  let prefix = "Bearer "
  if auth_header.has_prefix(prefix) {
    auth_header[prefix.length():].to_owned()
  } else {
    auth_header
  }
}

///|
/// Parse auth header and return (user_id, role). Never fails.
fn auth_user(auth_header : String) -> (String, String) {
  let token = extract_token(auth_header)
  parse_auth(token)
}

///|
/// List all subjects — open to everyone
#derive.endpoint(get="/subjects")
#derive.endpoint_header("Authorization", "auth_header")
pub fn ApiAgent::get_subjects(self : Self, auth_header : String) -> String raise @common.AgentError {
  let _ = self
  let (user_id, role) = auth_user(auth_header)
  user_get_subjects(user_id, role)
}

///|
/// List lessons for a subject — open to everyone
#derive.endpoint(get="/subjects/{subject_id}/lessons")
#derive.endpoint_header("Authorization", "auth_header")
pub fn ApiAgent::get_lessons(
  self : Self,
  subject_id : String,
  auth_header : String
) -> String raise @common.AgentError {
  let _ = self
  let (user_id, role) = auth_user(auth_header)
  user_get_lessons(user_id, role, subject_id)
}

///|
/// Get lesson content — open to everyone
#derive.endpoint(get="/lessons/{lesson_id}")
#derive.endpoint_header("Authorization", "auth_header")
pub fn ApiAgent::get_lesson(
  self : Self,
  lesson_id : String,
  auth_header : String
) -> String raise @common.AgentError {
  let _ = self
  let (user_id, role) = auth_user(auth_header)
  user_get_lesson(user_id, role, lesson_id)
}

///|
/// Toggle lesson active state (teacher or admin only)
/// Forks an ephemeral ToggleFork agent to handle the request.
#derive.endpoint(post="/lessons/{lesson_id}/toggle")
#derive.endpoint_header("Authorization", "auth_header")
pub fn ApiAgent::toggle_lesson(
  self : Self,
  lesson_id : String,
  auth_header : String
) -> String raise @common.AgentError {
  let _ = self
  let (_user_id, role) = auth_user(auth_header)
  if role != "teacher" && role != "admin" {
    raise @common.AgentError::InvalidInput("Forbidden: teachers only")
  }
  let toggled = fork_toggle(lesson_id)
  "{\"toggled\":" + toggled.to_string() + "}"
}

///|
/// Assign teacher to subject (admin only)
#derive.endpoint(post="/admin/assign?teacher_id={teacher_id}&subject={subject}")
#derive.endpoint_header("Authorization", "auth_header")
pub fn ApiAgent::assign_teacher(
  self : Self,
  teacher_id : String,
  subject : String,
  auth_header : String
) -> String raise @common.AgentError {
  let _ = self
  let (_user_id, role) = auth_user(auth_header)
  if role != "admin" {
    raise @common.AgentError::InvalidInput("Forbidden: admin only")
  }
  let assigned = admin_assign_teacher(teacher_id, subject)
  "{\"assigned\":" + assigned.to_string() + "}"
}

///|
/// Spawn an ephemeral ToggleFork agent to handle a toggle request.
fn fork_toggle(lesson_id : String) -> Bool raise @common.AgentError {
  let ctor_data = @rpcTypes.DataValue::Tuple([@schema.to_element_value_as(lesson_id)])
  let client = @rpc.AgentClient::get("ToggleFork", ctor_data)
  defer client.drop()
  let result = client.invoke_and_await(
    "execute",
    @rpcTypes.DataValue::Tuple([]),
  )
  let elements = @extractor.extract_tuple(result)
  @schema.from_element_value_as(elements[0])
}

///|
fn main {

}
