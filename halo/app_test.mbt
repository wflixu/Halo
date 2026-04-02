// halo/app_test.mbt
// Tests for App module

test "app can be created" {
  let app = App::new()
  let _ = app
}

test "app.add_middleware adds middleware" {
  let app = App::new()
  let mw = fn(_ctx: Context, _next: Next) { }
  let app2 = app.add_middleware(mw)
  assert_eq(app2.middleware_count(), 1)
}

test "app.add_middleware supports chaining" {
  let app = App::new()
  let mw1 = fn(_ctx: Context, _next: Next) { }
  let mw2 = fn(_ctx: Context, _next: Next) { }
  let app2 = app.add_middleware(mw1).add_middleware(mw2)
  assert_eq(app2.middleware_count(), 2)
}

test "app.listen starts server" {
  let app = App::new()
  app.listen(":3000")
  // This should not error
}
