///|
/// QueryFork — ephemeral SurrealDB worker.
/// Makes blocking HTTP requests to SurrealDB, returns JSON string, then dies.
/// Isolates blocking I/O from durable UserAgent.
#derive.agent("ephemeral")
struct QueryFork {
  sql : String
}

///|
fn QueryFork::new(sql : String) -> QueryFork {
  { sql, }
}

///|
/// Execute the SQL query against SurrealDB and return the JSON result string.
pub fn QueryFork::execute(self : Self) -> String {
  match surrealdb_query(self.sql) {
    Ok(json) => json.stringify()
    Err(e) => "{\"error\":\"" + e + "\"}"
  }
}
