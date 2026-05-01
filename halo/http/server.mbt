// halo/http/server.mbt
// Native-only HTTP server — wraps moonbitlang/async server

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
