///| rpc_helpers.mbt — thin RPC wrappers for cross-component calls
/// UserAgent is per-user. AdminAgent is the durable singleton (global toggles).

/// Call UserAgent::get_subjects
fn user_get_subjects(user_id : String, role : String) -> String raise @common.AgentError {
  let ctor_data = @rpcTypes.DataValue::Tuple([
    @schema.to_element_value_as(user_id),
    @schema.to_element_value_as(role),
  ])
  let client = @rpc.AgentClient::get("UserAgent", ctor_data)
  defer client.drop()
  let result = client.invoke_and_await(
    "get_subjects",
    @rpcTypes.DataValue::Tuple([]),
  )
  let elements = @extractor.extract_tuple(result)
  @schema.from_element_value_as(elements[0])
}

/// Call UserAgent::get_lessons
fn user_get_lessons(user_id : String, role : String, subject : String) -> String raise @common.AgentError {
  let ctor_data = @rpcTypes.DataValue::Tuple([
    @schema.to_element_value_as(user_id),
    @schema.to_element_value_as(role),
  ])
  let client = @rpc.AgentClient::get("UserAgent", ctor_data)
  defer client.drop()
  let result = client.invoke_and_await(
    "get_lessons",
    @rpcTypes.DataValue::Tuple([@schema.to_element_value_as(subject)]),
  )
  let elements = @extractor.extract_tuple(result)
  @schema.from_element_value_as(elements[0])
}

/// Call UserAgent::get_lesson
fn user_get_lesson(user_id : String, role : String, lesson_id : String) -> String raise @common.AgentError {
  let ctor_data = @rpcTypes.DataValue::Tuple([
    @schema.to_element_value_as(user_id),
    @schema.to_element_value_as(role),
  ])
  let client = @rpc.AgentClient::get("UserAgent", ctor_data)
  defer client.drop()
  let result = client.invoke_and_await(
    "get_lesson",
    @rpcTypes.DataValue::Tuple([@schema.to_element_value_as(lesson_id)]),
  )
  let elements = @extractor.extract_tuple(result)
  @schema.from_element_value_as(elements[0])
}

/// Call AdminAgent::toggle_lesson — global toggle, single source of truth
fn admin_toggle_lesson(lesson_id : String) -> Bool raise @common.AgentError {
  let ctor_data = @rpcTypes.DataValue::Tuple([])
  let client = @rpc.AgentClient::get("AdminAgent", ctor_data)
  defer client.drop()
  let result = client.invoke_and_await(
    "toggle_lesson",
    @rpcTypes.DataValue::Tuple([@schema.to_element_value_as(lesson_id)]),
  )
  let elements = @extractor.extract_tuple(result)
  @schema.from_element_value_as(elements[0])
}

/// Call AdminAgent::is_lesson_active — query global toggle state
fn admin_is_lesson_active(lesson_id : String) -> Bool raise @common.AgentError {
  let ctor_data = @rpcTypes.DataValue::Tuple([])
  let client = @rpc.AgentClient::get("AdminAgent", ctor_data)
  defer client.drop()
  let result = client.invoke_and_await(
    "is_lesson_active",
    @rpcTypes.DataValue::Tuple([@schema.to_element_value_as(lesson_id)]),
  )
  let elements = @extractor.extract_tuple(result)
  @schema.from_element_value_as(elements[0])
}

/// Call AdminAgent::assign_teacher
fn admin_assign_teacher(teacher_id : String, subject : String) -> Bool raise @common.AgentError {
  let ctor_data = @rpcTypes.DataValue::Tuple([])
  let client = @rpc.AgentClient::get("AdminAgent", ctor_data)
  defer client.drop()
  let result = client.invoke_and_await(
    "assign_teacher",
    @rpcTypes.DataValue::Tuple([
      @schema.to_element_value_as(teacher_id),
      @schema.to_element_value_as(subject),
    ]),
  )
  let elements = @extractor.extract_tuple(result)
  @schema.from_element_value_as(elements[0])
}
