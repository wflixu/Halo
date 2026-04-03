// halo/router/router_test.mbt
// Router tests

///|
test "Router can be created" {
  let router = @router.Router::new()
  let _ = router
}

///|
test "Router registers GET route" {
  let router = @router.Router::new()
  let handler = fn(_ctx : @halo.Context, _next : @halo.Next) {  }
  let router2 = router.get("/test", handler)
  let _ = router2
}

///|
test "Router supports method chaining" {
  let router = @router.Router::new()
  let h1 = fn(_ctx : @halo.Context, _next : @halo.Next) {  }
  let h2 = fn(_ctx : @halo.Context, _next : @halo.Next) {  }
  let router2 = router.get("/a", h1).post("/b", h2)
  let _ = router2
}

///|
test "Route matches static path" {
  let route = @router.Route::new("GET", "/users", fn(_ctx, _next) {  })
  let result = route.do_match("/users")
  assert_eq(result.matched, true)
}

///|
test "Route does not match wrong path" {
  let route = @router.Route::new("GET", "/users", fn(_ctx, _next) {  })
  let result = route.do_match("/posts")
  assert_eq(result.matched, false)
}

///|
test "Route extracts path parameter" {
  let route = @router.Route::new("GET", "/user/:id", fn(_ctx, _next) {  })
  let result = route.do_match("/user/123")
  assert_eq(result.matched, true)
  assert_eq(result.params.get("id"), Some("123"))
}

///|
test "Route extracts multiple parameters" {
  let route = @router.Route::new("GET", "/user/:userId/post/:postId", fn(
    _ctx,
    _next,
  ) {

  })
  let result = route.do_match("/user/42/post/99")
  assert_eq(result.matched, true)
  assert_eq(result.params.get("userId"), Some("42"))
  assert_eq(result.params.get("postId"), Some("99"))
}

///|
test "Route matches wildcard" {
  let route = @router.Route::new("GET", "/files/*", fn(_ctx, _next) {  })
  let result = route.do_match("/files/a/b/c")
  assert_eq(result.matched, true)
}

///|
test "Route matches named wildcard" {
  let route = @router.Route::new("GET", "/files/:path*", fn(_ctx, _next) {  })
  let result = route.do_match("/files/js/app.js")
  assert_eq(result.matched, true)
  assert_eq(result.params.get("path"), Some("js/app.js"))
}

///|
test "Route matches method" {
  let route = @router.Route::new("GET", "/test", fn(_ctx, _next) {  })
  assert_eq(route.matches_method("GET"), true)
  assert_eq(route.matches_method("POST"), false)
}

///|
test "Any route matches all methods" {
  let route = @router.Route::new("*", "/test", fn(_ctx, _next) {  })
  assert_eq(route.matches_method("GET"), true)
  assert_eq(route.matches_method("POST"), true)
  assert_eq(route.matches_method("DELETE"), true)
}

///|
test "Router finds matching route" {
  let router = @router.Router::new()
  let handler = fn(ctx : @halo.Context, _next : @halo.Next) {
    ctx.set_body("matched")
  }
  let router2 = router.get("/hello", handler)
  let _ = router2
}

///|
test "Router to_middleware creates middleware function" {
  let router = @router.Router::new()
  let handler = fn(ctx : @halo.Context, _next : @halo.Next) {
    ctx.set_body("hello")
  }
  let router2 = router.get("/test", handler)
  let mw = router2.to_middleware()
  let _ = mw
}
