///|
let api_base : String = "http://johnethel-lessons-app.localhost:9006"

///|
enum Route {
  Home
  SubjectDetail(String)
  LessonDetail(String)
  Admin
  Login
}

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
  SubjectsLoaded(String)
  SubjectsFailed(String)
  LessonsLoaded(String)
  LessonsFailed(String)
  LessonLoaded(String)
  LessonFailed(String)
  ToggleLesson(String)
  ToggleResult(String)
  ToggleFailed(String)
  TokenInput(String)
  LoginSubmit
  Logout
}

///|
struct Model {
  route : Route
  token : String
  token_input : String
  role : String
  subjects : Array[SubjectInfo]
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
    token_input: "",
    role: "student",
    subjects: [],
    lessons: [],
    current_lesson: None,
    loading: false,
    error: "",
  }
}

///|
fn role_from_token(token : String) -> String {
  let parts = token.split("|").to_array()
  if parts.length() == 2 {
    parts[1].to_owned()
  } else {
    "student"
  }
}

///|
fn route_from_path(path : String) -> Route {
  let path = if path.has_prefix("/") { path } else { "/" + path }
  let segments = path.split("/").to_array()
  match segments {
    ["", ""] => Home
    ["", "subjects", id] => SubjectDetail(id.to_owned())
    ["", "lessons", id] => LessonDetail(id.to_owned())
    ["", "admin"] => Admin
    ["", "login"] => Login
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
) -> Unit =
  #|(url, httpMethod, token, onSuccess, onError) => {
  #|  const config = { method: httpMethod, headers: { "Authorization": "Bearer " + token } };
  #|  fetch(url, config)
  #|    .then(r => { if (!r.ok) throw new Error("HTTP " + r.status); return r.text(); })
  #|    .then(text => onSuccess(text))
  #|    .catch(e => onError(e.toString()));
  #| }

#cfg(target="js")
extern "js" fn js_auth_post(
  url : String,
  token : String,
  on_success : (String) -> Unit,
  on_error : (String) -> Unit,
) -> Unit =
  #|(url, token, onSuccess, onError) => {
  #|  const config = { method: "POST", headers: { "Authorization": "Bearer " + token } };
  #|  fetch(url, config)
  #|    .then(r => { if (!r.ok) throw new Error("HTTP " + r.status); return r.text(); })
  #|    .then(text => onSuccess(text))
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

#cfg(not(target="js"))
fn js_auth_fetch(url_ : String, http_method_ : String, token_ : String, on_success_ : (String) -> Unit, on_error_ : (String) -> Unit) -> Unit {
  ignore((url_, http_method_, token_))
  on_error_("stub")
}
#cfg(not(target="js"))
fn js_auth_post(url_ : String, token_ : String, on_success_ : (String) -> Unit, on_error_ : (String) -> Unit) -> Unit {
  ignore((url_, token_))
  on_error_("stub")
}
#cfg(not(target="js"))
fn js_local_storage_get(key_ : String) -> String { ignore(key_); "" }
#cfg(not(target="js"))
fn js_local_storage_set(key_ : String, value_ : String) -> Unit { ignore((key_, value_)); () }
#cfg(not(target="js"))
fn js_local_storage_remove(key_ : String) -> Unit { ignore(key_); () }

// --- API commands ---

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
            { id, title, week, term, subject }
          }
          _ => { id: "unknown", title: "unknown", week: 0.0, term: "", subject: "" }
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
    Home => fetch_cmd(emit, api_base + "/subjects", "GET", token, fn(b) { SubjectsLoaded(b) }, fn(e) { SubjectsFailed(e) })
    SubjectDetail(subject) => fetch_cmd(emit, api_base + "/subjects/" + subject + "/lessons", "GET", token, fn(b) { LessonsLoaded(b) }, fn(e) { LessonsFailed(e) })
    LessonDetail(id) => fetch_cmd(emit, api_base + "/lessons/" + id, "GET", token, fn(b) { LessonLoaded(b) }, fn(e) { LessonFailed(e) })
    Admin => @cmd.none
    Login => @cmd.none
  }
}

