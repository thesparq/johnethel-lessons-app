///|
/// AuthAgent — durable singleton for token validation.
/// Validates dev tokens (user_id|role) and eventually JWT from Authentik.
#derive.agent
struct AuthAgent {}

///|
fn AuthAgent::new() -> AuthAgent {
  AuthAgent::{}
}

///|
/// Validate a token and return (user_id, role, email).
/// Supports dev format: user_id|role (e.g. alice|student, teacher1|teacher)
/// Never fails — returns defaults on any error.
pub fn AuthAgent::validate_token(self : Self, token : String) -> (String, String, String) {
  let _ = self
  // Try dev format first
  let parts = token.split("|").to_array()
  if parts.length() == 2 {
    let user_id = parts[0].to_owned()
    let role = parts[1].to_owned()
    return (user_id, role, user_id + "@johnethel.local")
  }
  // Unknown format — treat as anonymous student
  ("anonymous", "student", "anonymous@johnethel.local")
}

///|
fn main {

}
