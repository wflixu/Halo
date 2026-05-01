// halo/http/http_test.mbt
// Blackbox tests for halo/http package

///|
test "server can be created" {
  let _server = Server::new(":3000")
}

///|
test "server can be created with full address" {
  let _server = Server::new("localhost:8080")
}

///|
test "Request::new creates Request with correct method and path" {
  let headers = Map::new()
  let req = Request::new("GET", "/test", headers, Some("body"))

  assert_eq(req.http_method, "GET")
  assert_eq(req.path, "/test")
  assert_eq(req.body.unwrap(), "body")
}

///|
test "Request::new parses headers correctly" {
  let headers = Map::new()
  headers["Content-Type"] = "application/json"
  headers["Authorization"] = "Bearer token"
  let req = Request::new("POST", "/api", headers, None)

  assert_eq(req.headers["Content-Type"], "application/json")
  assert_eq(req.headers["Authorization"], "Bearer token")
}

///|
test "Request::new handles empty headers" {
  let headers = Map::new()
  let req = Request::new("GET", "/", headers, None)

  assert_eq(req.headers.length(), 0)
}

///|
test "Response::new creates response with defaults" {
  let res = Response::new()

  assert_eq(res.status.val, 200)
  assert_eq(res.body.val == None, true)
}

///|
test "Response::new_with creates Response with correct values" {
  let headers = Map::new()
  headers["Content-Type"] = "text/html"
  let res = Response::new_with(200, headers, Some("hello"))

  assert_eq(res.status.val, 200)
  assert_eq(res.headers.val["Content-Type"], "text/html")
  assert_eq(res.body.val.unwrap(), "hello")
}

///|
test "Response::new_with handles different status codes" {
  let headers = Map::new()
  let res_404 = Response::new_with(404, headers, None)
  let res_500 = Response::new_with(500, headers, None)

  assert_eq(res_404.status.val, 404)
  assert_eq(res_500.status.val, 500)
}

///|
test "apply_to_response sets status" {
  let res = Response::new_with(201, Map::new(), Some("created"))

  let captured_status : Ref[Int] = { val: 0 }
  let set_status_fn = fn(status : Int) { captured_status.val = status }
  let set_header_fn = fn(_key : String, _value : String) {  }
  let set_body_fn = fn(_body : String) {  }

  apply_to_response(res, set_status_fn, set_header_fn, set_body_fn)

  assert_eq(captured_status.val, 201)
}

///|
test "apply_to_response sets body" {
  let res = Response::new_with(200, Map::new(), Some("hello world"))

  let captured_body : Ref[String?] = { val: None }
  let set_status_fn = fn(_status : Int) {  }
  let set_header_fn = fn(_key : String, _value : String) {  }
  let set_body_fn = fn(body : String) { captured_body.val = Some(body) }

  apply_to_response(res, set_status_fn, set_header_fn, set_body_fn)

  assert_eq(captured_body.val.unwrap(), "hello world")
}

///|
test "apply_to_response sets headers" {
  let headers = Map::new()
  headers["X-Custom"] = "value"

  let res = Response::new_with(200, headers, None)

  let captured_headers : Ref[Array[(String, String)]] = { val: [] }
  let set_status_fn = fn(_status : Int) {  }
  let set_header_fn = fn(key : String, value : String) {
    let _ = captured_headers.val.push((key, value))
  }
  let set_body_fn = fn(_body : String) {  }

  apply_to_response(res, set_status_fn, set_header_fn, set_body_fn)

  assert_eq(captured_headers.val.length(), 1)
  assert_eq(captured_headers.val[0], ("X-Custom", "value"))
}
