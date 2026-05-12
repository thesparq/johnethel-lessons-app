///|
let redirect_uri : String = "http://johnethel-lessons-static.localhost:9006/callback"

// Authentik config — populated by config.js before this script runs
#cfg(target="js")
extern "js" fn js_get_config_json() -> String =
  #|() => { try { const c = window.__CONFIG__ || {}; return JSON.stringify({u: c.authentikUrl || "", c: c.clientId || "", a: c.apiUrl || ""}); } catch(e) { return "{}"; } }

#cfg(not(target="js"))
fn js_get_config_json() -> String { "{}" }

///|
fn parse_config() -> (String, String, String) {
  let raw = js_get_config_json()
  let json = @json.parse(raw) catch { _ => return ("", "", "") }
  match json {
    Json::Object(obj) => {
      let url = match obj.get("u") { Some(Json::String(s)) => s; _ => "" }
      let client_id = match obj.get("c") { Some(Json::String(s)) => s; _ => "" }
      let api_base = match obj.get("a") { Some(Json::String(s)) => s; _ => "http://johnethel-lessons-app.localhost:9006" }
      (url, client_id, api_base)
    }
    _ => ("", "", "")
  }
}

///|
fn api_base() -> String {
  let (_, _, base) = parse_config()
  base
}

#cfg(target="js")
extern "js" fn js_session_set(key : String, value : String) -> Unit =
  #|(key, value) => { try { sessionStorage.setItem(key, value); } catch(e) {} }

#cfg(target="js")
extern "js" fn js_session_get(key : String) -> String =
  #|(key) => { try { return sessionStorage.getItem(key) || ""; } catch(e) { return ""; } }

#cfg(not(target="js"))
fn js_session_set(key_ : String, value_ : String) -> Unit { ignore((key_, value_)) }

#cfg(not(target="js"))
fn js_session_get(key_ : String) -> String { ignore(key_); "" }

///|
enum Route {
  Home
  ClassDetail(String)
  SubjectDetail(String, String)
  TermDetail(String, String, String)
  LessonDetail(String)
  Admin
  Login
  Callback(String)
} derive(Eq)

///|
struct SubjectInfo {
  id : String
  name : String
}

///|
struct LessonInfo {
  id : String
  title : String
  week : Double
  term : String
  subject : String
  active : Bool
}

///|
struct LessonContent {
  id : String
  title : String
  subject : String
  week : Double
  term : String
  active : Bool
  content : String
}

///|
enum Msg {
  UrlChanged(@url.Url)
  UrlRequest(@url.UrlRequest)
  ClassesLoaded(String)
  ClassesFailed(String)
  SubjectsLoaded(String)
  SubjectsFailed(String)
  TermsLoaded(String)
  TermsFailed(String)
  LessonsLoaded(String)
  LessonsFailed(String)
  LessonLoaded(String)
  LessonFailed(String)
  ToggleLesson(String)
  ToggleResult(String)
  ToggleFailed(String)
  Logout
  LoginWithAuthentik
  PkceReady(String)
  AuthCallback(String)
  LoginFailed(String)
  AuthExpired
}

///|
struct Model {
  route : Route
  token : String
  role : String
  class_level : String
  subjects : Array[SubjectInfo]
  classes : Array[String]
  terms : Array[String]
  lessons : Array[LessonInfo]
  current_lesson : Option[LessonContent]
  loading : Bool
  error : String
}

///|
fn init_model() -> Model {
  {
    route: Home,
    token: "",
    role: "student",
    class_level: "",
    subjects: [],
    classes: [],
    terms: [],
    lessons: [],
    current_lesson: None,
    loading: false,
    error: "",
  }
}

///|
///|
#cfg(target="js")
extern "js" fn js_jwt_role(token : String) -> String =
  #|(token) => {
  #|  try {
  #|    const parts = token.split(".");
  #|    if (parts.length < 2) return "student";
  #|    const payload = JSON.parse(atob(parts[1].replace(/-/g,"+").replace(/_/g,"/")));
  #|    const groups = payload.groups || [];
  #|    if (groups.includes("teachers") || groups.includes("teacher")) return "teacher";
  #|    if (groups.includes("admin") || groups.includes("admins")) return "admin";
  #|    return "student";
  #|  } catch(e) { return "student"; }
  #| }

#cfg(target="js")
extern "js" fn js_get_user_class(token : String) -> String =
  #|(token) => {
  #|  try {
  #|    const parts = token.split(".");
  #|    if (parts.length < 2) return "";
  #|    const payload = JSON.parse(atob(parts[1].replace(/-/g,"+").replace(/_/g,"/")));
  #|    const groups = payload.groups || [];
  #|    const classes = ["JSS_1","JSS_2","JSS_3","SS1","SS2","SS3"];
  #|    for (const g of groups) { if (classes.includes(g)) return g; }
  #|    return "";
  #|  } catch(e) { return ""; }
  #| }

