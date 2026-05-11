///|
/// DEPRECATED: ToggleFork kept for provision config compatibility.
/// Will be removed in next schema evolution.
#derive.agent("ephemeral")
struct ToggleFork {
  lesson_id : String
}

///|
fn ToggleFork::new(lesson_id : String) -> ToggleFork {
  { lesson_id, }
}

///|
pub fn ToggleFork::execute(self : Self) -> Bool {
  false
}

///|
/// API entry point agent — ephemeral, one per request.
/// Auth validated by Golem gateway via security scheme (Authentik).
/// Uses per-endpoint auth to allow CORS preflight through.
#derive.agent("ephemeral")
#derive.mount("/")
#derive.mount_cors("*")
struct ApiAgent {
  principal : @common.Principal
}

///|
fn ApiAgent::new(principal : @common.Principal) -> ApiAgent {
  { principal, }
}

///|
let secondary_classes : Array[String] = ["JSS_1", "JSS_2", "JSS_3", "SS1", "SS2", "SS3"]

///|
fn extract_class(groups : Array[Json]) -> String {
  for g in groups {
    match g {
      Json::String(s) => {
        for c in secondary_classes {
          if s == c { return c }
        }
      }
      _ => ()
    }
  }
  ""
}

///|
fn auth_user(auth_header : String, p : @common.Principal) -> (String, String, String) {
  match p {
    @common.Principal::Oidc(oidc) => validate_principal_claims(oidc, auth_header)
    @common.Principal::Anonymous => auth_manual(auth_header)
    @common.Principal::Agent(_) => auth_manual(auth_header)
    @common.Principal::GolemUser(_) => auth_manual(auth_header)
  }
}

///|
fn validate_principal_claims(oidc : @common.OidcPrincipal, auth_header : String) -> (String, String, String) {
  let json = @json.parse(oidc.claims) catch { _ => return auth_manual(auth_header) }
  match json {
    Json::Object(obj) => match obj.get("groups") {
      Some(Json::Array(groups)) => {
        let mut found = false
        let mut r = "student"
        let class_level = extract_class(groups)
        for g in groups {
          match g {
            Json::String("admin") => { r = "admin"; found = true; break }
            Json::String("teachers") => { r = "teacher"; found = true; break }
            Json::String("students") => { r = "student"; found = true; break }
            _ => ()
          }
        }
        if found { (oidc.sub, r, class_level) } else { auth_manual(auth_header) }
      }
      _ => auth_manual(auth_header)
    }
    _ => auth_manual(auth_header)
  }
}

///|
fn auth_manual(auth_header : String) -> (String, String, String) {
  if auth_header == "" { return ("anonymous", "student", "") }
  let token = auth_header
  let prefix = "Bearer "
  let token = if token.has_prefix(prefix) { token[prefix.length():].to_owned() } else { token }
  if token.contains(".") { return parse_jwt(token) }
  ("anonymous", "student", "")
}

///|
fn fix_base64url(s : String) -> String {
  let chars = s.to_array()
  let mut r = ""
  for i = 0; i < chars.length(); i = i + 1 {
    let ch = chars[i]
    if ch == '-' { r = r + "+" } else if ch == '_' { r = r + "/" } else { r = r + ch.to_string() }
  }
  let pad = (4 - r.length() % 4) % 4
  for _i = 0; _i < pad; _i = _i + 1 { r = r + "=" }
  r
}

///|
fn bytes_to_str_simple(b : Bytes) -> String {
  let mut s = ""
  for i = 0; i < b.length(); i = i + 1 {
    s = s + b[i].to_int().unsafe_to_char().to_string()
  }
  s
}

///|
fn parse_jwt(token : String) -> (String, String, String) {
  let parts = token.split(".").to_array()
  if parts.length() < 2 { return ("anonymous", "student", "") }
  let b64 = fix_base64url(parts[1].to_owned())
  let bytes = @base64.decode(b64) catch { _ => return ("anonymous", "student", "") }
  let decoded = @utf8.decode_lossy(bytes.view())
  let json = @json.parse(decoded) catch { _ => return ("anonymous", "student", "") }
  match json {
    Json::Object(obj) => {
      let user_id = match obj.get("sub") { Some(Json::String(s)) => s; _ => "" }
      let class_level = match obj.get("groups") {
        Some(Json::Array(groups)) => extract_class(groups)
        _ => ""
      }
      let role = match obj.get("groups") {
        Some(Json::Array(groups)) => {
          let mut found = false
          let mut r = "student"
          for g in groups {
            match g {
              Json::String("teachers") => { r = "teacher"; found = true; break }
              Json::String("admin") => { r = "admin"; found = true; break }
              Json::String("students") => { r = "student"; found = true; break }
              _ => ()
            }
          }
          if found { r } else { "anonymous" }
        }
        _ => "student"
      }
      if user_id != "" && role != "anonymous" { (user_id, role, class_level) } else { ("anonymous", "student", "") }
    }
    _ => ("anonymous", "student", "")
  }
}

