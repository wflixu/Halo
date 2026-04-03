// halo/middleware/static.mbt
// Static file serving middleware

///|
/// Static file middleware options
pub struct StaticOptions {
  root : String
  prefix : String
}

///|
/// Create static file middleware with default options (./public)
///
/// Example:
/// ```moonbit nocheck
/// app.add_middleware(@middleware.static_files("./public"))
/// ```
pub fn static_files(root : String) -> @halo.Middleware {
  static_with_options({ root, prefix: "/" })
}

///|
/// Create static file middleware with custom prefix
///
/// Example:
/// ```moonbit nocheck
/// app.add_middleware(@middleware.static_with_options({ root: "./assets", prefix: "/static" }))
/// ```
pub fn static_with_options(options : StaticOptions) -> @halo.Middleware {
  fn(ctx : @halo.Context, next : @halo.Next) {
    let path = ctx.req.path

    // Check if path matches prefix
    let matches_prefix = options.prefix == "/" ||
      String::has_prefix(path, options.prefix)

    if !matches_prefix {
      next()
      return
    }

    // Remove prefix from path
    let file_path = if options.prefix == "/" {
      path
    } else {
      path[String::length(options.prefix):].to_string()
    }

    // Build full file path
    let full_path = options.root + file_path

    // Log the file path being served
    println("Serving static file: " + full_path)

    // Note: Actual file reading depends on MoonBit runtime support
    // For now, just call next() to continue the middleware chain
    next()
  }
}
