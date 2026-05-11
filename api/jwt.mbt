///| jwt.mbt — input validation helpers

/// Validate that a lesson ID matches the expected format (lesson_content:N)
fn validate_lesson_id(id : String) -> Bool {
  let prefix = "lesson_content:"
  if id.length() <= prefix.length() { return false }
  if id[:prefix.length()] != prefix { return false }
  let suffix = id[prefix.length():]
  let chars = suffix.to_array()
  if chars.length() == 0 { return false }
  for c in chars {
    if !((c >= '0' && c <= '9') || (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z')) { return false }
  }
  true
}

/// Validate subject name — only alphanumeric, space, hyphen, ampersand
fn validate_subject_name(name : String) -> Bool {
  let chars = name.to_array()
  if chars.length() == 0 { return false }
  for c in chars {
    let ok = (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || (c >= '0' && c <= '9') || c == ' ' || c == '-'
    if !ok { return false }
  }
  true
}