///|
fn update(emit : @cmd.Emit[Msg], msg : Msg, model : Model) -> (@cmd.Cmd, Model) {
  match msg {
    UrlChanged(url) => {
      let route = route_from_path(url.path)
      match (model.token == "", route) {
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
    UrlRequest(req) => {
      match req {
        @url.UrlRequest::Internal(url) => {
          let push_path = if url.path.has_prefix("/") { url.path } else { "/" + url.path }
          (@nav.push_url(push_path), model)
        }
        @url.UrlRequest::External(href) => (@nav.load(href), model)
      }
    }
    SubjectsLoaded(body) => {
      let subjects = parse_subjects(body)
      (@cmd.none, { ..model, subjects, loading: false, error: "" })
    }
    SubjectsFailed(err) =>
      (@cmd.none, { ..model, loading: false, error: "Failed to load subjects: " + err })
    LessonsLoaded(body) => {
      let lessons = parse_lessons(body)
      (@cmd.none, { ..model, lessons, loading: false, error: "" })
    }
    LessonsFailed(err) =>
      (@cmd.none, { ..model, loading: false, error: "Failed to load lessons: " + err })
    LessonLoaded(body) => {
      let lesson = parse_lesson_content(body)
      (@cmd.none, { ..model, current_lesson: lesson, loading: false, error: "" })
    }
    LessonFailed(err) =>
      (@cmd.none, { ..model, loading: false, error: "Failed to load lesson: " + err })
    ToggleLesson(id) =>
      (post_cmd(emit, api_base + "/lessons/" + id + "/toggle", model.token), { ..model, loading: true })
    ToggleResult(_) => {
      let cmd = match model.current_lesson {
        Some(lesson) =>
          fetch_cmd(emit, api_base + "/lessons/" + lesson.id, "GET", model.token, fn(b) { LessonLoaded(b) }, fn(e) { LessonFailed(e) })
        None => @cmd.none
      }
      (cmd, { ..model, loading: true })
    }
    ToggleFailed(err) =>
      (@cmd.none, { ..model, loading: false, error: "Toggle failed: " + err })
    TokenInput(text) => (@cmd.none, { ..model, token_input: text })
    LoginSubmit => {
      let token = model.token_input
      let role = role_from_token(token)
      js_local_storage_set("jwt_token", token)
      (@nav.push_url("/"), { ..model, token, role, error: "", route: Home })
    }
    Logout => {
      js_local_storage_remove("jwt_token")
      let model = init_model()
      (@nav.push_url("/login"), { ..model, route: Login })
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
    nav_items.push(
      @html.span(
        style=["margin-left: 12px", "color: #666", "font-size: 12px"],
        "Role: " + model.role,
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
    SubjectDetail(_) => view_subject(emit, model)
    LessonDetail(_) => view_lesson(emit, model)
    Admin => view_admin()
    Login => view_login(emit, model)
  }
}

///|
fn view_login(emit : @cmd.Emit[Msg], model : Model) -> @html.Html {
  @html.div(
    style=["max-width: 400px", "margin: 80px auto", "text-align: center"],
    [
      @html.h2("Johnethel School"),
      @html.p("Sign in to continue."),
      @html.div(
        style=["font-size: 12px", "color: #666", "margin-bottom: 12px"],
        "Formats: username|role  (e.g.  teacher|teacher,  admin|admin,  student|student)",
      ),
      @html.input(
        placeholder="username|role",
        value=model.token_input,
        on_input=fn(s) { emit(TokenInput(s)) },
        style=["width: 100%", "padding: 8px", "margin: 8px 0", "box-sizing: border-box"],
        "",
      ),
      @html.button(
        on_click=emit(LoginSubmit),
        style=["padding: 8px 24px", "margin-top: 8px", "border: 1px solid #ccc", "border-radius: 4px", "cursor: pointer"],
        "Sign in",
      ),
    ],
  )
}

///|
fn view_home(emit : @cmd.Emit[Msg], model : Model) -> @html.Html {
  let _ = emit
  @html.div(
    [
      @html.h1("Subjects"),
      if model.subjects.length() == 0 {
        @html.p("No subjects found.")
      } else {
        @html.ul(
          style=["list-style: none", "padding: 0"],
          model.subjects.map(fn(s) {
            @html.li(
              style=["margin: 8px 0"],
              [@html.a(
                href="/subjects/" + s.id,
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
fn view_subject(emit : @cmd.Emit[Msg], model : Model) -> @html.Html {
  let _ = emit
  let subject_id = match model.route {
    SubjectDetail(id) => id
    _ => ""
  }
  @html.div(
    [
      @html.a(href="/", style=["color: #666"], "\u2190 Back to subjects"),
      @html.h1("Lessons for " + subject_id),
      if model.lessons.length() == 0 {
        @html.p("No lessons found for this subject.")
      } else {
        @html.ul(
          style=["list-style: none", "padding: 0"],
          model.lessons.map(fn(l) {
            @html.li(
              style=["margin: 8px 0"],
              [@html.a(
                href="/lessons/" + l.id,
                style=["display: block", "padding: 12px 16px", "background: #f8f9fa", "border-radius: 6px", "text-decoration: none", "color: #333"],
                "Week " + week_str(l.week) + ": " + l.title + " (" + l.term + ")",
              )],
            )
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
  let role = role_from_token(token)
  let route = if token == "" { Login } else { Home }
  let model = { ..init_model(), token, role, route }
  let (_emit, root) = @rabbita.cell_with_emit(
    model~,
    update~,
    view~,
    subscriptions~,
  )
  let app = @rabbita.new(root)
  app.mount("app")
}