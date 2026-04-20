// halo/middleware/static.mbt
// Static file serving middleware

///|
/// Static file middleware options
pub struct StaticOptions {
  /// Root directory for static files
  root : String
  /// URL prefix (default: "/")
  prefix : String
  /// Enable caching headers (default: true)
  cache : Bool
  /// Max-age for cache (default: 31536000 = 1 year)
  max_age : Int
}

///|
/// Default static file options
fn default_static_options() -> StaticOptions {
  {
    root: "./public",
    prefix: "/",
    cache: true,
    max_age: 31536000,
  }
}

///|
/// Create static file middleware with root path
///
/// Example:
/// ```moonbit nocheck
/// app.add_middleware(@middleware.static_files("./public"))
/// ```
pub fn static_files(root : String) -> @halo.Middleware {
  let opts = default_static_options()
  static_with_options({
    root: root,
    prefix: opts.prefix,
    cache: opts.cache,
    max_age: opts.max_age,
  })
}

///|
/// Create static file middleware with custom prefix
///
/// Example:
/// ```moonbit nocheck
/// app.add_middleware(@middleware.static_with_prefix("./assets", "/static"))
/// ```
pub fn static_with_prefix(root : String, prefix : String) -> @halo.Middleware {
  let opts = default_static_options()
  static_with_options({
    root: root,
    prefix: prefix,
    cache: opts.cache,
    max_age: opts.max_age,
  })
}

///|
/// Create static file middleware with custom options
///
/// Example:
/// ```moonbit nocheck
/// app.add_middleware(@middleware.static_with_options({
///   root: "./assets",
///   prefix: "/static",
///   cache: true,
///   max_age: 86400,
/// }))
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
      // Remove prefix by splitting and taking the part after prefix
      let parts = String::split(path, options.prefix)
      let arr = parts.to_array()
      if Array::length(arr) > 1 {
        arr[1].to_string()
      } else {
        path
      }
    }

    // Build full file path
    let full_path = options.root + file_path

    // Security: prevent directory traversal
    if String::contains(full_path, "..") {
      ctx.set_status(403)
      ctx.set_body("Forbidden")
      return
    }

    // Get MIME type based on file extension
    let content_type = get_mime_type(full_path)

    // Set response headers
    ctx.res.val.headers.val["Content-Type"] = content_type

    // Set caching headers if enabled
    if options.cache {
      ctx.res.val.headers.val["Cache-Control"] = "public, max-age=" + Int::to_string(options.max_age)
      ctx.res.val.headers.val["ETag"] = generate_etag(full_path)
    }

    // Note: Actual file reading requires MoonBit runtime file I/O support
    // For now, we simulate by returning a placeholder
    // In production, this would read the actual file and stream it

    // Try to read file content (placeholder - depends on runtime)
    match read_file_content(full_path) {
      Some(content) => {
        ctx.set_body(content)
      }
      None => {
        ctx.set_status(404)
        ctx.set_body("File not found: " + file_path)
      }
    }
  }
}

///|
/// Get MIME type based on file extension
fn get_mime_type(path : String) -> String {
  let ext = get_file_extension(path)
  mime_type_for_ext(ext)
}

///|
/// Extract file extension from path
fn get_file_extension(path : String) -> String {
  let parts = String::split(path, ".")
  let arr = parts.to_array()
  if Array::length(arr) > 0 {
    arr[Array::length(arr) - 1].to_string()
  } else {
    ""
  }
}

///|
/// Generate ETag for file (simplified - uses path + length)
fn generate_etag(path : String) -> String {
  // In production, this should be based on file content hash
  // For now, use a simple approach
  "\"" + path + "-static\""
}

///|
/// Read file content (placeholder - requires MoonBit runtime support)
///
/// Note: This is a placeholder. Actual implementation depends on
/// MoonBit runtime providing file I/O primitives.
fn read_file_content(path : String) -> String? {
  // Placeholder: In real implementation, this would call MoonBit's
  // file reading API. For now, return None to simulate file not found.
  //
  // Expected MoonBit API (when available):
  // ```moonbit
  // match File::read_to_string(path) {
  //   Ok(content) => Some(content)
  //   Err(_) => None
  // }
  // ```
  None
}

///|
/// Helper to get the MIME type for a file extension
pub fn mime_type_for_ext(ext : String) -> String {
  match ext {
    "html" => "text/html"
    "htm" => "text/html"
    "css" => "text/css"
    "js" => "application/javascript"
    "json" => "application/json"
    "png" => "image/png"
    "jpg" => "image/jpeg"
    "jpeg" => "image/jpeg"
    "gif" => "image/gif"
    "svg" => "image/svg+xml"
    "ico" => "image/x-icon"
    "webp" => "image/webp"
    "woff" => "font/woff"
    "woff2" => "font/woff2"
    "ttf" => "font/ttf"
    "eot" => "application/vnd.ms-fontobject"
    "xml" => "application/xml"
    "txt" => "text/plain"
    "md" => "text/markdown"
    "pdf" => "application/pdf"
    "zip" => "application/zip"
    _ => "application/octet-stream"
  }
}

///|
/// Helper to create static options for testing
pub fn make_static_options(root : String, prefix : String, cache : Bool, max_age : Int) -> StaticOptions {
  {
    root: root,
    prefix: prefix,
    cache: cache,
    max_age: max_age,
  }
}
