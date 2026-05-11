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
/// WORKAROUND: Required because `read_bytes` is capped at 64KB per call.
fn read_file_bytes(path : String) -> Bytes {
  let root = match @fs.get_root_dir() {
    Some(r) => r
    None => return b""
  }
  let fd = match root.open_at(
    @fsTypes.PathFlags::default(),
    path,
    @fsTypes.OpenFlags::default(),
    @fsTypes.DescriptorFlags::default().set(@fsTypes.DescriptorFlagsFlag::READ),
  ) {
    Ok(f) => f
    Err(_) => return b""
  }
  let s = match fd.stat() {
    Ok(st) => st
    Err(_) => return b""
  }
  let chunk_size : UInt64 = 32768
  let mut offset : UInt64 = 0
  let acc : Array[Byte] = []
  while offset < s.size {
    let remaining = s.size - offset
    let to_read = if remaining < chunk_size { remaining } else { chunk_size }
    match fd.read(to_read, offset) {
      Err(_) => break
      Ok((chunk, eof)) => {
        for b in chunk {
          acc.push(b)
        }
        offset += chunk.length().to_int64().reinterpret_as_uint64()
        if eof { break }
      }
    }
  }
  Bytes::from_array(acc)
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
    let script = "window.__CONFIG__={authentikUrl:\"" + auth_url + "\",clientId:\"" + client_id + "\",apiUrl:\"" + api_url + "\"};"
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
