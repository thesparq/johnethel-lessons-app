///|
/// QueryFork — ephemeral SurrealDB worker.
/// Makes blocking HTTP requests to SurrealDB, returns JSON, then dies.
/// Isolates blocking I/O from durable UserAgent.
#derive.agent("ephemeral")
struct QueryFork {
  sql : String
}

///|
fn QueryFork::new(sql : String) -> QueryFork {
  { sql }
}

///|
/// Execute the SQL query against SurrealDB and return the JSON result.
pub fn QueryFork::execute(self : Self) -> String {
  let result = surrealdb_query(self.sql)
  match result {
    Ok(json) => json.stringify()
    Err(e) => "{\"error\":\"" + e + "\"}"
  }
}

///|
/// Get environment variable by name.
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
/// Convert string to bytes (UTF-8).
fn str_to_bytes(s : String) -> FixedArray[Byte] {
  let bytes = FixedArray::make(s.length(), b'\x00')
  for i = 0; i < s.length(); i = i + 1 {
    bytes[i] = s[i].to_int().to_byte()
  }
  bytes
}

///|
/// Convert bytes to string.
fn bytes_to_str(bytes : FixedArray[Byte]) -> String {
  String::from_array(bytes.map(fn(b) { b.to_int().unsafe_to_char() }))
}

///|
/// Parse SurrealDB URL into (scheme, authority, path).
fn surreal_url_parts() -> (@httpTypes.Scheme, String, String) {
  let url = get_env("SURREALDB_URL")
  let scheme = if url.has_prefix("https://") {
    @httpTypes.Scheme::Https
  } else {
    @httpTypes.Scheme::Http
  }
  let rest = if url.has_prefix("https://") {
    url["https://".length():].to_owned()
  } else if url.has_prefix("http://") {
    url["http://".length():].to_owned()
  } else {
    url
  }
  let parts = rest.split("/").to_array()
  let authority = parts[0].to_owned()
  let base_path = if parts.length() > 1 {
    let tail = parts[1:].iter().map(fn(sv) { sv.to_owned() }).to_array()
    "/" + tail.join("/")
  } else {
    ""
  }
  (scheme, authority, base_path + "/sql")
}

///|
/// Execute SurrealDB query via WASI HTTP.
fn surrealdb_query(sql : String) -> Result[Json, String] {
  let (scheme, authority, path) = surreal_url_parts()
  let ns = get_env("SURREALDB_NS")
  let db = get_env("SURREALDB_DB")

  let headers = @httpTypes.Fields::fields()
  let _ = headers.append("Authorization", str_to_bytes("Basic cm9vdDpyb290"))
  let _ = headers.append("surreal-ns", str_to_bytes(ns))
  let _ = headers.append("surreal-db", str_to_bytes(db))
  let _ = headers.append("Content-Type", str_to_bytes("text/plain"))
  let _ = headers.append("Accept", str_to_bytes("application/json"))

  let request = @httpTypes.OutgoingRequest::outgoing_request(headers)
  let _ = request.set_method(@httpTypes.Method::Post)
  let _ = request.set_scheme(Some(scheme))
  let _ = request.set_authority(Some(authority))
  let _ = request.set_path_with_query(Some(path))

  let body = request.body().unwrap()
  let output_stream = body.write().unwrap()
  let body_bytes = str_to_bytes(sql)
  output_stream.blocking_write_and_flush(body_bytes).unwrap()
  output_stream.drop()
  let _ = @httpTypes.OutgoingBody::finish(body, None)

  match @http.handle(request, None) {
    Err(e) => Err("HTTP request failed: " + e.to_string())
    Ok(future) => {
      let pollable = future.subscribe()
      pollable.block()
      match future.get() {
        Some(Ok(Ok(response))) => {
          let status = response.status()
          let incoming_body = response.consume().unwrap()
          let stream = incoming_body.stream().unwrap()
          let bytes = stream.blocking_read(1048576UL).unwrap()
          stream.drop()
          let _ = @httpTypes.IncomingBody::finish(incoming_body)
          let body_str = bytes_to_str(bytes)
          if status >= 200 && status < 300 {
            let json = @json.parse(body_str) catch {
              _ => return Err("Failed to parse JSON response")
            }
            Ok(json)
          } else {
            Err("HTTP " + status.to_string() + ": " + body_str)
          }
        }
        Some(Ok(Err(e))) => Err("HTTP error: " + e.to_string())
        Some(Err(_)) => Err("Response already consumed")
        None => Err("Response not ready")
      }
    }
  }
}

///|
/// Extract the "result" field from SurrealDB response.
pub fn extract_result(response : Json) -> Result[Json, String] {
  match response {
    Json::Array(arr) => {
      if arr.length() == 0 {
        return Err("Empty response array")
      }
      match arr[0] {
        Json::Object(obj) => {
          match obj.get("result") {
            Some(result) => Ok(result)
            None => Err("Missing 'result' field")
          }
        }
        _ => Err("Expected object in response array")
      }
    }
    _ => Err("Expected array response")
  }
}

///|
fn main {

}
