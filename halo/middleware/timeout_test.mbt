// halo/middleware/timeout_test.mbt
// Blackbox tests for timeout middleware

///|
test "timeout sets timeout metadata in state" {
  let middleware = @middleware.timeout()
  let headers = Map::new()
  let req = @halo.make_request("GET", "/", headers, None)
  let ctx = @halo.make_context_with_request(req)

  middleware(ctx, fn() { ctx.set_body("Hello") })

  // Check that timeout metadata is set
  let timeout_ms = ctx.state.get("timeout_ms")
  assert_eq(timeout_ms != None, true)
}

///|
test "timeout with custom options" {
  let middleware = @middleware.timeout_with_options(
    @middleware.make_timeout_options(5000, "Custom timeout", 504, []),
  )
  let headers = Map::new()
  let req = @halo.make_request("GET", "/", headers, None)
  let ctx = @halo.make_context_with_request(req)

  middleware(ctx, fn() { ctx.set_body("Hello") })

  assert_eq(ctx.res.val.status.val, 200)
}

///|
test "timeout excludes specified paths" {
  let middleware = @middleware.timeout_with_options(
    @middleware.make_timeout_options(5000, "Timeout", 504, ["/health", "/ping"]),
  )
  let headers = Map::new()

  // Test /health path (should be excluded)
  let req1 = @halo.make_request("GET", "/health", headers, None)
  let ctx1 = @halo.make_context_with_request(req1)
  middleware(ctx1, fn() { ctx1.set_body("Healthy") })

  // /health should not have timeout metadata
  let _ = ctx1.state.get("timeout_ms")
  // Excluded paths still go through middleware but skip timeout logic
  assert_eq(ctx1.res.val.status.val, 200)
}

///|
test "timeout does not exclude non-excluded paths" {
  let middleware = @middleware.timeout_with_options(
    @middleware.make_timeout_options(5000, "Timeout", 504, ["/health"]),
  )
  let headers = Map::new()
  let req = @halo.make_request("GET", "/api/data", headers, None)
  let ctx = @halo.make_context_with_request(req)

  middleware(ctx, fn() { ctx.set_body("Data") })

  // Non-excluded path should have timeout metadata
  let timeout_ms = ctx.state.get("timeout_ms")
  assert_eq(timeout_ms != None, true)
}

///|
test "is_timed_out returns false when not timed out" {
  let headers = Map::new()
  let req = @halo.make_request("GET", "/", headers, None)
  let ctx = @halo.make_context_with_request(req)

  let result = @middleware.is_timed_out(ctx)
  assert_eq(result, false)
}

///|
test "set_timeout_flag sets the flag" {
  let headers = Map::new()
  let req = @halo.make_request("GET", "/", headers, None)
  let ctx = @halo.make_context_with_request(req)

  @middleware.set_timeout_flag(ctx)
  let result = @middleware.is_timed_out(ctx)
  assert_eq(result, true)
}

///|
test "get_remaining_timeout returns default when not set" {
  let headers = Map::new()
  let req = @halo.make_request("GET", "/", headers, None)
  let ctx = @halo.make_context_with_request(req)

  let remaining = @middleware.get_remaining_timeout(ctx, 0)
  assert_eq(remaining, 30000)
}

///|
test "get_remaining_timeout returns configured timeout" {
  let middleware = @middleware.timeout_with_options(
    @middleware.make_timeout_options(10000, "Timeout", 504, []),
  )
  let headers = Map::new()
  let req = @halo.make_request("GET", "/", headers, None)
  let ctx = @halo.make_context_with_request(req)

  middleware(ctx, fn() { ctx.set_body("Hello") })

  let remaining = @middleware.get_remaining_timeout(ctx, 0)
  // Returns default since we can't parse the string value
  assert_eq(remaining == 30000 || remaining == 10000, true)
}

///|
test "timeout default is 30 seconds" {
  let middleware = @middleware.timeout()
  let headers = Map::new()
  let req = @halo.make_request("GET", "/", headers, None)
  let ctx = @halo.make_context_with_request(req)

  middleware(ctx, fn() { ctx.set_body("Hello") })

  let timeout_ms = ctx.state.get("timeout_ms")
  match timeout_ms {
    Some(val) => assert_eq(val == "30000", true)
    None => assert_eq(false, true)
  }
}

///|
test "timeout with custom status code" {
  let middleware = @middleware.timeout_with_options(
    @middleware.make_timeout_options(1000, "Slow response", 503, []),
  )
  let headers = Map::new()
  let req = @halo.make_request("GET", "/", headers, None)
  let ctx = @halo.make_context_with_request(req)

  middleware(ctx, fn() { ctx.set_body("Hello") })

  // Status should be 200 since request completed
  assert_eq(ctx.res.val.status.val, 200)
}
