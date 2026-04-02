// src/halo/http/request.mbt
// Request wrapper for Halo web framework

/// Wrap raw HTTP request parameters into our Request type
pub fn wrap_request(http_method : String, path : String, headers : Map[String, String], body : Option[String]) -> @halo.Request {
  @halo.make_request(http_method, path, headers, body)
}
