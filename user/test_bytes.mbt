test "str_to_bytes test" {
  let bytes = str_to_bytes("Basic cm9vdDpyb290")
  assert_eq(bytes.length(), 19)
  assert_eq(bytes[0], b'B')
  assert_eq(bytes[6], b'c')
}
