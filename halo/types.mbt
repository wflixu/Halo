// halo/types.mbt
// Core type definitions for Halo web framework
// Request and Response types are defined in halo/http, used here via @http

///|
/// Context struct — carries request, response, and state through the middleware chain
pub struct Context {
  req : @http.Request
  res : Ref[@http.Response]
  state : Map[String, String]
}

///|
/// Next function type — calls the next middleware in chain
pub type Next = () -> Unit

///|
/// Middleware type — takes context and next function
pub type Middleware = (Context, Next) -> Unit
