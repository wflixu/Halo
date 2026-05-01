// halo/http/response.mbt
// HTTP Response type — defines the response abstraction for Halo

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
/// Send this Response to an async HTTP connection
pub async fn Response::send(
  self : Response,
  conn : @async_http.ServerConnection,
) -> Unit {
  let status_code = self.status.val
  let status_text = match status_code {
    200 => "OK"
    201 => "Created"
    204 => "No Content"
    400 => "BadRequest"
    404 => "NotFound"
    500 => "InternalServerError"
    _ => "Status"
  }
  let headers = self.headers.val
  match self.body.val {
    Some(body) =>
      conn
      ..send_response(status_code, status_text, extra_headers=headers)
      ..write(body)
      .end_response()
    None =>
      conn
      ..send_response(status_code, status_text, extra_headers=headers)
      .end_response()
  }
}

///|
/// Apply response to raw HTTP response setters (for custom handling)
pub fn apply_to_response(
  res : Response,
  set_status_fn : (Int) -> Unit,
  set_header_fn : (String, String) -> Unit,
  set_body_fn : (String) -> Unit,
) -> Unit {
  set_status_fn(res.status.val)

  for k in res.headers.val.keys() {
    let value = res.headers.val[k]
    set_header_fn(k, value)
  }

  match res.body.val {
    Some(body) => set_body_fn(body)
    None => ()
  }
}
