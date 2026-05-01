// halo/middleware/compression_test.mbt
// Blackbox tests for compression middleware

///|
test "compression sets Vary header" {
  let middleware = @middleware.compression()
  let headers = Map::new()
  headers["Accept-Encoding"] = "gzip"
  let req = @halo.make_request("GET", "/", headers, None)
  let ctx = @halo.make_context_with_request(req)

  middleware(ctx, fn() { ctx.set_body("test content") })

  let vary = ctx.res.val.headers.val.get("Vary")
  assert_eq(vary != None, true)
}

///|
test "compression detects gzip support" {
  let middleware = @middleware.compression()
  let headers = Map::new()
  headers["Accept-Encoding"] = "gzip, deflate, br"
  let req = @halo.make_request("GET", "/", headers, None)
  let ctx = @halo.make_context_with_request(req)

  middleware(ctx, fn() {
    // Set a body larger than min_size
    let large_body : Ref[String] = { val: "" }
    for _i in 1..<=200 {
      large_body.val = large_body.val +
        "This is some content that will be compressed. "
    }
    ctx.set_body(large_body.val)
  })

  // Vary header should be set
  let vary = ctx.res.val.headers.val.get("Vary")
  assert_eq(vary != None, true)
}

///|
test "compression skips if no Accept-Encoding header" {
  let middleware = @middleware.compression()
  let headers = Map::new()
  let req = @halo.make_request("GET", "/", headers, None)
  let ctx = @halo.make_context_with_request(req)

  middleware(ctx, fn() { ctx.set_body("test content") })

  // Content-Encoding should not be set
  let encoding = ctx.res.val.headers.val.get("Content-Encoding")
  assert_eq(encoding == None, true)
}

///|
test "compression skips small responses" {
  let middleware = @middleware.compression_with_options(
    @middleware.make_compression_options(true, false, false, 1024, 6, [
      "text/html",
    ]),
  )
  let headers = Map::new()
  headers["Accept-Encoding"] = "gzip"
  let req = @halo.make_request("GET", "/", headers, None)
  let ctx = @halo.make_context_with_request(req)

  middleware(ctx, fn() {
    // Small body - should not be compressed
    ctx.set_body("small")
  })

  // Content-Encoding should not be set for small responses
  let encoding = ctx.res.val.headers.val.get("Content-Encoding")
  assert_eq(encoding == None, true)
}

///|
test "compression respects content-type" {
  let middleware = @middleware.compression_with_options(
    @middleware.make_compression_options(true, false, false, 100, 6, [
      "application/json",
    ]),
  )
  let headers = Map::new()
  headers["Accept-Encoding"] = "gzip"
  let req = @halo.make_request("GET", "/", headers, None)
  let ctx = @halo.make_context_with_request(req)

  middleware(ctx, fn() {
    let large_body : Ref[String] = { val: "" }
    for _i in 1..<=10 {
      large_body.val = large_body.val + "This is JSON content. "
    }
    ctx.set_json(large_body.val)
  })

  // JSON should be in the compressible types
  let vary = ctx.res.val.headers.val.get("Vary")
  assert_eq(vary != None, true)
}

///|
test "get_compression_stats returns initial values" {
  @middleware.reset_compression_stats()
  let stats = @middleware.get_compression_stats()
  assert_eq(stats.total_requests.val, 0)
  assert_eq(stats.compressed_count.val, 0)
}

///|
test "get_compression_ratio returns zero when no data" {
  @middleware.reset_compression_stats()
  let ratio = @middleware.get_compression_ratio()
  assert_eq(ratio, 0.0)
}

///|
test "compression_with_options enables gzip only" {
  let middleware = @middleware.compression_with_options(
    @middleware.make_compression_options(true, false, false, 512, 9, [
      "text/plain",
    ]),
  )
  let headers = Map::new()
  headers["Accept-Encoding"] = "gzip"
  let req = @halo.make_request("GET", "/", headers, None)
  let ctx = @halo.make_context_with_request(req)

  middleware(ctx, fn() { ctx.set_body("test") })

  // Should process without error
  assert_eq(ctx.res.val.status.val, 200)
}

///|
test "compression handles br (brotli) encoding" {
  let middleware = @middleware.compression_with_options(
    @middleware.make_compression_options(false, true, false, 512, 9, [
      "text/plain",
    ]),
  )
  let headers = Map::new()
  headers["Accept-Encoding"] = "br"
  let req = @halo.make_request("GET", "/", headers, None)
  let ctx = @halo.make_context_with_request(req)

  middleware(ctx, fn() { ctx.set_body("test content for brotli") })

  // Should set Vary header
  let vary = ctx.res.val.headers.val.get("Vary")
  assert_eq(vary != None, true)
}

///|
test "compression handles deflate encoding" {
  let middleware = @middleware.compression_with_options(
    @middleware.make_compression_options(false, false, true, 512, 9, [
      "text/plain",
    ]),
  )
  let headers = Map::new()
  headers["Accept-Encoding"] = "deflate"
  let req = @halo.make_request("GET", "/", headers, None)
  let ctx = @halo.make_context_with_request(req)

  middleware(ctx, fn() { ctx.set_body("test content for deflate") })

  // Should set Vary header
  let vary = ctx.res.val.headers.val.get("Vary")
  assert_eq(vary != None, true)
}
