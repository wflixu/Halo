// src/halo/app.mbt
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
/// Add middleware to the app
/// Returns self for method chaining
pub fn App::add_middleware(self : App, mw : Middleware) -> App {
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
/// Start the server with the given address
pub fn App::listen(self : App, _address : String) -> Unit {
  let handler = self.callback()
  // The handler can be passed to Server::start from the http package
  // For now, just print the address to indicate the server would start
  println("Server would start on {_address}")
  let _ = handler
}

///|
/// Create the request handler function (internal use)
fn App::callback(self : App) -> (Request) -> Response {
  let composed = compose(self.middlewares)

  fn(req : Request) -> Response {
    let ctx = make_context()
    // Create new context with updated req (structs are immutable)
    let ctx_with_req = { req, res: ctx.res, state: ctx.state }
    composed(ctx_with_req, make_next())
    ctx_with_req.res.val
  }
}
