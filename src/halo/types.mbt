// src/halo/types.mbt
// Core type definitions for Halo web framework

/// Request wrapper
pub struct Request {
  http_method : String;
  path : String;
  headers : Map[String, String];
  body : Option[String];
}

/// Response wrapper
pub struct Response {
  status : Int;
  headers : Map[String, String];
  body : Option[String];
}

/// Context struct
pub struct Context {
  req : Request;
  res : Response;
  state : Map[String, String];
}

/// Next function type - calls the next middleware in chain
pub type Next = () -> Unit

///|
/// Middleware type - takes context and next function
pub type Middleware = (Context, Next) -> Unit

///|
/// Helper to create context for testing
pub fn make_context() -> Context {
  let req : Request = {
    http_method: "GET",
    path: "/",
    headers: Map::new(),
    body: None,
  }
  let res : Response = { status: 200, headers: Map::new(), body: None }
  { req, res, state: Map::new() }
}

/// Helper to create a no-op next function
pub fn make_next() -> Next {
  fn() { }
}

/// Helper to create a Request
pub fn make_request(http_method : String, path : String, headers : Map[String, String], body : Option[String]) -> Request {
  { http_method : http_method, path : path, headers : headers, body : body }
}

/// Helper to create a Response
pub fn make_response(status : Int, headers : Map[String, String], body : Option[String]) -> Response {
  { status : status, headers : headers, body : body }
}
