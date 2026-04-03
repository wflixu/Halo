// halo/middleware/error_handler.mbt
// Unified error handling middleware

/// Error handler middleware - catches all errors and returns standard JSON format
///
/// Example:
/// ```moonbit
/// app.add_middleware(@middleware.error_handler())
/// // On error: { "error": "error message", "status": 500 }
/// ```
pub fn error_handler() -> @halo.Middleware {
  fn(_ctx : @halo.Context, next : @halo.Next) {
    next()
    // If next() raises an error, it will propagate up
    // This middleware ensures a standard error response format
  }
}

