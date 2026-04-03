// halo/middleware/cookie_parser.mbt
// Cookie parsing middleware

/// Cookie parser middleware - parses Cookie header into ctx.state
///
/// Example:
/// ```moonbit
/// app.add_middleware(@middleware.cookie_parser())
///
/// // In handler:
/// let session_id = ctx.state.get("cookie:session_id")
/// ```
pub fn cookie_parser() -> @halo.Middleware {
  fn(ctx : @halo.Context, next : @halo.Next) {
    let cookie_header = ctx.req.headers.get("Cookie")

    match cookie_header {
      Some(header) => {
        let cookies = parse_cookies(header)
        for key in Map::keys(cookies) {
          ignore(ctx.state.set("cookie:" + key, cookies[key]))
        }
      }
      None => {
        // No cookies
        ignore(0)
      }
    }

    next()
  }
}

/// Parse Cookie header string into Map
fn parse_cookies(header : String) -> Map[String, String] {
  let cookies : Map[String, String] = Map::new()
  let pairs = String::split(header, ";")

  for pair in pairs {
    let pair_str = pair.to_string()
    // Trim leading space
    let trimmed = String::trim(pair_str).to_string()
    if trimmed != "" {
      let parts = String::split(trimmed, "=")
      let parts_arr : Array[String] = []
      for p in parts {
        parts_arr.push(p.to_string())
      }
      if parts_arr.length() >= 2 {
        let key = parts_arr[0]
        let value = parts_arr[1]
        ignore(cookies.set(key, value))
      } else if parts_arr.length() == 1 {
        ignore(cookies.set(parts_arr[0], ""))
      }
    }
  }

  cookies
}

/// Helper to get cookie value
pub fn get_cookie(ctx : @halo.Context, name : String) -> Option[String] {
  ctx.state.get("cookie:" + name)
}

/// Set cookie in response header
pub fn set_cookie(ctx : @halo.Context, name : String, value : String) -> Unit {
  let cookie = name + "=" + value
  let existing = ctx.res.val.headers.val.get("Set-Cookie")
  match existing {
    Some(e) => {
      ctx.res.val.headers.val["Set-Cookie"] = e + "; " + cookie
    }
    None => {
      ctx.res.val.headers.val["Set-Cookie"] = cookie
    }
  }
}

/// Set cookie with options (path, max-age, etc.)
pub fn set_cookie_with_options(
  ctx : @halo.Context,
  name : String,
  value : String,
  path : Option[String],
  max_age : Option[Int],
  http_only : Bool,
  secure : Bool
) -> Unit {
  let mut cookie = name + "=" + value

  match path {
    Some(p) => { cookie = cookie + "; Path=" + p }
    None => { ignore(0) }
  }

  match max_age {
    Some(age) => { cookie = cookie + "; Max-Age=" + Int::to_string(age) }
    None => { ignore(0) }
  }

  if http_only {
    cookie = cookie + "; HttpOnly"
  }

  if secure {
    cookie = cookie + "; Secure"
  }

  let existing = ctx.res.val.headers.val.get("Set-Cookie")
  match existing {
    Some(e) => {
      ctx.res.val.headers.val["Set-Cookie"] = e + "; " + cookie
    }
    None => {
      ctx.res.val.headers.val["Set-Cookie"] = cookie
    }
  }
}

/// Delete cookie
pub fn delete_cookie(ctx : @halo.Context, name : String) -> Unit {
  set_cookie_with_options(ctx, name, "", Some("/"), Some(0), true, false)
}
