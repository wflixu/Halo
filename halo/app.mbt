// halo/app.mbt
// App module for Halo web framework

///|
pub struct App {
  middlewares : Array[Middleware]
}

///|
/// Create a new App instance
pub fn App::new() -> App {
  { middlewares: [] }
}

///|
/// Register middleware (Koa-style API)
/// Returns self for method chaining
pub fn App::use(self : App, mw : Middleware) -> App {
  let middlewares = self.middlewares
  middlewares.push(mw)
  { middlewares, }
}

///|
/// Get the number of registered middlewares
pub fn App::middleware_count(self : App) -> Int {
  self.middlewares.length()
}

///|
/// Create the request handler function (internal use)
pub fn App::callback(self : App) -> (@http.Request) -> @http.Response {
  let composed = compose(self.middlewares)

  fn(req : @http.Request) -> @http.Response {
    let ctx = make_context_with_request(req)
    composed(ctx, make_next())
    ctx.res.val
  }
}

///|
/// Start the server listening on the given address
/// Delegates to @http.Server for HTTP handling
pub async fn App::listen(self : App, address : String) -> Unit {
  let handler = self.callback()
  let server = @http.Server::new(address)
  println("Starting Halo server on {address}")
  server.run_forever(handler)
}
