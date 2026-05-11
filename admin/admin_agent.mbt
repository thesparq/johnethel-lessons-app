///|
/// Admin agent — durable singleton for teacher-subject assignments.
#derive.agent
struct AdminAgent {
  subject_teacher : Map[String, String]
}

///|
fn AdminAgent::new() -> AdminAgent {
  { subject_teacher: {} }
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
fn main {

}