#cfg(not(target="js"))
fn js_jwt_role(token_ : String) -> String { ignore(token_); "student" }
#cfg(not(target="js"))
fn js_get_user_class(token_ : String) -> String { ignore(token_); "" }

///|
fn role_from_jwt(token : String) -> String {
  if !token.contains(".") { return "student" }
  js_jwt_role(token)
}

///|
fn route_from_path(path : String) -> Route {
  let path = if path.has_prefix("/") { path } else { "/" + path }
  let path = if path.length() > 1 && path.has_suffix("/") {
    path[:path.length() - 1].to_owned()
  } else {
    path
  }
  let segments = path.split("/").to_array()
  match segments {
    ["", ""] => Home
    ["", "class", id] => ClassDetail(id.to_owned())
    ["", "class", cl, sub] => SubjectDetail(cl.to_owned(), sub.to_owned())
    ["", "class", cl, sub, term] => TermDetail(cl.to_owned(), sub.to_owned(), term.to_owned())
    ["", "lessons", id] => LessonDetail(id.to_owned())
    ["", "admin"] => Admin
    ["", "login"] => Login
    ["", "callback"] => Callback("")
    _ => Home
  }
}

// --- JS FFI ---

#cfg(target="js")
extern "js" fn js_auth_fetch(
  url : String,
  http_method : String,
  token : String,
  on_success : (String) -> Unit,
  on_error : (String) -> Unit,
  on_auth_error : (String) -> Unit,
) -> Unit =
  #|(url, httpMethod, token, onSuccess, onError, onAuthError) => {
  #|  const config = { method: httpMethod, headers: { "Authorization": "Bearer " + token } };
  #|  fetch(url, config)
  #|    .then(r => { if (r.status === 401 || r.status === 403) { onAuthError("auth_expired"); return null; } if (!r.ok) throw new Error("HTTP " + r.status); return r.text(); })
  #|    .then(text => { if (text !== null) onSuccess(text); })
  #|    .catch(e => onError(e.toString()));
  #| }

#cfg(target="js")
extern "js" fn js_auth_post(
  url : String,
  token : String,
  on_success : (String) -> Unit,
  on_error : (String) -> Unit,
  on_auth_error : (String) -> Unit,
) -> Unit =
  #|(url, token, onSuccess, onError, onAuthError) => {
  #|  const config = { method: "POST", headers: { "Authorization": "Bearer " + token } };
  #|  fetch(url, config)
  #|    .then(r => { if (r.status === 401 || r.status === 403) { onAuthError("auth_expired"); return null; } if (!r.ok) throw new Error("HTTP " + r.status); return r.text(); })
  #|    .then(text => { if (text !== null) onSuccess(text); })
  #|    .catch(e => onError(e.toString()));
  #| }

#cfg(target="js")
extern "js" fn js_local_storage_get(key : String) -> String =
  #|(key) => { try { return localStorage.getItem(key) || ""; } catch(e) { return ""; } }

#cfg(target="js")
extern "js" fn js_local_storage_set(key : String, value : String) -> Unit =
  #|(key, value) => { try { localStorage.setItem(key, value); } catch(e) {} }

#cfg(target="js")
extern "js" fn js_local_storage_remove(key : String) -> Unit =
  #|(key) => { try { localStorage.removeItem(key); } catch(e) {} }

#cfg(target="js")
extern "js" fn js_current_url() -> String =
  #|() => { try { return window.location.pathname; } catch(e) { return "/"; } }

#cfg(target="js")
extern "js" fn js_get_query_param(name : String) -> String =
  #|(name) => { try { const p = new URLSearchParams(window.location.search); return p.get(name) || ""; } catch(e) { return ""; } }

#cfg(target="js")
extern "js" fn js_url_encode(s : String) -> String =
  #|(s) => { try { return encodeURIComponent(s); } catch(e) { return s; } }

#cfg(target="js")
extern "js" fn js_url_decode(s : String) -> String =
  #|(s) => { try { return decodeURIComponent(s); } catch(e) { return s; } }

#cfg(not(target="js"))
fn js_url_encode(s : String) -> String { s }
#cfg(not(target="js"))
fn js_url_decode(s : String) -> String { s }

#cfg(target="js")
extern "js" fn js_redirect(url : String) -> Unit =
  #|(url) => { window.location.href = url; }

#cfg(target="js")
extern "js" fn js_pkce_generate(
  on_success : (String) -> Unit,
  on_error : (String) -> Unit,
) -> Unit =
  #|(onSuccess, onError) => {
  #|  try {
  #|    const chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~";
  #|    const arr = new Uint8Array(43);
  #|    crypto.getRandomValues(arr);
  #|    let verifier = "";
  #|    for (let i = 0; i < 43; i++) verifier += chars[arr[i] % chars.length];
  #|    const encoder = new TextEncoder();
  #|    crypto.subtle.digest("SHA-256", encoder.encode(verifier))
  #|      .then(hash => {
  #|        const challenge = btoa(String.fromCharCode(...new Uint8Array(hash)))
  #|          .replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
  #|        onSuccess(JSON.stringify({ v: verifier, c: challenge }));
  #|      })
  #|      .catch(e => onError(e.toString()));
  #|  } catch(e) { onError(e.toString()); }
  #| }

