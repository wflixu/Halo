// halo/http/request.mbt
// Native-only conversion from moonbitlang/async types to Halo Request

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
