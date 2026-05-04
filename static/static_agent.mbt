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
/// WORKAROUND: Required because `read_bytes` is capped at 64KB per call.
/// TODO: Replace with `@fs.read_bytes(root, path).unwrap()` once Golem SDK fixes the limit.
fn read_file_bytes(path : String) -> Bytes {
  let root = @fs.get_root_dir().unwrap()
  let fd = root.open_at(
    @fsTypes.PathFlags::default(),
    path,
    @fsTypes.OpenFlags::default(),
    @fsTypes.DescriptorFlags::default().set(@fsTypes.DescriptorFlagsFlag::READ),
  ).unwrap()
  let s = fd.stat().unwrap()
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
/// Serve static files
#derive.endpoint(get="/{path}")
pub fn FileServerAgent::download_file(
  self : Self,
  path : String,
) -> @types.UnstructuredBinary {
  ignore(self)
  let full_path = if path == "" { "index.html" } else { path }
  let bytes = read_file_bytes(full_path)
  @types.UnstructuredBinary::from_inline(bytes, mime_type=mime_type(full_path))
}

///|
fn main {

}
