// halo/http/server.mbt
// HTTP Server — wraps moonbitlang/async HTTP server

///|
/// HTTP Server — wraps the moonbitlang/async HTTP server
pub struct Server {
  address : String
}

///|
/// Create a new Server bound to the given address string
/// Accepts addresses like ":3000" (binds all interfaces) or "127.0.0.1:3000"
pub fn Server::new(address : String) -> Server {
  let normalized = if address.has_prefix(":") {
    "0.0.0.0" + address
  } else {
    address
  }
  { address: normalized }
}

///|
/// Start the server with the given request handler
/// The handler receives a Request and returns a Response.
pub async fn Server::run_forever(
  self : Server,
  handler : (Request) -> Response,
) -> Unit {
  let addr = @socket.Addr::parse(self.address)
  let server = @async_http.Server::new(addr)
  server.run_forever((request, _body, conn) => {
    let req = from_async(request)
    let res = handler(req)
    res.send(conn)
  })
}