#cfg(not(target="js"))
fn js_redirect(url_ : String) -> Unit { ignore(url_) }

#cfg(not(target="js"))
fn js_pkce_generate(on_success_ : (String) -> Unit, on_error_ : (String) -> Unit) -> Unit { on_error_("stub") }

#cfg(target="js")
extern "js" fn js_form_post(
  url : String,
  body : String,
  on_success : (String) -> Unit,
  on_error : (String) -> Unit,
) -> Unit =
  #|(url, body, onSuccess, onError) => {
  #|  fetch(url, {
  #|    method: "POST",
  #|    headers: { "Content-Type": "application/x-www-form-urlencoded" },
  #|    body: body,
  #|  })
  #|    .then(r => r.text())
  #|    .then(text => onSuccess(text))
  #|    .catch(e => onError(e.toString()));
  #| }

#cfg(not(target="js"))
fn js_auth_fetch(url_ : String, http_method_ : String, token_ : String, on_success_ : (String) -> Unit, on_error_ : (String) -> Unit, on_auth_error_ : (String) -> Unit) -> Unit {
  ignore((url_, http_method_, token_))
  on_error_("stub")
}
#cfg(not(target="js"))
fn js_auth_post(url_ : String, token_ : String, on_success_ : (String) -> Unit, on_error_ : (String) -> Unit, on_auth_error_ : (String) -> Unit) -> Unit {
  ignore((url_, token_))
  on_error_("stub")
}
#cfg(not(target="js"))
fn js_local_storage_get(key_ : String) -> String { ignore(key_); "" }
#cfg(not(target="js"))
fn js_local_storage_set(key_ : String, value_ : String) -> Unit { ignore((key_, value_)); () }
#cfg(not(target="js"))
fn js_local_storage_remove(key_ : String) -> Unit { ignore(key_); () }

///|
fn fetch_cmd(
  emit : @cmd.Emit[Msg],
  url : String,
  http_method : String,
  token : String,
  ok_fn : (String) -> Msg,
  err_fn : (String) -> Msg,
) -> @cmd.Cmd {
  @cmd.custom_cmd(fn(scheduler : &@cmd.Scheduler) {
    js_auth_fetch(
      url,
      http_method,
      token,
      fn(body) { scheduler.add(emit(ok_fn(body))) },
      fn(e) { scheduler.add(emit(err_fn(e))) },
      fn(_) { scheduler.add(emit(AuthExpired)) },
    )
  })
}

///|
fn post_cmd(emit : @cmd.Emit[Msg], url : String, token : String) -> @cmd.Cmd {
  @cmd.custom_cmd(fn(scheduler : &@cmd.Scheduler) {
    js_auth_post(
      url,
      token,
      fn(body) { scheduler.add(emit(ToggleResult(body))) },
      fn(e) { scheduler.add(emit(ToggleFailed(e))) },
      fn(_) { scheduler.add(emit(AuthExpired)) },
    )
  })
}

///|
fn pkce_cmd(emit : @cmd.Emit[Msg]) -> @cmd.Cmd {
  @cmd.custom_cmd(fn(scheduler : &@cmd.Scheduler) {
    js_pkce_generate(
      fn(data) { scheduler.add(emit(PkceReady(data))) },
      fn(e) { scheduler.add(emit(LoginFailed(e))) },
    )
  })
}

///|
fn exchange_cmd(emit : @cmd.Emit[Msg], code : String) -> @cmd.Cmd {
  let (auth_url_str, client_id_str, _) = parse_config()
  let pkce_verifier = js_session_get("pkce_verifier")
  let body = "grant_type=authorization_code&code=" + js_url_encode(code) + "&redirect_uri=" + js_url_encode(redirect_uri) + "&client_id=" + js_url_encode(client_id_str)
  let body = if pkce_verifier != "" { body + "&code_verifier=" + pkce_verifier } else { body }
  @cmd.custom_cmd(fn(scheduler : &@cmd.Scheduler) {
    js_form_post(
      auth_url_str + "/application/o/token/",
      body,
      fn(response_text) {
        let json = @json.parse(response_text) catch { _ => { scheduler.add(emit(LoginFailed("Invalid JSON"))); return } }
        match json {
          Json::Object(obj) => {
            let token = match obj.get("id_token") { Some(Json::String(s)) => s; _ => match obj.get("access_token") { Some(Json::String(s)) => s; _ => "" } }
            if token != "" {
              scheduler.add(emit(AuthCallback(token)))
            } else {
              scheduler.add(emit(LoginFailed("No token in response")))
            }
          }
          _ => scheduler.add(emit(LoginFailed("Unexpected response")))
        }
      },
      fn(e) { scheduler.add(emit(LoginFailed(e))) },
    )
  })
}

