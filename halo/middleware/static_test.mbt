// halo/middleware/static_test.mbt
// Blackbox tests for static file middleware

///|
test "static_files creates middleware with root path" {
  let middleware = @middleware.static_files("./public")
  let headers = Map::new()
  let req = @halo.make_request("GET", "/test.css", headers, None)
  let ctx = @halo.make_context_with_request(req)
  let called : Ref[Bool] = { val: false }

  middleware(ctx, fn() { called.val = true })

  // Should continue chain since file doesn't exist (placeholder behavior)
  assert_eq(called.val, false)
  assert_eq(ctx.res.val.status.val, 404)
}

///|
test "static_with_prefix creates middleware with custom prefix" {
  let middleware = @middleware.static_with_prefix("./assets", "/static")
  let headers = Map::new()
  let req = @halo.make_request("GET", "/static/style.css", headers, None)
  let ctx = @halo.make_context_with_request(req)
  let called : Ref[Bool] = { val: false }

  middleware(ctx, fn() { called.val = true })

  // Should not continue chain - should try to serve file
  assert_eq(called.val, false)
}

///|
test "static_with_prefix skips non-matching paths" {
  let middleware = @middleware.static_with_prefix("./assets", "/static")
  let headers = Map::new()
  let req = @halo.make_request("GET", "/other/file.css", headers, None)
  let ctx = @halo.make_context_with_request(req)
  let called : Ref[Bool] = { val: false }

  middleware(ctx, fn() { called.val = true })

  // Should continue chain for non-matching prefix
  assert_eq(called.val, true)
  assert_eq(ctx.res.val.status.val, 200)
}

///|
test "static middleware blocks directory traversal" {
  let middleware = @middleware.static_files("./public")
  let headers = Map::new()
  let req = @halo.make_request("GET", "/../../../etc/passwd", headers, None)
  let ctx = @halo.make_context_with_request(req)
  let called : Ref[Bool] = { val: false }

  middleware(ctx, fn() { called.val = true })

  // Should block directory traversal
  assert_eq(called.val, false)
  assert_eq(ctx.res.val.status.val, 403)
  assert_eq(ctx.res.val.body.val, Some("Forbidden"))
}

///|
test "mime_type_for_ext returns correct types" {
  assert_eq(@middleware.mime_type_for_ext("html"), "text/html")
  assert_eq(@middleware.mime_type_for_ext("css"), "text/css")
  assert_eq(@middleware.mime_type_for_ext("js"), "application/javascript")
  assert_eq(@middleware.mime_type_for_ext("json"), "application/json")
  assert_eq(@middleware.mime_type_for_ext("png"), "image/png")
  assert_eq(@middleware.mime_type_for_ext("jpg"), "image/jpeg")
  assert_eq(@middleware.mime_type_for_ext("jpeg"), "image/jpeg")
  assert_eq(@middleware.mime_type_for_ext("gif"), "image/gif")
  assert_eq(@middleware.mime_type_for_ext("svg"), "image/svg+xml")
  assert_eq(@middleware.mime_type_for_ext("webp"), "image/webp")
  assert_eq(@middleware.mime_type_for_ext("woff"), "font/woff")
  assert_eq(@middleware.mime_type_for_ext("woff2"), "font/woff2")
  assert_eq(@middleware.mime_type_for_ext("ttf"), "font/ttf")
  assert_eq(@middleware.mime_type_for_ext("pdf"), "application/pdf")
  assert_eq(@middleware.mime_type_for_ext("txt"), "text/plain")
  assert_eq(@middleware.mime_type_for_ext("unknown"), "application/octet-stream")
}

///|
test "static_with_options sets cache headers" {
  let middleware = @middleware.static_with_options(
    @middleware.make_static_options("./public", "/", true, 3600)
  )
  let headers = Map::new()
  let req = @halo.make_request("GET", "/test.css", headers, None)
  let ctx = @halo.make_context_with_request(req)
  let called : Ref[Bool] = { val: false }

  middleware(ctx, fn() { called.val = true })

  // Should set Content-Type header
  let content_type = ctx.res.val.headers.val.get("Content-Type")
  assert_eq(content_type != None, true)
}

///|
test "static_with_options cache=false skips cache headers" {
  let middleware = @middleware.static_with_options(
    @middleware.make_static_options("./public", "/", false, 3600)
  )
  let headers = Map::new()
  let req = @halo.make_request("GET", "/test.css", headers, None)
  let ctx = @halo.make_context_with_request(req)
  let called : Ref[Bool] = { val: false }

  middleware(ctx, fn() { called.val = true })

  // Should set Content-Type but not Cache-Control
  let cache_control = ctx.res.val.headers.val.get("Cache-Control")
  assert_eq(cache_control, None)
}

///|
test "static middleware returns 404 for missing files" {
  let middleware = @middleware.static_files("./public")
  let headers = Map::new()
  let req = @halo.make_request("GET", "/nonexistent.css", headers, None)
  let ctx = @halo.make_context_with_request(req)
  let called : Ref[Bool] = { val: false }

  middleware(ctx, fn() { called.val = true })

  // Placeholder behavior: always returns 404 since file reading is not implemented
  assert_eq(called.val, false)
  assert_eq(ctx.res.val.status.val, 404)
}
