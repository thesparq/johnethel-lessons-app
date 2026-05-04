///|
/// API entry point agent — ephemeral, one per request
#derive.agent("ephemeral")
#derive.mount("/")
struct ApiAgent {}

///|
fn ApiAgent::new() -> ApiAgent {
  ApiAgent::{}
}

///|
/// Extract Bearer token from Authorization header
fn extract_bearer(auth_header : String) -> String {
  let prefix = "Bearer "
  if auth_header.has_prefix(prefix) {
    auth_header[prefix.length():].to_owned()
  } else {
    ""
  }
}

///|
/// Parse JWT and return (user_id, role)
fn auth_user(auth_header : String) -> Result[(String, String), String] {
  let token = extract_bearer(auth_header)
  if token == "" {
    return Err("Missing or invalid Authorization header")
  }
  parse_jwt(token)
}

///|
/// List all subjects
#derive.endpoint(get="/subjects")
#derive.endpoint_header("Authorization", "auth_header")
pub fn ApiAgent::get_subjects(self : Self, auth_header : String) -> String raise @common.AgentError {
  let _ = self
  let (user_id, role) = match auth_user(auth_header) {
    Ok(pair) => pair
    Err(e) => raise @common.AgentError::InvalidInput(e)
  }
  user_get_subjects(user_id, role)
}

///|
/// List lessons for a subject
#derive.endpoint(get="/subjects/{subject_id}/lessons")
#derive.endpoint_header("Authorization", "auth_header")
pub fn ApiAgent::get_lessons(
  self : Self,
  subject_id : String,
  auth_header : String
) -> String raise @common.AgentError {
  let _ = self
  let (user_id, role) = match auth_user(auth_header) {
    Ok(pair) => pair
    Err(e) => raise @common.AgentError::InvalidInput(e)
  }
  user_get_lessons(user_id, role, subject_id)
}

///|
/// Get lesson content
#derive.endpoint(get="/lessons/{lesson_id}")
#derive.endpoint_header("Authorization", "auth_header")
pub fn ApiAgent::get_lesson(
  self : Self,
  lesson_id : String,
  auth_header : String
) -> String raise @common.AgentError {
  let _ = self
  let (user_id, role) = match auth_user(auth_header) {
    Ok(pair) => pair
    Err(e) => raise @common.AgentError::InvalidInput(e)
  }
  user_get_lesson(user_id, role, lesson_id)
}

///|
/// Toggle lesson active state (teacher only)
#derive.endpoint(post="/lessons/{lesson_id}/toggle")
#derive.endpoint_header("Authorization", "auth_header")
pub fn ApiAgent::toggle_lesson(
  self : Self,
  lesson_id : String,
  auth_header : String
) -> String raise @common.AgentError {
  let _ = self
  let (user_id, role) = match auth_user(auth_header) {
    Ok(pair) => pair
    Err(e) => raise @common.AgentError::InvalidInput(e)
  }
  if role != "teacher" && role != "admin" {
    raise @common.AgentError::InvalidInput("Forbidden: teachers only")
  }
  let toggled = user_toggle_lesson(user_id, role, lesson_id)
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
  let (_user_id, role) = match auth_user(auth_header) {
    Ok(pair) => pair
    Err(e) => raise @common.AgentError::InvalidInput(e)
  }
  if role != "admin" {
    raise @common.AgentError::InvalidInput("Forbidden: admin only")
  }
  let assigned = admin_assign_teacher(teacher_id, subject)
  "{\"assigned\":" + assigned.to_string() + "}"
}

///|
fn main {

}