///|
fn auth_error_json(msg : String) -> String { "{\"error\":\"" + msg + "\"}" }

///|
fn get_env_safe(name : String, default : String) -> String {
  let envs = @environment.get_environment()
  for pair in envs {
    if pair.0 == name { return pair.1 }
  }
  default
}

///|
/// Public: return Authentik config for frontend.
#derive.endpoint(get="/config")
#derive.endpoint_auth(false)
pub fn ApiAgent::get_config(self : Self) -> String {
  let _ = self
  let url = get_env_safe("AUTHENTIK_URL", "")
  let client_id = get_env_safe("AUTHENTIK_CLIENT_ID", "")
  "{\"authentikUrl\":\"" + url + "\",\"clientId\":\"" + client_id + "\"}"
}

///|
/// List all subjects.
#derive.endpoint(get="/subjects")
#derive.endpoint_header("Authorization", "auth_header")
pub fn ApiAgent::get_subjects(self : Self, auth_header : String?) -> String raise @common.AgentError {
  let _ = self
  let (user_id, role, class_level) = auth_user(auth_header.unwrap_or(""), self.principal)
  if user_id == "anonymous" { return auth_error_json("Unauthorized: invalid token") }
  user_get_subjects(user_id, role, class_level)
}

///|
/// List lessons for a subject.
#derive.endpoint(get="/subjects/{subject_id}/lessons")
#derive.endpoint_header("Authorization", "auth_header")
pub fn ApiAgent::get_lessons(self : Self, subject_id : String, auth_header : String?) -> String raise @common.AgentError {
  let _ = self
  if !validate_subject_name(subject_id) { return auth_error_json("Invalid subject name") }
  let (user_id, role, class_level) = auth_user(auth_header.unwrap_or(""), self.principal)
  if user_id == "anonymous" { return auth_error_json("Unauthorized: invalid token") }
  user_get_lessons(user_id, role, subject_id, class_level)
}

///|
/// Get full lesson content.
#derive.endpoint(get="/lessons/{lesson_id}")
#derive.endpoint_header("Authorization", "auth_header")
pub fn ApiAgent::get_lesson(self : Self, lesson_id : String, auth_header : String?) -> String raise @common.AgentError {
  let _ = self
  if !validate_lesson_id(lesson_id) { return auth_error_json("Invalid lesson ID") }
  let (user_id, role, _class_level) = auth_user(auth_header.unwrap_or(""), self.principal)
  if user_id == "anonymous" { return auth_error_json("Unauthorized: invalid token") }
  user_get_lesson(user_id, role, lesson_id)
}

///|
/// Toggle lesson active state (teacher/admin only).
#derive.endpoint(post="/lessons/{lesson_id}/toggle")
#derive.endpoint_header("Authorization", "auth_header")
pub fn ApiAgent::toggle_lesson(self : Self, lesson_id : String, auth_header : String?) -> String raise @common.AgentError {
  let _ = self
  if !validate_lesson_id(lesson_id) { return auth_error_json("Invalid lesson ID") }
  let (user_id, role, _class_level) = auth_user(auth_header.unwrap_or(""), self.principal)
  if user_id == "anonymous" { return auth_error_json("Unauthorized: invalid token") }
  if role != "teacher" && role != "admin" { return auth_error_json("Forbidden: teachers only") }
  let toggled = user_toggle_lesson(user_id, role, lesson_id)
  "{\"toggled\":" + toggled.to_string() + "}"
}

///|
fn user_toggle_lesson(user_id : String, role : String, lesson_id : String) -> Bool raise @common.AgentError {
  let ctor_data = @rpcTypes.DataValue::Tuple([@schema.to_element_value_as(user_id), @schema.to_element_value_as(role)])
  let client = @rpc.AgentClient::get("UserAgent", ctor_data)
  defer client.drop()
  let result = client.invoke_and_await("toggle_lesson", @rpcTypes.DataValue::Tuple([@schema.to_element_value_as(lesson_id)]))
  let elements = @extractor.extract_tuple(result)
  @schema.from_element_value_as(elements[0])
}

///|
/// Assign teacher to subject (admin only).
#derive.endpoint(post="/admin/assign?teacher_id={teacher_id}&subject={subject}")
#derive.endpoint_header("Authorization", "auth_header")
pub fn ApiAgent::assign_teacher(self : Self, teacher_id : String, subject : String, auth_header : String?) -> String raise @common.AgentError {
  let _ = self
  if !validate_subject_name(subject) { return auth_error_json("Invalid subject name") }
  if teacher_id == "" { return auth_error_json("Invalid teacher ID") }
  let (_user_id, role, _class_level) = auth_user(auth_header.unwrap_or(""), self.principal)
  if _user_id == "anonymous" { return auth_error_json("Unauthorized: invalid token") }
  if role != "admin" { return auth_error_json("Forbidden: admin only") }
  let assigned = admin_assign_teacher(teacher_id, subject)
  "{\"assigned\":" + assigned.to_string() + "}"
}

///|
fn main {}