// --- JSON parsing ---

/// Golem HTTP endpoints return String as a JSON-encoded string.
/// This helper unwraps one level of JSON string encoding if needed.
///|
fn parse_body_json(body : String) -> Result[Json, String] {
  let first = @json.parse(body) catch {
    _ => return Err("Invalid JSON")
  }
  match first {
    Json::String(s) => {
      let inner = @json.parse(s) catch {
        _ => return Err("Invalid nested JSON")
      }
      Ok(inner)
    }
    _ => Ok(first)
  }
}

///|
fn parse_string_array(body : String) -> Array[String] {
  // Golem wraps String returns as JSON strings — try unwrap first
  let json = @json.parse(body) catch { _ => return [] }
  let json = match json {
    Json::String(s) => @json.parse(s) catch { _ => return [] }
    j => j
  }
  match json {
    Json::Array(arr) => {
      let result : Array[String] = []
      for item in arr {
        match item {
          Json::String(s) => result.push(s)
          Json::Object(obj) => {
            match obj.get("term") { Some(Json::String(s)) => result.push(s); _ => () }
            match obj.get("class_level") { Some(Json::String(s)) => result.push(s); _ => () }
          }
          _ => ()
        }
      }
      result
    }
    _ => []
  }
}

///|
fn parse_subjects(body : String) -> Array[SubjectInfo] {
  let json = parse_body_json(body)
  match json {
    Ok(Json::Array(arr)) =>
      arr.map(fn(item) {
        match item {
          Json::Object(obj) => {
            let name : String = match obj.get("subject") {
              Some(Json::String(s)) => s
              _ => "unknown"
            }
            { id: name, name }
          }
          _ => { id: "unknown", name: "unknown" }
        }
      })
    _ => []
  }
}

///|
fn parse_lessons(body : String) -> Array[LessonInfo] {
  let json = parse_body_json(body)
  match json {
    Ok(Json::Array(arr)) =>
      arr.map(fn(item) {
        match item {
          Json::Object(obj) => {
            let id : String = match obj.get("id") {
              Some(Json::String(s)) => s
              _ => "unknown"
            }
            let title : String = match obj.get("topic_title") {
              Some(Json::String(s)) => s
              _ => "unknown"
            }
            let week : Double = match obj.get("week") {
              Some(Json::Number(n, ..)) => n
              _ => 0.0
            }
            let term : String = match obj.get("term") {
              Some(Json::String(s)) => s
              _ => ""
            }
            let subject : String = match obj.get("subject") {
              Some(Json::String(s)) => s
              _ => ""
            }
            let active : Bool = match obj.get("active") {
              Some(Json::True) => true
              Some(Json::False) => false
              _ => true
            }
            { id, title, week, term, subject, active }
          }
          _ => { id: "unknown", title: "unknown", week: 0.0, term: "", subject: "", active: true }
        }
      })
    _ => []
  }
}

///|
fn parse_lesson_content(body : String) -> Option[LessonContent] {
  let json = parse_body_json(body)
  match json {
    Ok(Json::Array(arr)) => {
      if arr.length() > 0 {
        match arr[0] {
          Json::Object(obj) => Some(parse_lesson_obj(obj))
          _ => None
        }
      } else {
        None
      }
    }
    Ok(Json::Object(obj)) => Some(parse_lesson_obj(obj))
    _ => None
  }
}

///|
fn parse_lesson_obj(obj : Map[String, Json]) -> LessonContent {
  let id : String = match obj.get("id") {
    Some(Json::String(s)) => s
    _ => "unknown"
  }
  let title : String = match obj.get("topic_title") {
    Some(Json::String(s)) => s
    _ =>
      match obj.get("title") {
        Some(Json::String(s)) => s
        _ => "unknown"
      }
  }
  let subject : String = match obj.get("subject") {
    Some(Json::String(s)) => s
    _ => ""
  }
  let week : Double = match obj.get("week") {
    Some(Json::Number(n, ..)) => n
    _ => 0.0
  }
  let term : String = match obj.get("term") {
    Some(Json::String(s)) => s
    _ => ""
  }
  let active : Bool = match obj.get("active") {
    Some(Json::True) => true
    Some(Json::False) => false
    _ => true
  }
  let content : String = match obj.get("content") {
    Some(Json::String(s)) => s
    _ =>
      match obj.get("lesson_steps") {
        Some(steps) => steps.stringify()
        _ => Json::object(obj).stringify()
      }
  }
  { id, title, subject, week, term, active, content }
}

///|
fn week_str(week : Double) -> String {
  let i = week.to_int()
  i.to_string()
}

// --- Update ---

