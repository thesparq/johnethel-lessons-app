///|
/// AuthAgent — durable singleton for token validation.
/// Validates dev tokens (user_id|role) and Authentik JWT via userinfo endpoint.
#derive.agent
struct AuthAgent {}

///|
fn AuthAgent::new() -> AuthAgent {
  AuthAgent::{}
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
/// Call Authentik /userinfo endpoint to validate token.
/// Returns Ok(user_id, role, email) or Err(error_message).
fn authenticate_via_userinfo(token : String) -> Result[(String, String, String), String] {
  let userinfo_url = get_env("AUTHENTIK_USERINFO_URL")
  if userinfo_url == "" {
    return Err("AUTHENTIK_USERINFO_URL not configured")
  }

  let parts = parse_url(userinfo_url)
  let (scheme, authority, path) = match parts {
    Ok(p) => p
    Err(e) => return Err(e)
  }

  let headers = @httpTypes.Fields::fields()
  let _ = headers.append("Authorization", str_to_bytes("Bearer " + token))
  let _ = headers.append("Accept", str_to_bytes("application/json"))

  let request = @httpTypes.OutgoingRequest::outgoing_request(headers)
  let _ = request.set_method(@httpTypes.Method::Get)
  let _ = request.set_scheme(Some(scheme))
  let _ = request.set_authority(Some(authority))
  let _ = request.set_path_with_query(Some(path))

  let body = request.body().unwrap()
  let _ = @httpTypes.OutgoingBody::finish(body, None)

  let response = match @http.handle(request, None) {
    Err(e) => return Err("HTTP request failed: " + e.to_string())
    Ok(future) => {
      let pollable = future.subscribe()
      pollable.block()
      match future.get() {
        Some(Ok(Ok(resp))) => resp
        _ => return Err("HTTP response error")
      }
    }
  }

  let status = response.status()
  let incoming_body = response.consume().unwrap()
  let stream = incoming_body.stream().unwrap()
  let bytes = stream.blocking_read(65536UL).unwrap()
  let _ = @httpTypes.IncomingBody::finish(incoming_body)

  if status < 200 || status >= 300 {
    return Err("Authentik returned HTTP " + status.to_string())
  }

  let body_str = bytes_to_str(bytes)
  let json = @json.parse(body_str) catch {
    _ => return Err("Failed to parse userinfo response")
  }

  match json {
    Json::Object(obj) => {
      let user_id = match obj.get("sub") {
        Some(Json::String(s)) => s
        _ => return Err("Missing sub in userinfo")
      }
      let email = match obj.get("email") {
        Some(Json::String(s)) => s
        _ => user_id + "@johnethel.school"
      }
      let role = match obj.get("groups") {
        Some(Json::Array(groups)) => {
          let mut r = "student"
          for g in groups {
            match g {
              Json::String("teachers") => { r = "teacher"; break }
              Json::String("admin") => { r = "admin"; break }
              Json::String("students") => { r = "student"; break }
              _ => ()
            }
          }
          r
        }
        _ => "student"
      }
      Ok((user_id, role, email))
    }
    _ => Err("Unexpected userinfo response format")
  }
}

///|
/// Parse URL into (scheme, authority, path).
fn parse_url(url : String) -> Result[(@httpTypes.Scheme, String, String), String] {
  let scheme = if url.has_prefix("https://") {
    @httpTypes.Scheme::Https
  } else if url.has_prefix("http://") {
    @httpTypes.Scheme::Http
  } else {
    return Err("Invalid URL scheme")
  }
  let rest = if url.has_prefix("https://") {
    url["https://".length():].to_owned()
  } else {
    url["http://".length():].to_owned()
  }
  let parts = rest.split("/").to_array()
  let authority = parts[0].to_owned()
  let path = if parts.length() > 1 {
    "/" + parts[1:].to_array().join("/")
  } else {
    "/"
  }
  Ok((scheme, authority, path))
}

///|
/// Validate a token and return (user_id, role, email).
/// Tries Authentik userinfo first, falls back to dev tokens.
pub fn AuthAgent::validate_token(self : Self, token : String) -> (String, String, String) {
  let _ = self
  if token == "" {
    return ("anonymous", "student", "anonymous@johnethel.local")
  }

  // Try dev format first (contains | separator, no dots)
  if !token.contains(".") {
    let parts = token.split("|").to_array()
    if parts.length() == 2 {
      let user_id = parts[0].to_owned()
      let role = parts[1].to_owned()
      let valid_user = user_id == "alice" || user_id == "bob" || user_id == "teacher1" || user_id == "admin"
      let valid_role = role == "student" || role == "teacher" || role == "admin"
      if valid_user && valid_role {
        return (user_id, role, user_id + "@johnethel.local")
      }
    }
    ("anonymous", "student", "anonymous@johnethel.local")
  } else {
    // JWT format — validate via Authentik userinfo
    match authenticate_via_userinfo(token) {
      Ok(result) => result
      Err(_) => ("anonymous", "student", "anonymous@johnethel.local")
    }
  }
}

///|
fn main {

}
