// halo/http/request.mbt
// HTTP Request type — the low-level HTTP abstraction for Halo

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
/// Convert from @async_http.Request (moonbitlang/async) to Halo Request
pub fn from_async(raw : @async_http.Request) -> Request {
  let method_str = match raw.meth {
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
  { http_method: method_str, path: raw.path, headers: raw.headers, body: None }
}
