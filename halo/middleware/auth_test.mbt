// halo/middleware/auth_test.mbt
// Blackbox tests for auth middleware

///|
test "bearer_auth accepts valid token" {
  let middleware = @middleware.bearer_auth(fn(token) { token == "valid-token" })
  let headers = Map::new()
  headers["Authorization"] = "Bearer valid-token"
  let req = @halo.make_request("GET", "/protected", headers, None)
  let ctx = @halo.make_context_with_request(req)
  let called : Ref[Bool] = { val: false }

  middleware(ctx, fn() { called.val = true })

  assert_eq(called.val, true)
  assert_eq(ctx.res.val.status.val, 200)
}

///|
test "bearer_auth rejects invalid token" {
  let middleware = @middleware.bearer_auth(fn(token) { token == "valid-token" })
  let headers = Map::new()
  headers["Authorization"] = "Bearer invalid-token"
  let req = @halo.make_request("GET", "/protected", headers, None)
  let ctx = @halo.make_context_with_request(req)
  let called : Ref[Bool] = { val: false }

  middleware(ctx, fn() { called.val = true })

  assert_eq(called.val, false)
  assert_eq(ctx.res.val.status.val, 401)
}

///|
test "bearer_auth rejects missing token" {
  let middleware = @middleware.bearer_auth(fn(_token) { true })
  let headers = Map::new()
  let req = @halo.make_request("GET", "/protected", headers, None)
  let ctx = @halo.make_context_with_request(req)
  let called : Ref[Bool] = { val: false }

  middleware(ctx, fn() { called.val = true })

  assert_eq(called.val, false)
  assert_eq(ctx.res.val.status.val, 401)
}

///|
test "bearer_auth rejects non-Bearer scheme" {
  let middleware = @middleware.bearer_auth(fn(_token) { true })
  let headers = Map::new()
  headers["Authorization"] = "Basic abc123"
  let req = @halo.make_request("GET", "/protected", headers, None)
  let ctx = @halo.make_context_with_request(req)
  let called : Ref[Bool] = { val: false }

  middleware(ctx, fn() { called.val = true })

  assert_eq(called.val, false)
  assert_eq(ctx.res.val.status.val, 401)
}

///|
test "bearer_auth_with_options excludes paths" {
  let middleware = @middleware.bearer_auth_with_options(
    @middleware.make_auth_options(
      fn(_token) { false },
      ["/public", "/health"],
      "Unauthorized",
    )
  )
  let headers = Map::new()
  let req = @halo.make_request("GET", "/public/info", headers, None)
  let ctx = @halo.make_context_with_request(req)
  let called : Ref[Bool] = { val: false }

  middleware(ctx, fn() { called.val = true })

  assert_eq(called.val, true)
  assert_eq(ctx.res.val.status.val, 200)
}

///|
test "bearer_auth_with_options protects non-excluded paths" {
  let middleware = @middleware.bearer_auth_with_options(
    @middleware.make_auth_options(
      fn(_token) { false },
      ["/public"],
      "Unauthorized",
    )
  )
  let headers = Map::new()
  let req = @halo.make_request("GET", "/protected", headers, None)
  let ctx = @halo.make_context_with_request(req)
  let called : Ref[Bool] = { val: false }

  middleware(ctx, fn() { called.val = true })

  assert_eq(called.val, false)
  assert_eq(ctx.res.val.status.val, 401)
}

///|
test "bearer_auth_with_options uses custom error message" {
  let middleware = @middleware.bearer_auth_with_options(
    @middleware.make_auth_options(
      fn(_token) { false },
      [],
      "Custom error",
    )
  )
  let headers = Map::new()
  let req = @halo.make_request("GET", "/protected", headers, None)
  let ctx = @halo.make_context_with_request(req)
  let called : Ref[Bool] = { val: false }

  middleware(ctx, fn() { called.val = true })

  assert_eq(called.val, false)
  assert_eq(ctx.res.val.status.val, 401)
  // Check response body contains custom error message
  let body = ctx.res.val.body.val
  match body {
    Some(b) => assert_eq(String::contains(b, "Custom error"), true)
    None => assert_eq(false, true)
  }
}

///|
test "get_bearer_token extracts token correctly" {
  let headers = Map::new()
  headers["Authorization"] = "Bearer my-secret-token"
  let req = @halo.make_request("GET", "/", headers, None)
  let ctx = @halo.make_context_with_request(req)

  assert_eq(@middleware.get_bearer_token(ctx), Some("my-secret-token"))
}

///|
test "get_bearer_token returns None for missing header" {
  let headers = Map::new()
  let req = @halo.make_request("GET", "/", headers, None)
  let ctx = @halo.make_context_with_request(req)

  assert_eq(@middleware.get_bearer_token(ctx), None)
}

///|
test "get_bearer_token returns None for non-Bearer scheme" {
  let headers = Map::new()
  headers["Authorization"] = "Basic abc123"
  let req = @halo.make_request("GET", "/", headers, None)
  let ctx = @halo.make_context_with_request(req)

  assert_eq(@middleware.get_bearer_token(ctx), None)
}

///|
test "get_bearer_token returns None for empty token" {
  let headers = Map::new()
  headers["Authorization"] = "Bearer "
  let req = @halo.make_request("GET", "/", headers, None)
  let ctx = @halo.make_context_with_request(req)

  assert_eq(@middleware.get_bearer_token(ctx), None)
}
