// halo/middleware/rate_limit_test.mbt
// Blackbox tests for rate limit middleware

///|
test "rate_limit_ip_based allows requests within limit" {
  @middleware.reset_rate_limit_store()
  @middleware.set_current_timestamp(1000)

  let middleware = @middleware.rate_limit_ip_based(5, 60)
  let headers = Map::new()
  headers["X-Forwarded-For"] = "192.168.1.1"

  // First 5 requests should succeed
  for _i in 1..=5 {
    let req = @halo.make_request("GET", "/", headers, None)
    let ctx = @halo.make_context_with_request(req)
    let called : Ref[Bool] = { val: false }

    middleware(ctx, fn() { called.val = true })

    assert_eq(called.val, true)
  }
}

///|
test "rate_limit_ip_based blocks requests over limit" {
  @middleware.reset_rate_limit_store()
  @middleware.set_current_timestamp(2000)

  let middleware = @middleware.rate_limit_ip_based(3, 60)
  let headers = Map::new()
  headers["X-Forwarded-For"] = "192.168.1.2"

  // First 3 requests should succeed
  for _i in 1..=3 {
    let req = @halo.make_request("GET", "/", headers, None)
    let ctx = @halo.make_context_with_request(req)
    let called : Ref[Bool] = { val: false }

    middleware(ctx, fn() { called.val = true })
  }

  // 4th request should be blocked
  let req = @halo.make_request("GET", "/", headers, None)
  let ctx = @halo.make_context_with_request(req)
  let called : Ref[Bool] = { val: false }

  middleware(ctx, fn() { called.val = true })

  assert_eq(called.val, false)
  assert_eq(ctx.res.val.status.val, 429)
}

///|
test "rate_limit resets after window expires" {
  @middleware.reset_rate_limit_store()
  @middleware.set_current_timestamp(3000)

  let middleware = @middleware.rate_limit_ip_based(2, 60)
  let headers = Map::new()
  headers["X-Forwarded-For"] = "192.168.1.3"

  // Use up the limit
  for _i in 1..=2 {
    let req = @halo.make_request("GET", "/", headers, None)
    let ctx = @halo.make_context_with_request(req)
    let called : Ref[Bool] = { val: false }
    middleware(ctx, fn() { called.val = true })
  }

  // Verify limit reached
  let req = @halo.make_request("GET", "/", headers, None)
  let ctx = @halo.make_context_with_request(req)
  let called : Ref[Bool] = { val: false }
  middleware(ctx, fn() { called.val = true })
  assert_eq(called.val, false)

  // Advance time past window
  @middleware.advance_timestamp(61)

  // Should be allowed again
  let req2 = @halo.make_request("GET", "/", headers, None)
  let ctx2 = @halo.make_context_with_request(req2)
  let called2 : Ref[Bool] = { val: false }
  middleware(ctx2, fn() { called2.val = true })

  assert_eq(called2.val, true)
}

///|
test "rate_limit_user_based uses user_id from state" {
  @middleware.reset_rate_limit_store()
  @middleware.set_current_timestamp(4000)

  let middleware = @middleware.rate_limit_user_based(2, 60)
  let headers = Map::new()
  let req = @halo.make_request("GET", "/", headers, None)
  let ctx = @halo.make_context_with_request(req)

  // Set user_id in state
  ctx.state["user_id"] = "user123"

  let called : Ref[Bool] = { val: false }
  middleware(ctx, fn() { called.val = true })

  assert_eq(called.val, true)
}

///|
test "rate_limit_user_based treats anonymous users" {
  @middleware.reset_rate_limit_store()
  @middleware.set_current_timestamp(5000)

  let middleware = @middleware.rate_limit_user_based(2, 60)
  let headers = Map::new()
  let req = @halo.make_request("GET", "/", headers, None)
  let ctx = @halo.make_context_with_request(req)

  // No user_id in state - should be treated as anonymous
  let called : Ref[Bool] = { val: false }
  middleware(ctx, fn() { called.val = true })

  assert_eq(called.val, true)
}

///|
test "different IPs have separate limits" {
  @middleware.reset_rate_limit_store()
  @middleware.set_current_timestamp(6000)

  let middleware = @middleware.rate_limit_ip_based(2, 60)

  let headers1 = Map::new()
  headers1["X-Forwarded-For"] = "10.0.0.1"

  let headers2 = Map::new()
  headers2["X-Forwarded-For"] = "10.0.0.2"

  // IP1 uses its limit
  for _i in 1..=2 {
    let req = @halo.make_request("GET", "/", headers1, None)
    let ctx = @halo.make_context_with_request(req)
    let called : Ref[Bool] = { val: false }
    middleware(ctx, fn() { called.val = true })
  }

  // IP1 is blocked
  let req1 = @halo.make_request("GET", "/", headers1, None)
  let ctx1 = @halo.make_context_with_request(req1)
  let called1 : Ref[Bool] = { val: false }
  middleware(ctx1, fn() { called1.val = true })
  assert_eq(called1.val, false)

  // IP2 should still work
  let req2 = @halo.make_request("GET", "/", headers2, None)
  let ctx2 = @halo.make_context_with_request(req2)
  let called2 : Ref[Bool] = { val: false }
  middleware(ctx2, fn() { called2.val = true })
  assert_eq(called2.val, true)
}

///|
test "get_remaining_requests returns correct count" {
  @middleware.reset_rate_limit_store()
  @middleware.set_current_timestamp(7000)

  let options = @middleware.make_rate_limit_options(5, 60, @middleware.ip_based_strategy(), "X-API-Key", "Too many requests", 429)
  let identifier = "test-ip"

  // Initially should have max requests
  assert_eq(@middleware.get_remaining_requests(identifier, options), 5)

  // Make one request
  let headers = Map::new()
  headers["X-Forwarded-For"] = identifier
  let middleware = @middleware.rate_limit_with_options(options)
  let req = @halo.make_request("GET", "/", headers, None)
  let ctx = @halo.make_context_with_request(req)
  middleware(ctx, fn() { })

  // Should have 4 remaining
  assert_eq(@middleware.get_remaining_requests(identifier, options), 4)
}

///|
test "rate limit returns 429 with retry_after" {
  @middleware.reset_rate_limit_store()
  @middleware.set_current_timestamp(8000)

  let middleware = @middleware.rate_limit_ip_based(1, 60)
  let headers = Map::new()
  headers["X-Forwarded-For"] = "192.168.2.1"

  // First request succeeds
  let req1 = @halo.make_request("GET", "/", headers, None)
  let ctx1 = @halo.make_context_with_request(req1)
  middleware(ctx1, fn() { })

  // Second request fails with 429
  let req2 = @halo.make_request("GET", "/", headers, None)
  let ctx2 = @halo.make_context_with_request(req2)
  middleware(ctx2, fn() { })

  assert_eq(ctx2.res.val.status.val, 429)
  // Check response contains retry_after
  let body = ctx2.res.val.body.val
  match body {
    Some(b) => assert_eq(String::contains(b, "retry_after"), true)
    None => assert_eq(false, true)
  }
}
