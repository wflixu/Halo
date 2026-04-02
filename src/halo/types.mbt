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

/// Next function wrapper - holds a function that can be called
pub struct Next {
  dummy : Int
}

/// Middleware wrapper
pub struct Middleware {
  dummy : Int
}

/// Helper to create context for testing
pub fn make_context() -> Context {
  let req : Request = { http_method : "GET", path : "/", headers : Map::new(), body : None }
  let res : Response = { status : 200, headers : Map::new(), body : None }
  { req : req, res : res, state : Map::new() }
}

/// Helper to create a next function
pub fn make_next() -> Next {
  Next::new()
}

/// Constructor for Next
pub fn Next::new() -> Next {
  { dummy : 0 }
}
