// halo/app_test.mbt
// Tests for App module

///|
test "app can be created" {
  let app = App::new()
  let _ = app
}

///|
test "app.use adds middleware" {
  let app = App::new()
  let mw = fn(_ctx : Context, _next : Next) {  }
  let app2 = app.use(mw)
  assert_eq(app2.middleware_count(), 1)
}

///|
test "app.use supports chaining" {
  let app = App::new()
  let mw1 = fn(_ctx : Context, _next : Next) {  }
  let mw2 = fn(_ctx : Context, _next : Next) {  }
  let app2 = app.use(mw1).use(mw2)
  assert_eq(app2.middleware_count(), 2)
}

///|
test "app.callback processes middleware and returns response" {
  let app = App::new()
  ignore(
    app.use(fn(ctx : Context, next : Next) {
      ctx.set_body("hello from middleware")
      next()
    }),
  )
  let handler = app.callback()
  let req = make_request("GET", "/", Map::new(), None)
  let res = handler(req)
  assert_eq(res.body.val, Some("hello from middleware"))
  assert_eq(res.status.val, 200)
}

///|
test "app.callback sets status from middleware" {
  let app = App::new()
  ignore(
    app.use(fn(ctx : Context, _next : Next) {
      ctx.set_status(201)
      ctx.set_body("created")
    }),
  )
  let handler = app.callback()
  let req = make_request("GET", "/", Map::new(), None)
  let res = handler(req)
  assert_eq(res.status.val, 201)
  assert_eq(res.body.val, Some("created"))
}
