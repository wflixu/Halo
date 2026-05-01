// halo/context_test.mbt
// Blackbox tests for context methods and helpers

///|
test "Context::set_body sets response body" {
  let ctx = make_context()
  ctx.set_body("hello")
  assert_eq(ctx.res.val.body.val, Some("hello"))
}

///|
test "Context::set_status sets response status" {
  let ctx = make_context()
  ctx.set_status(404)
  assert_eq(ctx.res.val.status.val, 404)
}

///|
test "Context::set_json sets body and content-type header" {
  let ctx = make_context()
  ctx.set_json("{\"key\": \"value\"}")
  assert_eq(ctx.res.val.body.val, Some("{\"key\": \"value\"}"))
  assert_eq(ctx.res.val.headers.val["Content-Type"], "application/json")
}

///|
test "Context state is mutable" {
  let ctx = make_context()
  ctx.state["key"] = "value"
  assert_eq(ctx.state["key"], "value")
}

///|
test "Context::get_header returns header value" {
  let headers = Map::new()
  headers["Content-Type"] = "application/json"
  headers["Authorization"] = "Bearer token123"
  let req = make_request("GET", "/test", headers, None)
  let ctx = make_context_with_request(req)

  assert_eq(ctx.get_header("Content-Type"), Some("application/json"))
  assert_eq(ctx.get_header("Authorization"), Some("Bearer token123"))
}

///|
test "Context::get_header returns None for missing header" {
  let headers = Map::new()
  let req = make_request("GET", "/test", headers, None)
  let ctx = make_context_with_request(req)

  assert_eq(ctx.get_header("X-Non-Existent"), None)
}

///|
test "Context::get_header_or returns default for missing header" {
  let headers = Map::new()
  let req = make_request("GET", "/test", headers, None)
  let ctx = make_context_with_request(req)

  assert_eq(ctx.get_header_or("X-Custom", "default-value"), "default-value")
}

///|
test "Context::get_header_or returns actual value when exists" {
  let headers = Map::new()
  headers["X-Custom"] = "actual-value"
  let req = make_request("GET", "/test", headers, None)
  let ctx = make_context_with_request(req)

  assert_eq(ctx.get_header_or("X-Custom", "default-value"), "actual-value")
}

///|
test "Context::has_header returns true for existing header" {
  let headers = Map::new()
  headers["X-Exists"] = "yes"
  let req = make_request("GET", "/test", headers, None)
  let ctx = make_context_with_request(req)

  assert_eq(ctx.has_header("X-Exists"), true)
}

///|
test "Context::has_header returns false for missing header" {
  let headers = Map::new()
  let req = make_request("GET", "/test", headers, None)
  let ctx = make_context_with_request(req)

  assert_eq(ctx.has_header("X-Missing"), false)
}
