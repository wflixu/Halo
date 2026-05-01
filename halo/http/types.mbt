// halo/http/types.mbt
// Pure type definitions — no dependency on native async types
// These types compile for all targets, enabling the core framework
// (Context, Middleware, App) to be available for non-native builds

///|
/// Low-level HTTP Request type
pub struct Request {
  http_method : String
  path : String
  headers : Map[String, String]
  body : String?
}

///|
/// Create a Request from raw values
pub fn Request::new(
  http_method : String,
  path : String,
  headers : Map[String, String],
  body : String?,
) -> Request {
  { http_method, path, headers, body }
}

///|
/// HTTP Response type
pub struct Response {
  status : Ref[Int]
  headers : Ref[Map[String, String]]
  body : Ref[String?]
}

///|
/// Create a new Response with default values (200 OK, empty headers, no body)
pub fn Response::new() -> Response {
  { status: { val: 200 }, headers: { val: Map::new() }, body: { val: None } }
}

///|
/// Create a Response with specific values
pub fn Response::new_with(
  status : Int,
  headers : Map[String, String],
  body : String?,
) -> Response {
  { status: { val: status }, headers: { val: headers }, body: { val: body } }
}

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
