///|
/// Admin agent — durable singleton, global source of truth for toggles
#derive.agent
struct AdminAgent {
  subject_teacher : Map[String, String]
  lesson_toggle_state : Map[String, Bool]
}

///|
fn AdminAgent::new() -> AdminAgent {
  { subject_teacher: {}, lesson_toggle_state: {} }
}

///|
pub fn AdminAgent::spawn_user(
  self : Self,
  user_id : String,
  role : String,
  name : String
) -> Bool {
  let _ = self
  let _ = user_id
  let _ = role
  let _ = name
  true
}

///|
pub fn AdminAgent::assign_teacher(
  self : Self,
  teacher_id : String,
  subject : String
) -> Bool {
  self.subject_teacher[subject] = teacher_id
  true
}

///|
pub fn AdminAgent::get_teacher_for_subject(self : Self, subject : String) -> String {
  self.subject_teacher.get(subject).unwrap_or("")
}

///|
/// Toggle lesson active state globally. Returns new active value.
pub fn AdminAgent::toggle_lesson(self : Self, lesson_id : String) -> Bool {
  let current = self.lesson_toggle_state.get(lesson_id).unwrap_or(true)
  let next = !current
  self.lesson_toggle_state[lesson_id] = next
  next
}

///|
/// Get global active state for a lesson (defaults to true).
pub fn AdminAgent::is_lesson_active(self : Self, lesson_id : String) -> Bool {
  self.lesson_toggle_state.get(lesson_id).unwrap_or(true)
}

///|
fn main {

}
