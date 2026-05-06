///| jwt.mbt — auth parser supporting JWT and simple user|role tokens

/// Parse auth token and extract (user_id, role).
/// Supports three formats:
///   1. Empty / missing → ("guest", "student")
///   2. JWT (contains '.') → parse claims
///   3. Simple "user|role" → split on '|' (e.g. "teacher1|teacher")
/// NOTE: JWT signature is NOT verified — add JWKS validation for production.
/// Parse auth token and extract (user_id, role).
fn parse_auth(token : String) -> (String, String) {
  if token == "" {
    return ("guest", "student")
  }
  // Simple user|role format
  let parts = token.split("|").to_array()
  if parts.length() == 2 {
    let user_id = parts[0].to_owned()
    let role = parts[1].to_owned()
    return (user_id, role)
  }
  // JWT format
  let jwt_parts = token.split(".").to_array()
  if jwt_parts.length() == 3 {
    match parse_jwt(token) {
      Ok(pair) => return pair
      Err(_) => ()
    }
  }
  // Fallback: treat entire token as user_id, default role student
  (token, "student")
}

/// Parse JWT payload and extract (sub, role) claims.
fn parse_jwt(token : String) -> Result[(String, String), String] {
  let parts = token.split(".").to_array()
  if parts.length() != 3 {
    return Err("Invalid JWT format")
  }
  let payload_b64url = parts[1].to_owned()
  let payload_b64 = base64url_to_std(payload_b64url)
  let bytes = @base64.decode(payload_b64) catch {
    _ => return Err("Invalid Base64 payload")
  }
  let payload_str = bytes_to_str(bytes)
  let json = @json.parse(payload_str) catch {
    _ => return Err("Invalid JSON payload")
  }
  match json {
    Json::Object(obj) => {
      let user_id = match obj.get("sub") {
        Some(Json::String(s)) => s
        _ => return Err("Missing sub claim")
      }
      let role = match obj.get("groups") {
        Some(Json::Array(groups)) => {
          let mut role = "student"
          for g in groups {
            match g {
              Json::String("teachers") => { role = "teacher"; break }
              Json::String("admin") => { role = "admin"; break }
              _ => ()
            }
          }
          role
        }
        _ => "student"
      }
      Ok((user_id, role))
    }
    _ => Err("Invalid JWT payload structure")
  }
}

/// Convert Base64Url to standard Base64
fn base64url_to_std(s : String) -> String {
  let chars = s.to_array()
  let mut result = ""
  for c in chars {
    let ch = match c {
      '-' => "+"
      '_' => "/"
      _ => c.to_string()
    }
    result = result + ch
  }
  let pad = (4 - result.length() % 4) % 4
  for i = 0; i < pad; i = i + 1 {
    result = result + "="
  }
  result
}

/// Convert bytes to string (ASCII only)
fn bytes_to_str(bytes : Bytes) -> String {
  let mut s = ""
  for i = 0; i < bytes.length(); i = i + 1 {
    s = s + bytes[i].to_int().unsafe_to_char().to_string()
  }
  s
}