///|
fn route_cmd(emit : @cmd.Emit[Msg], token : String, route : Route) -> @cmd.Cmd {
  match route {
    Home => fetch_cmd(emit, api_base() + "/classes", "GET", token, fn(b) { ClassesLoaded(b) }, fn(e) { ClassesFailed(e) })
    ClassDetail(cl) => fetch_cmd(emit, api_base() + "/subjects?class=" + js_url_encode(cl), "GET", token, fn(b) { SubjectsLoaded(b) }, fn(e) { SubjectsFailed(e) })
    SubjectDetail(cl, sub) => fetch_cmd(emit, api_base() + "/terms?class=" + js_url_encode(cl) + "&subject=" + js_url_encode(sub), "GET", token, fn(b) { TermsLoaded(b) }, fn(e) { TermsFailed(e) })
    TermDetail(cl, sub, term) => fetch_cmd(emit, api_base() + "/subjects/" + js_url_encode(sub) + "/lessons?class=" + js_url_encode(cl) + "&term=" + js_url_encode(term), "GET", token, fn(b) { LessonsLoaded(b) }, fn(e) { LessonsFailed(e) })
    LessonDetail(id) => fetch_cmd(emit, api_base() + "/lessons/" + id, "GET", token, fn(b) { LessonLoaded(b) }, fn(e) { LessonFailed(e) })
    Admin => @cmd.none
    Login => @cmd.none
    Callback(_) => @cmd.none
  }
}

///|
fn update(emit : @cmd.Emit[Msg], msg : Msg, model : Model) -> (@cmd.Cmd, Model) {
  match msg {
    UrlChanged(url) => {
      let route = route_from_path(url.path)
      match route {
        Callback(_) => {
          let code = js_get_query_param("code")
          let returned_state = js_get_query_param("state")
          let stored_state = js_session_get("oauth_state")
          if stored_state != "" && returned_state != stored_state {
            (@nav.push_url("/login"), { ..model, route: Login, loading: false, error: "CSRF check failed: state mismatch" })
          } else if code != "" {
            let cmd = exchange_cmd(emit, code)
            (cmd, { ..model, route, loading: true, error: "" })
          } else {
            (@nav.push_url("/login"), { ..model, route: Login, loading: false, error: "No authorization code received" })
          }
        }
        _ => match (model.token == "", route) {
          (true, Login) => {
            (@cmd.none, { ..model, route, loading: false, error: "" })
          }
          (true, _) => {
            (@nav.push_url("/login"), { ..model, route: Login, loading: false, error: "" })
          }
          _ => {
            let cmd = route_cmd(emit, model.token, route)
            (cmd, { ..model, route, loading: true, error: "" })
          }
        }
      }
    }
    UrlRequest(req) => {
      match req {
        @url.UrlRequest::Internal(url) => {
          let push_path = if url.path.has_prefix("/") { url.path } else { "/" + url.path }
          (@nav.push_url(push_path), model)
        }
        @url.UrlRequest::External(href) => (@nav.load(href), model)
      }
    }
    ClassesLoaded(body) => {
      let classes = parse_string_array(body)
      (@cmd.none, { ..model, classes, loading: false, error: "" })
    }
    ClassesFailed(err) =>
      (@cmd.none, { ..model, loading: false, error: "Failed to load classes: " + err })
    SubjectsLoaded(body) => {
      let subjects = parse_subjects(body)
      let deduped : Array[SubjectInfo] = []
      for s in subjects {
        let mut found = false
        let key = s.name.to_lower()
        for d in deduped {
          if d.name.to_lower() == key { found = true; break }
        }
        if !found { deduped.push(s) }
      }
      if subjects.length() == 0 && body != "" && body != "[]" {
        (@cmd.none, { ..model, loading: false, error: "Failed to parse subjects data" })
      } else {
        (@cmd.none, { ..model, subjects: deduped, loading: false, error: "" })
      }
    }
    SubjectsFailed(err) =>
      (@cmd.none, { ..model, loading: false, error: "Failed to load subjects: " + err })
    TermsLoaded(body) => {
      let terms = parse_string_array(body)
      (@cmd.none, { ..model, terms, loading: false, error: "" })
    }
    TermsFailed(err) =>
      (@cmd.none, { ..model, loading: false, error: "Failed to load terms: " + err })
    LessonsLoaded(body) => {
      let lessons = parse_lessons(body)
      if lessons.length() == 0 && body != "" && body != "[]" {
        (@cmd.none, { ..model, loading: false, error: "Failed to parse lessons data" })
      } else {
        (@cmd.none, { ..model, lessons, loading: false, error: "" })
      }
    }
    LessonsFailed(err) =>
      (@cmd.none, { ..model, loading: false, error: "Failed to load lessons: " + err })
    LessonLoaded(body) => {
      let lesson = parse_lesson_content(body)
      match lesson {
        None => if body != "" && body != "[]" {
          (@cmd.none, { ..model, loading: false, error: "Failed to parse lesson data" })
        } else {
          (@cmd.none, { ..model, current_lesson: None, loading: false, error: "" })
        }
        _ => (@cmd.none, { ..model, current_lesson: lesson, loading: false, error: "" })
      }
    }
    LessonFailed(err) =>
      (@cmd.none, { ..model, loading: false, error: "Failed to load lesson: " + err })
    ToggleLesson(id) =>
      if model.loading { (@cmd.none, model) } else {
        (post_cmd(emit, api_base() + "/lessons/" + id + "/toggle", model.token), { ..model, loading: true })
      }
    ToggleResult(_) => {
      let cmd = match model.current_lesson {
        Some(lesson) =>
          fetch_cmd(emit, api_base() + "/lessons/" + lesson.id, "GET", model.token, fn(b) { LessonLoaded(b) }, fn(e) { LessonFailed(e) })
        None => @cmd.none
      }
      (cmd, { ..model, loading: true })
    }
    ToggleFailed(err) =>
      (@cmd.none, { ..model, loading: false, error: "Toggle failed: " + err })
    Logout => {
      js_local_storage_remove("jwt_token")
      let model = init_model()
      (@nav.push_url("/login"), { ..model, route: Login })
    }
    LoginWithAuthentik => {
      (pkce_cmd(emit), { ..model, loading: true, error: "" })
    }
    PkceReady(data) => {
      let (auth_url_str, client_id_str, _) = parse_config()
      let json = @json.parse(data) catch { _ => return (@cmd.none, { ..model, loading: false, error: "PKCE failed" }) }
      match json {
        Json::Object(obj) => {
          let verifier = match obj.get("v") { Some(Json::String(s)) => s; _ => "" }
          let challenge = match obj.get("c") { Some(Json::String(s)) => s; _ => "" }
          if verifier == "" || challenge == "" {
            return (@cmd.none, { ..model, loading: false, error: "PKCE generation failed" })
          }
          js_session_set("pkce_verifier", verifier)
          let state = "csrf_" + verifier[0:10].to_owned()
          js_session_set("oauth_state", state)
          let url = auth_url_str + "/application/o/authorize/?client_id=" + js_url_encode(client_id_str) + "&redirect_uri=" + js_url_encode(redirect_uri) + "&response_type=code&scope=openid+profile+email&code_challenge=" + challenge + "&code_challenge_method=S256&state=" + js_url_encode(state)
          js_redirect(url)
          (@cmd.none, { ..model, loading: false, error: "" })
        }
        _ => (@cmd.none, { ..model, loading: false, error: "PKCE parse failed" })
      }
    }
    AuthCallback(body) => {
      let token = body
      let role = role_from_jwt(token)
      let class_level = js_get_user_class(token)
      js_local_storage_set("jwt_token", token)
      js_session_set("pkce_verifier", "")
      js_session_set("oauth_state", "")
      (@nav.push_url("/"), { ..model, token, role, class_level, error: "", route: Home })
    }
    LoginFailed(err) => {
      js_session_set("pkce_verifier", "")
      js_session_set("oauth_state", "")
      (@nav.push_url("/login"), { ..model, loading: false, error: "Login failed: " + err, route: Login })
    }
    AuthExpired => {
      js_local_storage_remove("jwt_token")
      (@nav.push_url("/login"), { ..init_model(), route: Login, error: "Session expired. Please sign in again." })
    }
  }
}

