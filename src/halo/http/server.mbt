// src/halo/http/server.mbt
// HTTP server wrapper for Halo web framework

/// Server struct represents an HTTP server
pub struct Server {
  address : String;
}

/// Create a new server with the given address
pub fn Server::new(address : String) -> Server {
  { address : address }
}

/// Get the server address
pub fn Server::get_address(self : Server) -> String {
  self.address
}

/// Start the server with the given handler function
/// The handler takes a Request and returns a Response
pub fn Server::start(handler : (@halo.Request) -> @halo.Response) -> Unit {
  // This is a simplified wrapper
  // In a real implementation, this would use MoonBit's HTTP primitives
  // to listen on the address and call the handler for each request
  println("Starting server on {address}")
}
