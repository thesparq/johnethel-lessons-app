///|
/// Static file server agent — ephemeral (stateless)
#derive.agent("ephemeral")
#derive.mount("/")
struct FileServerAgent {}

///|
fn FileServerAgent::new() -> FileServerAgent {
  FileServerAgent::{}
}

///|
/// Read full file contents via chunked reads.
/// Returns empty bytes if file does not exist (caller checks length for fallback).
/// WORKAROUND REMOVED: Golem 1.5.1 fixes the 64KB read limit.
fn read_file_bytes(path : String) -> Bytes {
  let root = match @fs.get_root_dir() {
    Some(r) => r
    None => return b""
  }
  match @fs.read_bytes(root, path) {
    Ok(bytes) => {
      let arr : Array[Byte] = []
      for b in bytes { arr.push(b) }
      Bytes::from_array(arr)
    }
    Err(_) => b""
  }
}

///|
fn mime_type(path : String) -> String {
  if path.has_suffix(".html") {
    "text/html"
  } else if path.has_suffix(".js") {
    "application/javascript"
  } else if path.has_suffix(".css") {
    "text/css"
  } else if path.has_suffix(".json") {
    "application/json"
  } else if path.has_suffix(".png") {
    "image/png"
  } else if path.has_suffix(".svg") {
    "image/svg+xml"
  } else {
    "application/octet-stream"
  }
}

fn js_string_escape(s : String) -> String {
  let chars = s.to_array()
  let mut r = ""
  for i = 0; i < chars.length(); i = i + 1 {
    let c = chars[i]
    if c == '"' { r = r + "\\\"" } else if c == '\\' { r = r + "\\\\" } else { r = r + c.to_string() }
  }
  r
}

///|
/// Serve static files. Falls back to index.html for SPA routing.
/// Special handling for /config.js — generated from env vars.
#derive.endpoint(get="/{*path}")
pub fn FileServerAgent::download_file(
  self : Self,
  path : String,
) -> @types.UnstructuredBinary {
  ignore(self)
  // Dynamic config.js from env vars
  if path == "config.js" {
    let auth_url = get_env_s("AUTHENTIK_URL", "")
    let client_id = get_env_s("AUTHENTIK_CLIENT_ID", "")
    let api_url = get_env_s("API_URL", "http://johnethel-lessons-app.localhost:9006")
    let script = "window.__CONFIG__={authentikUrl:\"" + js_string_escape(auth_url) + "\",clientId:\"" + js_string_escape(client_id) + "\",apiUrl:\"" + js_string_escape(api_url) + "\"};"
    let bytes = str_to_fixed_bytes(script)
    return @types.UnstructuredBinary::from_inline(bytes, mime_type="application/javascript")
  }
  let full_path = if path == "" { "index.html" } else { path }
  let bytes = read_file_bytes(full_path)
  // SPA fallback: if file not found and path looks like a route, serve index.html
  let (final_path, final_bytes) = if bytes.length() == 0 && full_path != "index.html" {
    ("index.html", read_file_bytes("index.html"))
  } else {
    (full_path, bytes)
  }
  @types.UnstructuredBinary::from_inline(final_bytes, mime_type=mime_type(final_path))
}

///|
fn get_env_s(name : String, default : String) -> String {
  let envs = @environment.get_environment()
  for pair in envs {
    if pair.0 == name {
      return pair.1
    }
  }
  default
}

///|
fn str_to_fixed_bytes(s : String) -> Bytes {
  let arr : Array[Byte] = []
  for i = 0; i < s.length(); i = i + 1 {
    arr.push(s[i].to_int().to_byte())
  }
  Bytes::from_array(arr)
}

///|
fn main {

}