// --- View ---

///|
fn view(emit : @cmd.Emit[Msg], model : Model) -> @html.Html {
  @html.div(
    style=["max-width: 900px", "margin: 0 auto", "padding: 20px", "font-family: -apple-system,BlinkMacSystemFont,Segoe UI,Roboto,sans-serif"],
    [
      view_nav(emit, model),
      if model.loading {
        @html.div(style=["padding: 40px", "text-align: center"], "Loading...")
      } else if model.error != "" {
        @html.div(style=["color: red", "padding: 12px"], model.error)
      } else {
        view_content(emit, model)
      },
    ],
  )
}

///|
fn view_nav(emit : @cmd.Emit[Msg], model : Model) -> @html.Html {
  let nav_items : Array[@html.Html] = []
  nav_items.push(
    @html.a(href="/", style=["font-weight: bold", "text-decoration: none", "color: #333"], "Johnethel Lessons"),
  )
  if model.token != "" {
    let info = if model.class_level != "" { model.role + " \u00b7 " + model.class_level } else { model.role }
    nav_items.push(
      @html.span(
        style=["margin-left: 12px", "color: #666", "font-size: 12px"],
        info,
      ),
    )
    if model.role == "admin" {
      nav_items.push(@html.a(href="/admin", style=["margin-left: 12px"], "Admin"))
    }
    nav_items.push(
      @html.button(
        on_click=emit(Logout),
        style=["margin-left: auto", "padding: 4px 12px", "border: 1px solid #ccc", "border-radius: 4px", "cursor: pointer"],
        "Logout",
      ),
    )
  } else {
    nav_items.push(
      @html.a(
        href="/login",
        style=["margin-left: auto", "padding: 4px 12px", "border: 1px solid #ccc", "border-radius: 4px", "text-decoration: none", "color: #333"],
        "Sign in",
      ),
    )
  }
  @html.nav(
    style=["display: flex", "align-items: center", "gap: 12px", "padding: 12px 0", "border-bottom: 1px solid #ddd", "margin-bottom: 20px"],
    nav_items,
  )
}

