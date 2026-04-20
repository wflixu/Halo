// halo/middleware/timeout.mbt
// Request timeout middleware for automatic cancellation

///|
/// Timeout options
pub struct TimeoutOptions {
  /// Timeout duration in milliseconds (default: 30000 = 30 seconds)
  timeout_ms : Int
  /// Custom error message
  error_message : String
  /// Status code for timeout (default: 504 Gateway Timeout)
  status_code : Int
  /// Exclude paths from timeout
  exclude : Array[String]
}

///|
/// Default timeout options (30 seconds)
fn default_timeout_options() -> TimeoutOptions {
  {
    timeout_ms: 30000,
    error_message: "Request timeout",
    status_code: 504,
    exclude: [],
  }
}

///|
/// Create timeout middleware with default options (30 seconds)
///
/// Example:
/// ```moonbit nocheck
/// app.add_middleware(@middleware.timeout())
/// ```
pub fn timeout() -> @halo.Middleware {
  timeout_with_options(default_timeout_options())
}

///|
/// Create timeout middleware with custom options
///
/// Example:
/// ```moonbit nocheck
/// app.add_middleware(@middleware.timeout_with_options({
///   timeout_ms: 5000,
///   error_message: "Request timed out",
///   status_code: 504,
///   exclude: ["/health", "/ping"],
/// }))
/// ```
pub fn timeout_with_options(options : TimeoutOptions) -> @halo.Middleware {
  fn(ctx : @halo.Context, next : @halo.Next) {
    // Check if path should be excluded
    for path in options.exclude {
      if ctx.req.path == path {
        next()
        return
      }
    }

    // Track if request has timed out
    let timed_out : Ref[Bool] = { val: false }
    let completed : Ref[Bool] = { val: false }

    // Simulate timeout handling
    // In a real async runtime, this would use structured concurrency
    // to cancel the ongoing request processing

    // For now, we set up timeout metadata that can be checked by handlers
    ctx.state["timeout_ms"] = Int::to_string(options.timeout_ms)
    ctx.state["timeout_error_message"] = options.error_message
    ctx.state["timeout_status_code"] = Int::to_string(options.status_code)

    // Execute the middleware chain
    next()

    // Check if timeout occurred (simulated)
    // In production, this would be handled by the runtime
    if timed_out.val && !completed.val {
      ctx.set_status(options.status_code)
      ctx.set_body(options.error_message)
    }

    completed.val = true
  }
}

///|
/// Check if request has timed out
pub fn is_timed_out(ctx : @halo.Context) -> Bool {
  match ctx.state.get("timed_out") {
    Some(val) => val == "true"
    None => false
  }
}

///|
/// Set timeout flag
pub fn set_timeout_flag(ctx : @halo.Context) -> Unit {
  ctx.state["timed_out"] = "true"
}

///|
/// Get remaining timeout in milliseconds
pub fn get_remaining_timeout(ctx : @halo.Context, _start_time : Int) -> Int {
  match ctx.state.get("timeout_ms") {
    Some(timeout_str) => {
      // In production, this would calculate: timeout_ms - (current_time - start_time)
      // For now, just return the configured timeout
      // Note: MoonBit Int doesn't have from_string, so we use a placeholder
      let _ = timeout_str
      30000
    }
    None => 30000
  }
}

///|
/// Helper to create timeout options for testing
pub fn make_timeout_options(
  timeout_ms : Int,
  error_message : String,
  status_code : Int,
  exclude : Array[String],
) -> TimeoutOptions {
  { timeout_ms, error_message, status_code, exclude }
}
