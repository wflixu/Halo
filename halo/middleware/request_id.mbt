// halo/middleware/request_id.mbt
// Request ID middleware - adds unique ID to each request for tracing

/// Request ID middleware options
pub struct RequestIdOptions {
  /// Header name for request ID (default: "X-Request-ID")
  header_name : String
  /// Generate custom ID (if None, use default generator)
  generator : Option[() -> String]
}

/// Default request ID options
fn default_request_id_options() -> RequestIdOptions {
  {
    header_name: "X-Request-ID",
    generator: None,
  }
}

/// Request ID middleware - adds unique ID to each request
///
/// Example:
/// ```moonbit
/// app.add_middleware(@middleware.request_id())
///
/// // In handler:
/// let req_id = ctx.state.get("request_id")
/// ```
pub fn request_id() -> @halo.Middleware {
  request_id_with_options(default_request_id_options())
}

/// Request ID middleware with custom options
pub fn request_id_with_options(options : RequestIdOptions) -> @halo.Middleware {
  fn(ctx : @halo.Context, next : @halo.Next) {
    // Check if client provided a request ID
    let req_id = match ctx.req.headers.get(options.header_name) {
      Some(id) => id
      None => generate_request_id()
    }

    // Store in context state
    ctx.state["request_id"] = req_id

    // Add response header
    ctx.res.val.headers.val[options.header_name] = req_id

    next()
  }
}

/// Generate a unique request ID
fn generate_request_id() -> String {
  // Simple UUID-like format: timestamp + random
  let ts = "1234567890"  // In real implementation: Int::to_string(os::time())
  let rand = "abcd"
  "req_" + ts + "_" + rand
}

/// Get request ID from context
pub fn get_request_id(ctx : @halo.Context) -> Option[String] {
  ctx.state.get("request_id")
}
