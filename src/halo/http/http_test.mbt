// src/halo/http/http_test.mbt
// Blackbox tests for http package

test "server can be created" {
  let server = Server::new(":3000")
  assert_eq(server.get_address(), ":3000")
}

test "server address is stored correctly" {
  let server = Server::new("localhost:8080")
  assert_eq(server.get_address(), "localhost:8080")
}

test "wrap_request creates Request with correct method and path" {
  let headers = Map::new()
  let req = wrap_request("GET", "/test", headers, Some("body"))

  assert_eq(req.http_method, "GET")
  assert_eq(req.path, "/test")
  assert_eq(req.body, Some("body"))
}

test "wrap_request parses headers correctly" {
  let headers = Map::new()
  headers["Content-Type"] = "application/json"
  headers["Authorization"] = "Bearer token"
  let req = wrap_request("POST", "/api", headers, None)

  assert_eq(req.headers["Content-Type"], "application/json")
  assert_eq(req.headers["Authorization"], "Bearer token")
}

test "wrap_request handles empty headers" {
  let headers = Map::new()
  let req = wrap_request("GET", "/", headers, None)

  assert_eq(req.headers.length(), 0)
}

test "wrap_response creates Response with correct status" {
  let headers = Map::new()
  headers["Content-Type"] = "text/html"
  let res = wrap_response(200, headers)

  assert_eq(res.status, 200)
  assert_eq(res.headers["Content-Type"], "text/html")
}

test "wrap_response handles different status codes" {
  let headers = Map::new()
  let res_404 = wrap_response(404, headers)
  let res_500 = wrap_response(500, headers)

  assert_eq(res_404.status, 404)
  assert_eq(res_500.status, 500)
}

test "apply_to_response sets status" {
  let res = @halo.make_response(201, Map::new(), Some("created"))

  let captured_status : Ref[Int] = { val : 0 }
  let set_status_fn = fn(status : Int) { captured_status.val = status }
  let set_header_fn = fn(_key : String, _value : String) { }
  let set_body_fn = fn(_body : String) { }

  apply_to_response(res, set_status_fn, set_header_fn, set_body_fn)

  assert_eq(captured_status.val, 201)
}

test "apply_to_response sets body" {
  let res = @halo.make_response(200, Map::new(), Some("hello world"))

  let captured_body : Ref[Option[String]] = { val : None }
  let set_status_fn = fn(_status : Int) { }
  let set_header_fn = fn(_key : String, _value : String) { }
  let set_body_fn = fn(body : String) { captured_body.val = Some(body) }

  apply_to_response(res, set_status_fn, set_header_fn, set_body_fn)

  assert_eq(captured_body.val, Some("hello world"))
}

test "apply_to_response sets headers" {
  let headers = Map::new()
  headers["X-Custom"] = "value"

  let res = @halo.make_response(200, headers, None)

  let captured_headers : Ref[Array[(String, String)]] = { val : [] }
  let set_status_fn = fn(_status : Int) { }
  let set_header_fn = fn(key : String, value : String) {
    let _ = captured_headers.val.push((key, value))
  }
  let set_body_fn = fn(_body : String) { }

  apply_to_response(res, set_status_fn, set_header_fn, set_body_fn)

  assert_eq(captured_headers.val.length(), 1)
  assert_eq(captured_headers.val[0], ("X-Custom", "value"))
}
