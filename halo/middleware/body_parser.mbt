// halo/middleware/body_parser.mbt
// Request body parsing middleware

///|
/// Body parser middleware - parses JSON and form bodies
/// Stores raw body in ctx.state["body"] and parsed JSON in ctx.state["json"]
///
/// Example:
/// ```moonbit nocheck
/// app.add_middleware(@middleware.body_parser())
///
/// // In handler:
/// let raw_body = ctx.state.get("body")
/// let json_body = ctx.state.get("json")
/// ```
pub fn body_parser() -> @halo.Middleware {
  fn(ctx : @halo.Context, next : @halo.Next) {
    let content_type = ctx.req.headers.get("Content-Type")
    let body_str = ctx.req.body

    match body_str {
      Some(raw) => {
        ctx.state["body"] = raw

        // Parse JSON
        match content_type {
          Some(ct) =>
            if String::has_prefix(ct, "application/json") {
              ctx.state["json"] = raw
            } else if String::has_prefix(
                ct, "application/x-www-form-urlencoded",
              ) {
              let form = parse_form(raw)
              // Store form fields as individual state entries
              for key in Map::keys(form) {
                ignore(ctx.state.set("form:" + key, form[key]))
              }
            }
          None => ignore(0)
        }
      }
      None => ctx.state["body"] = ""
    }

    next()
  }
}

///|
/// Parse form-encoded string into Map
fn parse_form(body : String) -> Map[String, String] {
  let form : Map[String, String] = Map::new()
  let pairs = String::split(body, "&")

  for pair in pairs {
    let pair_str = pair.to_string()
    if pair_str != "" {
      let parts = String::split(pair_str, "=")
      let parts_arr : Array[String] = []
      for p in parts {
        parts_arr.push(p.to_string())
      }
      if parts_arr.length() >= 2 {
        let key = parts_arr[0]
        let value = parts_arr[1]
        form[key] = value
      }
    }
  }

  form
}

///|
/// Helper to get raw body string
pub fn get_body(ctx : @halo.Context) -> String? {
  ctx.state.get("body")
}

///|
/// Helper to get JSON body string
pub fn get_json(ctx : @halo.Context) -> String? {
  ctx.state.get("json")
}

///|
/// Helper to get form field value
pub fn get_form_field(ctx : @halo.Context, field : String) -> String? {
  ctx.state.get("form:" + field)
}
