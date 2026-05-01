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
/// Start the server listening on the given address
pub async fn App::listen(self : App, address : String) -> Unit {
  let handler = self.callback()
  // Handle ":3000" style addresses by prepending 0.0.0.0
  let normalized = if address.has_prefix(":") {
    "0.0.0.0" + address
  } else {
    address
  }
  let addr = @socket.Addr::parse(normalized)
  let server = @http.Server::new(addr)
  println("Starting Halo server on {normalized}")
  server.run_forever((request, _body, conn) => {
    let req = wrap_from_http(request)
    let res = handler(req)
    send_to_conn(conn, res)
  })
}

///|
/// Create the request handler function (internal use)
pub fn App::callback(self : App) -> (Request) -> Response {
  let composed = compose(self.middlewares)

  fn(req : Request) -> Response {
    let ctx = make_context()
    let ctx_with_req = { req, res: ctx.res, state: ctx.state }
    composed(ctx_with_req, make_next())
    ctx_with_req.res.val
  }
}

///|
/// Convert @http.Request to Halo Request
fn wrap_from_http(request : @http.Request) -> Request {
  let method_str = match request.meth {
    Get => "GET"
    Head => "HEAD"
    Post => "POST"
    Put => "PUT"
    Delete => "DELETE"
    Connect => "CONNECT"
    Options => "OPTIONS"
    Trace => "TRACE"
    Patch => "PATCH"
  }
  make_request(method_str, request.path, request.headers, None)
}

///|
/// Send Halo Response to the HTTP connection
async fn send_to_conn(conn : @http.ServerConnection, res : Response) -> Unit {
  let status_code = res.status.val
  let status_text = match status_code {
    200 => "OK"
    201 => "Created"
    204 => "No Content"
    400 => "BadRequest"
    404 => "NotFound"
    500 => "InternalServerError"
    _ => "Status"
  }
  let headers = res.headers.val
  match res.body.val {
    Some(body) =>
      conn..send_response(status_code, status_text, extra_headers=headers)..write(body).end_response()
    None =>
      conn..send_response(status_code, status_text, extra_headers=headers).end_response()
  }
}