///|
fn view_content(emit : @cmd.Emit[Msg], model : Model) -> @html.Html {
  match model.route {
    Home => view_home(emit, model)
    ClassDetail(cl) => view_class(emit, model, cl)
    SubjectDetail(cl, sub) => view_subject(emit, model, cl, sub)
    TermDetail(cl, sub, term) => view_term(emit, model, cl, sub, term)
    LessonDetail(_) => view_lesson(emit, model)
    Admin => view_admin()
    Login => view_login(emit, model)
    Callback(_) => view_login(emit, model)
  }
}

///|
fn view_login(emit : @cmd.Emit[Msg], model : Model) -> @html.Html {
  @html.div(
    style=["max-width: 400px", "margin: 80px auto", "text-align: center"],
    [
      @html.h2("Johnethel School"),
      @html.p("Sign in to continue."),
      @html.button(
        on_click=emit(LoginWithAuthentik),
        style=["padding: 12px 32px", "margin: 12px 0", "background: #3a7bd5", "color: white", "border: none", "border-radius: 6px", "cursor: pointer", "font-size: 14px"],
        "Sign in with Authentik",
      ),
    ],
  )
}

///|
let allowed_classes : Array[String] = ["JSS_1", "JSS_2", "JSS_3", "SS1", "SS2", "SS3", "PRIMARY_1", "PRIMARY_2", "PRIMARY_3", "PRIMARY_4", "PRIMARY_5"]

///|
fn format_class_name(cl : String) -> String {
  match cl {
    "JSS_1" => "JSS 1"
    "JSS_2" => "JSS 2"
    "JSS_3" => "JSS 3"
    "SS1" => "SS 1"
    "SS2" => "SS 2"
    "SS3" => "SS 3"
    "PRIMARY_1" => "Primary 1"
    "PRIMARY_2" => "Primary 2"
    "PRIMARY_3" => "Primary 3"
    "PRIMARY_4" => "Primary 4"
    "PRIMARY_5" => "Primary 5"
    _ => cl
  }
}

///|
fn view_home(emit : @cmd.Emit[Msg], model : Model) -> @html.Html {
  let _ = emit
  @html.div(
    [
      @html.h1("Classes"),
      @html.p(style=["color: #666", "font-size: 14px", "margin-bottom: 12px"], "Select your class to view subjects and lessons."),
      if model.classes.length() == 0 {
        @html.p("No classes found.")
      } else {
        @html.ul(
          style=["list-style: none", "padding: 0", "display: grid", "grid-template-columns: repeat(auto-fill, minmax(200px, 1fr))", "gap: 12px"],
          model.classes.filter(fn(cl) { allowed_classes.contains(cl) }).map(fn(cl) {
            let label = format_class_name(cl)
            @html.li(
              [@html.a(
                href="/class/" + cl,
                style=["display: block", "padding: 20px", "background: #f0f4ff", "border-radius: 8px", "text-decoration: none", "color: #333", "font-weight: 600", "text-align: center"],
                label,
              )],
            )
          }),
        )
      },
    ],
  )
}

///|
fn view_class(emit : @cmd.Emit[Msg], model : Model, class_id : String) -> @html.Html {
  let _ = emit
  @html.div(
    [
      @html.a(href="/", style=["color: #666"], "\u2190 Back to classes"),
      @html.h1("Subjects for " + format_class_name(class_id)),
      if model.subjects.length() == 0 {
        @html.p("No subjects found for this class.")
      } else {
        @html.ul(
          style=["list-style: none", "padding: 0"],
          model.subjects.map(fn(s) {
            @html.li(
              style=["margin: 8px 0"],
              [@html.a(
                href="/class/" + class_id + "/" + js_url_encode(s.name),
                style=["display: block", "padding: 12px 16px", "background: #f8f9fa", "border-radius: 6px", "text-decoration: none", "color: #333"],
                s.name,
              )],
            )
          }),
        )
      },
    ],
  )
}

///|
fn view_subject(emit : @cmd.Emit[Msg], model : Model, class_id : String, subject_id : String) -> @html.Html {
  let _ = emit
  @html.div(
    [
      @html.a(href="/class/" + class_id, style=["color: #666"], "\u2190 Back to subjects"),
      @html.h1(js_url_decode(subject_id)),
      @html.p(style=["color: #666"], "Class: " + format_class_name(class_id)),
      if model.terms.length() == 0 {
        @html.p("No terms found for this subject.")
      } else {
        @html.ul(
          style=["list-style: none", "padding: 0", "display: flex", "gap: 12px", "flex-wrap: wrap"],
          model.terms.map(fn(term) {
            @html.li(
              [@html.a(
                href="/class/" + class_id + "/" + js_url_encode(subject_id) + "/" + term,
                style=["display: block", "padding: 16px 24px", "background: #f0f4ff", "border-radius: 8px", "text-decoration: none", "color: #333", "font-weight: 500"],
                term + " Term",
              )],
            )
          }),
        )
      },
    ],
  )
}

