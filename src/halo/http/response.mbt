// src/halo/http/response.mbt
// Response wrapper for Halo web framework

/// Wrap raw HTTP response parameters into our Response type
pub fn wrap_response(status : Int, headers : Map[String, String]) -> @halo.Response {
  @halo.make_response(status, headers, None)
}

/// Apply our Response to raw HTTP response setters
pub fn apply_to_response(res : @halo.Response, set_status_fn : (Int) -> Unit, set_header_fn : (String, String) -> Unit, set_body_fn : (String) -> Unit) -> Unit {
  set_status_fn(res.status)

  for k in res.headers.keys() {
    let value = res.headers[k]
    set_header_fn(k, value)
  }

  match res.body {
    Some(body) => set_body_fn(body)
    None => ()
  }
}
