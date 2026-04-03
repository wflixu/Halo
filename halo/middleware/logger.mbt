// halo/middleware/logger.mbt
// Request logging middleware

/// Logger middleware - logs method, path and status
///
/// Example:
/// ```moonbit
/// app.add_middleware(@middleware.logger())
/// // Output: GET /users -> 200
/// ```
pub fn logger() -> @halo.Middleware {
  fn(ctx : @halo.Context, next : @halo.Next) {
    let http_method = ctx.req.http_method
    let path = ctx.req.path

    next()

    let status = ctx.res.val.status.val

    println(http_method + " " + path + " -> " + Int::to_string(status))
  }
}
