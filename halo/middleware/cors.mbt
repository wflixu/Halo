// halo/middleware/cors.mbt
// Cross-Origin Resource Sharing (CORS) middleware

///|
/// CORS options
pub struct CorsOptions {
  allow_origins : Array[String]
  allow_methods : Array[String]
  allow_headers : Array[String]
  max_age : Int
}

///|
/// Default CORS options
fn default_cors_options() -> CorsOptions {
  {
    allow_origins: ["*"],
    allow_methods: ["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"],
    allow_headers: ["Content-Type", "Authorization", "X-Requested-With"],
    max_age: 86400,
  }
}

///|
/// CORS middleware with allow all origins
///
/// Example:
/// ```moonbit nocheck
/// app.add_middleware(@middleware.cors_allow_all())
/// ```
pub fn cors_allow_all() -> @halo.Middleware {
  cors_with_options(default_cors_options())
}

///|
/// CORS middleware with specific origins
///
/// Example:
/// ```moonbit nocheck
/// app.add_middleware(@middleware.cors_allow_origins(["https://example.com"]))
/// ```
pub fn cors_allow_origins(origins : Array[String]) -> @halo.Middleware {
  cors_with_options({
    allow_origins: origins,
    allow_methods: ["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"],
    allow_headers: ["Content-Type", "Authorization", "X-Requested-With"],
    max_age: 86400,
  })
}

///|
/// CORS middleware with custom options
pub fn cors_with_options(options : CorsOptions) -> @halo.Middleware {
  fn(ctx : @halo.Context, next : @halo.Next) {
    let origin = ctx.req.headers.get("Origin")
    let origin_str = match origin {
      Some(o) => o
      None => "*"
    }

    // Check if origin is allowed
    let is_allowed = Array::contains(options.allow_origins, "*") ||
      Array::contains(options.allow_origins, origin_str)

    if is_allowed {
      let headers = ctx.res.val.headers.val
      headers["Access-Control-Allow-Origin"] = origin_str
      headers["Access-Control-Allow-Methods"] = Array::join(
        options.allow_methods,
        ", ",
      )
      headers["Access-Control-Allow-Headers"] = Array::join(
        options.allow_headers,
        ", ",
      )
      headers["Access-Control-Max-Age"] = Int::to_string(options.max_age)
    }

    // Handle preflight OPTIONS request
    if ctx.req.http_method == "OPTIONS" {
      ctx.res.val.status.val = 204
      return
    }

    next()
  }
}
