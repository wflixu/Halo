// halo/middleware/jwt_auth_test.mbt
// Blackbox tests for JWT authentication middleware

///|
test "jwt_auth rejects request without Authorization header" {
  let middleware = @middleware.jwt_auth("secret-key")
  let headers = Map::new()
  let req = @halo.make_request("GET", "/", headers, None)
  let ctx = @halo.make_context_with_request(req)

  middleware(ctx, fn() {
    ctx.set_body("Hello")
  })

  assert_eq(ctx.res.val.status.val, 401)
}

///|
test "jwt_auth rejects invalid token format" {
  let middleware = @middleware.jwt_auth("secret-key")
  let headers = Map::new()
  headers["Authorization"] = "Bearer invalid-token"
  let req = @halo.make_request("GET", "/", headers, None)
  let ctx = @halo.make_context_with_request(req)

  middleware(ctx, fn() {
    ctx.set_body("Hello")
  })

  // Invalid format (not 3 parts) should be rejected
  assert_eq(ctx.res.val.status.val, 401)
}

///|
test "jwt_auth accepts valid JWT structure" {
  let middleware = @middleware.jwt_auth("secret-key")
  let headers = Map::new()
  // Valid JWT format: header.payload.signature (base64 encoded)
  headers["Authorization"] = "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c"
  let req = @halo.make_request("GET", "/", headers, None)
  let ctx = @halo.make_context_with_request(req)

  middleware(ctx, fn() {
    ctx.set_body("Hello")
  })

  assert_eq(ctx.res.val.status.val, 200)
  // JWT payload should be stored in context
  let payload = @middleware.get_jwt_payload(ctx)
  assert_eq(payload != None, true)
}

///|
test "jwt_auth stores token in context" {
  let middleware = @middleware.jwt_auth("secret-key")
  let headers = Map::new()
  let token = "eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxMjM0NTY3ODkwIn0.signature"
  headers["Authorization"] = "Bearer " + token
  let req = @halo.make_request("GET", "/", headers, None)
  let ctx = @halo.make_context_with_request(req)

  middleware(ctx, fn() {
    ctx.set_body("Hello")
  })

  let stored_token = @middleware.get_jwt_token(ctx)
  match stored_token {
    Some(t) => assert_eq(String::has_prefix(t, "eyJ"), true)
    None => assert_eq(false, true)
  }
}

///|
test "jwt_auth excludes specified paths" {
  let middleware = @middleware.jwt_auth_with_options(
    @middleware.make_jwt_auth_options(
      "secret",
      ["/health", "/public"],
      "Unauthorized",
      "Authorization",
      "Bearer ",
      "HS256"
    )
  )
  let headers = Map::new()
  let req = @halo.make_request("GET", "/health", headers, None)
  let ctx = @halo.make_context_with_request(req)

  middleware(ctx, fn() {
    ctx.set_body("Healthy")
  })

  // Excluded paths should not require auth
  assert_eq(ctx.res.val.status.val, 200)
}

///|
test "jwt_auth does not exclude non-excluded paths" {
  let middleware = @middleware.jwt_auth_with_options(
    @middleware.make_jwt_auth_options(
      "secret",
      ["/health"],
      "Unauthorized",
      "Authorization",
      "Bearer ",
      "HS256"
    )
  )
  let headers = Map::new()
  let req = @halo.make_request("GET", "/api/data", headers, None)
  let ctx = @halo.make_context_with_request(req)

  middleware(ctx, fn() {
    ctx.set_body("Data")
  })

  // Non-excluded path without auth should be rejected
  assert_eq(ctx.res.val.status.val, 401)
}

///|
test "jwt_auth_with_options accepts valid token" {
  let middleware = @middleware.jwt_auth_with_options(
    @middleware.make_jwt_auth_options(
      "my-secret",
      [],
      "Invalid token",
      "Authorization",
      "Bearer ",
      "HS256"
    )
  )
  let headers = Map::new()
  headers["Authorization"] = "Bearer eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxMjM0NTY3ODkwIn0.signature"
  let req = @halo.make_request("GET", "/api", headers, None)
  let ctx = @halo.make_context_with_request(req)

  middleware(ctx, fn() {
    ctx.set_body("Success")
  })

  assert_eq(ctx.res.val.status.val, 200)
}

///|
test "jwt_auth rejects empty secret" {
  let middleware = @middleware.jwt_auth("")
  let headers = Map::new()
  headers["Authorization"] = "Bearer header.payload.signature"
  let req = @halo.make_request("GET", "/", headers, None)
  let ctx = @halo.make_context_with_request(req)

  middleware(ctx, fn() {
    ctx.set_body("Hello")
  })

  // Empty secret should reject
  assert_eq(ctx.res.val.status.val, 401)
}

///|
test "jwt_auth handles custom header name" {
  let middleware = @middleware.jwt_auth_with_options(
    @middleware.make_jwt_auth_options(
      "secret",
      [],
      "Unauthorized",
      "X-Auth-Token",
      "Bearer ",
      "HS256"
    )
  )
  let headers = Map::new()
  headers["X-Auth-Token"] = "Bearer token.payload.signature"
  let req = @halo.make_request("GET", "/", headers, None)
  let ctx = @halo.make_context_with_request(req)

  middleware(ctx, fn() {
    ctx.set_body("Hello")
  })

  assert_eq(ctx.res.val.status.val, 200)
}

///|
test "jwt_auth stores jwt_payload in context state" {
  let middleware = @middleware.jwt_auth("secret")
  let headers = Map::new()
  headers["Authorization"] = "Bearer header.payload.signature"
  let req = @halo.make_request("GET", "/", headers, None)
  let ctx = @halo.make_context_with_request(req)

  middleware(ctx, fn() {
    ctx.set_body("Hello")
  })

  let payload = ctx.state.get("jwt_payload")
  assert_eq(payload != None, true)
  match payload {
    Some(p) => assert_eq(String::has_prefix(p, "payload"), true)
    None => assert_eq(false, true)
  }
}

///|
test "get_jwt_claim returns claim info" {
  let middleware = @middleware.jwt_auth("secret")
  let headers = Map::new()
  headers["Authorization"] = "Bearer header.payload.signature"
  let req = @halo.make_request("GET", "/", headers, None)
  let ctx = @halo.make_context_with_request(req)

  middleware(ctx, fn() {
    ctx.set_body("Hello")
  })

  let claim = @middleware.get_jwt_claim(ctx, "sub")
  assert_eq(claim != None, true)
}
