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
  status : Ref[Int];
  headers : Ref[Map[String, String]];
  body : Ref[Option[String]];
}

/// Context struct
pub struct Context {
  req : Request;
  res : Ref[Response];
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
  let res : Ref[Response] = { val: { status: {val: 200}, headers: {val: Map::new()}, body: {val: None} } }
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
  { status : {val: status}, headers : {val: headers}, body : {val: body} }
}

///|
/// Context helper methods

/// Set the response body
pub fn Context::set_body(self : Context, body : String) -> Unit {
  self.res.val.body.val = Some(body)
}

/// Set the response status code
pub fn Context::set_status(self : Context, status : Int) -> Unit {
  self.res.val.status.val = status
}

/// Set the response JSON body with appropriate content-type header
pub fn Context::set_json(self : Context, json_str : String) -> Unit {
  self.res.val.headers.val["Content-Type"] = "application/json"
  self.res.val.body.val = Some(json_str)
}
