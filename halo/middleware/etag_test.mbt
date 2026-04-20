// halo/middleware/etag_test.mbt
// Blackbox tests for etag middleware

///|
test "etag sets ETag header on response" {
  let middleware = @middleware.etag()
  let headers = Map::new()
  let req = @halo.make_request("GET", "/", headers, None)
  let ctx = @halo.make_context_with_request(req)

  middleware(ctx, fn() { ctx.set_body("Hello, World!") })

  let etag = ctx.res.val.headers.val.get("ETag")
  assert_eq(etag != None, true)
}

///|
test "etag generates different ETags for different content" {
  let middleware = @middleware.etag()
  let headers = Map::new()

  // First request
  let req1 = @halo.make_request("GET", "/a", headers, None)
  let ctx1 = @halo.make_context_with_request(req1)
  middleware(ctx1, fn() { ctx1.set_body("Content A") })

  // Second request
  let req2 = @halo.make_request("GET", "/b", headers, None)
  let ctx2 = @halo.make_context_with_request(req2)
  middleware(ctx2, fn() { ctx2.set_body("Content B") })

  let etag1 = ctx1.res.val.headers.val.get("ETag")
  let etag2 = ctx2.res.val.headers.val.get("ETag")

  assert_eq(etag1 != etag2, true)
}

///|
test "etag returns 304 when If-None-Match matches" {
  let middleware = @middleware.etag()
  let headers = Map::new()
  headers["If-None-Match"] = "\"test-etag\""

  let req = @halo.make_request("GET", "/", headers, None)
  let ctx = @halo.make_context_with_request(req)

  // Simulate a handler that sets a matching ETag
  middleware(ctx, fn() {
    ctx.set_body("Hello")
    ctx.res.val.headers.val["ETag"] = "\"test-etag\""
  })

  assert_eq(ctx.res.val.status.val, 304)
}

///|
test "etag returns 200 when If-None-Match does not match" {
  let middleware = @middleware.etag()
  let headers = Map::new()
  headers["If-None-Match"] = "\"different-etag\""

  let req = @halo.make_request("GET", "/", headers, None)
  let ctx = @halo.make_context_with_request(req)

  middleware(ctx, fn() {
    ctx.set_body("Hello")
    ctx.res.val.headers.val["ETag"] = "\"test-etag\""
  })

  assert_eq(ctx.res.val.status.val, 200)
}

///|
test "etag skips ETag for empty body" {
  let middleware = @middleware.etag()
  let headers = Map::new()
  let req = @halo.make_request("GET", "/", headers, None)
  let ctx = @halo.make_context_with_request(req)

  middleware(ctx, fn() { ctx.set_body("") })

  let etag = ctx.res.val.headers.val.get("ETag")
  // Empty body should not get an ETag (min_size is 1 by default, empty string has length 0)
  assert_eq(etag, None)
}

///|
test "etag respects min_size option" {
  let middleware = @middleware.etag_with_options(
    @middleware.make_etag_options(false, 100, "md5"),
  )
  let headers = Map::new()
  let req = @halo.make_request("GET", "/", headers, None)
  let ctx = @halo.make_context_with_request(req)

  middleware(ctx, fn() { ctx.set_body("small") })

  let etag = ctx.res.val.headers.val.get("ETag")
  // Body is smaller than min_size, no ETag should be set
  assert_eq(etag, None)
}

///|
test "etag generates weak ETag when weak=true" {
  let middleware = @middleware.etag_with_options(
    @middleware.make_etag_options(true, 1, "md5"),
  )
  let headers = Map::new()
  let req = @halo.make_request("GET", "/", headers, None)
  let ctx = @halo.make_context_with_request(req)

  middleware(ctx, fn() { ctx.set_body("test content") })

  let etag = ctx.res.val.headers.val.get("ETag")
  match etag {
    Some(e) => assert_eq(String::has_prefix(e, "W/"), true)
    None => assert_eq(false, true)
  }
}

///|
test "etag weak comparison matches W/ prefix" {
  // Test that W/"abc" matches "abc"
  let result = @middleware.etags_match("W/\"abc123\"", "\"abc123\"")
  assert_eq(result, true)
}

///|
test "generate_etag_for_content generates correct format" {
  let etag = @middleware.generate_etag_for_content("test", false)
  // Should be quoted
  assert_eq(String::has_prefix(etag, "\""), true)
  assert_eq(String::has_suffix(etag, "\""), true)
}

///|
test "generate_etag_for_content with weak=true" {
  let etag = @middleware.generate_etag_for_content("test", true)
  // Should start with W/
  assert_eq(String::has_prefix(etag, "W/"), true)
}

///|
test "is_not_modified returns true when ETags match" {
  let headers = Map::new()
  headers["If-None-Match"] = "\"abc123\""
  let req = @halo.make_request("GET", "/", headers, None)
  let ctx = @halo.make_context_with_request(req)

  let result = @middleware.is_not_modified(ctx, "\"abc123\"")
  assert_eq(result, true)
}

///|
test "is_not_modified returns false when ETags differ" {
  let headers = Map::new()
  headers["If-None-Match"] = "\"abc123\""
  let req = @halo.make_request("GET", "/", headers, None)
  let ctx = @halo.make_context_with_request(req)

  let result = @middleware.is_not_modified(ctx, "\"def456\"")
  assert_eq(result, false)
}

///|
test "is_not_modified returns false when no If-None-Match" {
  let headers = Map::new()
  let req = @halo.make_request("GET", "/", headers, None)
  let ctx = @halo.make_context_with_request(req)

  let result = @middleware.is_not_modified(ctx, "\"abc123\"")
  assert_eq(result, false)
}

///|
test "set_cache_headers sets Cache-Control header" {
  let headers = Map::new()
  let req = @halo.make_request("GET", "/", headers, None)
  let ctx = @halo.make_context_with_request(req)

  @middleware.set_cache_headers(ctx, 3600, true)

  let cache_control = ctx.res.val.headers.val.get("Cache-Control")
  assert_eq(cache_control != None, true)
  match cache_control {
    Some(cc) => assert_eq(String::contains(cc, "max-age=3600"), true)
    None => assert_eq(false, true)
  }
}

///|
test "set_cache_headers public vs private" {
  let headers = Map::new()
  let req = @halo.make_request("GET", "/", headers, None)
  let ctx = @halo.make_context_with_request(req)

  @middleware.set_cache_headers(ctx, 3600, false)

  let cache_control = ctx.res.val.headers.val.get("Cache-Control")
  match cache_control {
    Some(cc) => assert_eq(String::has_prefix(cc, "private"), true)
    None => assert_eq(false, true)
  }
}
