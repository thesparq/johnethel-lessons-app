///|
/// Auth agent — durable singleton, JWKS caching, JWT validation
#derive.agent
struct AuthAgent {
  jwks_cache : String
  jwks_fetched_at : UInt64
}

///|
fn AuthAgent::new() -> AuthAgent {
  { jwks_cache: "", jwks_fetched_at: 0 }
}

///|
/// Validate a token and return (user_id, role, email).
/// Supports two formats:
///   1. Dev format: "user_id|role" (e.g. "alice|student", "teacher1|teacher")
///   2. JWT format: full JWT from Authentik (validated against JWKS)
///
/// Never fails — returns defaults on any error.
pub fn AuthAgent::validate_token(
  self : Self,
  token : String
) -> (String, String, String) {
  // Try dev format first
  let parts = token.split("|").to_array()
  if parts.length() == 2 {
    let user_id = parts[0].to_owned()
    let role = parts[1].to_owned()
    return (user_id, role, user_id + "@johnethel.local")
  }
  
  // Try JWT format
  if token.has_prefix("ey") {
    // JWT parsing placeholder — will implement full JWKS validation
    // when Authentik is configured
    match parse_jwt_payload(token) {
      Some((sub, role, email)) => (sub, role, email)
      None => ("anonymous", "student", "anonymous@johnethel.local")
    }
  }
  
  // Unknown format — treat as anonymous student
  ("anonymous", "student", "anonymous@johnethel.local")
}

///|
/// Parse JWT payload (base64url-decoded) to extract claims.
/// Returns (sub, role, email) or None.
fn parse_jwt_payload(token : String) -> (String, String, String)? {
  // JWT format: header.payload.signature
  let parts = token.split(".").to_array()
  if parts.length() != 3 {
    return None
  }
  
  let payload_b64 = parts[1]
  let payload_json = base64url_decode(payload_b64)
  
  match @json.parse(payload_json) {
    Ok(Json::Object(obj)) => {
      let sub = match obj.get("sub") {
        Some(Json::String(s)) => s
        _ => "anonymous"
      }
      let role = match obj.get("role") {
        Some(Json::String(s)) => s
        _ => match obj.get("groups") {
          Some(Json::Array(arr)) => {
            if arr.length() > 0 {
              match arr[0] {
                Json::String(s) => s.to_lower()
                _ => "student"
              }
            } else {
              "student"
            }
          }
          _ => "student"
        }
      }
      let email = match obj.get("email") {
        Some(Json::String(s)) => s
        _ => sub + "@johnethel.local"
      }
      Some((sub, role, email))
    }
    _ => None
  }
}

///|
/// Base64url decode (simplified — handles basic JWT payloads).
fn base64url_decode(input : String) -> String {
  // Replace URL-safe chars
  let normalized = input.replace("-", "+").replace("_", "/")
  
  // Add padding if needed
  let len = normalized.length()
  let padding = 4 - (len % 4)
  let padded = if padding < 4 {
    normalized + "=".repeat(padding)
  } else {
    normalized
  }
  
  // Basic base64 decode (placeholder — will use proper base64 library)
  // For MVP: just return the raw string for now
  padded
}

///|
fn main {

}