///|
fn view_term(emit : @cmd.Emit[Msg], model : Model, class_id : String, subject_id : String, term_id : String) -> @html.Html {
  let _ = emit
  let is_teacher = model.role == "teacher" || model.role == "admin"
  let visible_lessons = if is_teacher {
    model.lessons
  } else {
    model.lessons.filter(fn(l) { l.active })
  }
  @html.div(
    [
      @html.a(href="/class/" + class_id + "/" + subject_id, style=["color: #666"], "\u2190 Back to terms"),
      @html.h1("Lessons for " + js_url_decode(subject_id)),
      @html.p(style=["color: #666"], "Class: " + format_class_name(class_id) + " \u00b7 " + term_id + " Term"),
      if visible_lessons.length() == 0 {
        let msg = if is_teacher {
          "No lessons found for this term."
        } else {
          "No active lessons available for this term. Check back later or contact your teacher."
        }
        @html.p(msg)
      } else {
        @html.ul(
          style=["list-style: none", "padding: 0"],
          visible_lessons.map(fn(l) {
            if l.active {
              @html.li(
                style=["margin: 8px 0"],
                [@html.a(
                  href="/lessons/" + l.id,
                  style=["display: block", "padding: 12px 16px", "background: #f8f9fa", "border-radius: 6px", "text-decoration: none", "color: #333"],
                  "Week " + week_str(l.week) + ": " + l.title + " (" + l.term + ")",
                )],
              )
            } else {
              @html.li(
                style=["margin: 8px 0"],
                [@html.div(
                  style=["display: block", "padding: 12px 16px", "background: #e9ecef", "border-radius: 6px", "color: #6c757d"],
                  "Week " + week_str(l.week) + ": " + l.title + " (" + l.term + ") — Inactive",
                )],
              )
            }
          }),
        )
      },
    ],
  )
}

///|
fn view_lesson(emit : @cmd.Emit[Msg], model : Model) -> @html.Html {
  match model.current_lesson {
    Some(lesson) => {
      let bg_color = if lesson.active { "#d4edda" } else { "#fff3cd" }
      let status_text = if lesson.active { "Lesson is active" } else { "This lesson is currently inactive." }
      let is_teacher = model.role == "teacher" || model.role == "admin"
      let children : Array[@html.Html] = [
        @html.a(href="/subjects/" + lesson.subject, style=["color: #666"], "\u2190 Back to " + lesson.subject),
        @html.h1(lesson.title),
        @html.div(
          style=["margin-bottom: 16px", "color: #666"],
          "Week " + week_str(lesson.week) + " \u00b7 " + lesson.term,
        ),
        @html.div(
          style=["background: " + bg_color, "padding: 8px 12px", "border-radius: 4px", "margin-bottom: 12px"],
          status_text,
        ),
      ]
      if is_teacher {
        let btn_bg = if lesson.active { "#6c757d" } else { "#007bff" }
        let btn_text = if lesson.active { "Deactivate" } else { "Activate" }
        children.push(
          @html.button(
            on_click=emit(ToggleLesson(lesson.id)),
            style=["padding: 6px 16px", "margin-bottom: 16px", "background: " + btn_bg, "color: white", "border: none", "border-radius: 4px", "cursor: pointer"],
            btn_text,
          ),
        )
      }
      children.push(
        @html.div(
          style=["white-space: pre-wrap", "line-height: 1.6"],
          lesson.content,
        ),
      )
      @html.div(children)
    }
    None => @html.div("Lesson not found.")
  }
}

///|
fn view_admin() -> @html.Html {
  @html.div(
    [
      @html.h1("Admin"),
      @html.p("Admin panel \u2014 subject management coming soon."),
    ],
  )
}

// --- Subscriptions ---

///|
fn subscriptions(emit : @cmd.Emit[Msg], _model : Model) -> @sub.Sub {
  @sub.batch([
    @sub.on_url_changed(fn(url) { emit(UrlChanged(url)) }),
    @sub.on_url_request(fn(req) { emit(UrlRequest(req)) }),
  ])
}

// --- Entry point ---

///|
fn main {
  let token = js_local_storage_get("jwt_token")
  let role = role_from_jwt(token)
  let class_level = js_get_user_class(token)
  let url_path = js_current_url()
  let initial_route = route_from_path(url_path)
  let route = if token == "" && initial_route != Login && initial_route != Callback("") {
    Login
  } else {
    initial_route
  }
  // Show loading immediately for data routes before UrlChanged fires
  let loading = match route {
    Home | SubjectDetail(_) | LessonDetail(_) | Callback(_) => true
    _ => false
  }
  let model = { ..init_model(), token, role, class_level, route, loading }
  let (_emit, root) = @rabbita.cell_with_emit(
    model~,
    update~,
    view~,
    subscriptions~,
  )
  let app = @rabbita.new(root)
  app.mount("app")
}