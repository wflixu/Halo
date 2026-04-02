// src/halo/compose.mbt
// Middleware composition engine for Halo web framework

/// Compose an array of middleware functions into a single middleware
/// Middleware executes in order: first middleware's before-code runs first,
/// but its after-code runs last (onion model)
pub fn compose(middlewares: Array[Middleware]) -> Middleware {
  if middlewares.length() == 0 {
    // Return no-op middleware when array is empty
    return fn(_ctx: Context, _next: Next) {
      // Nothing to run
    }
  }

  // Return the composed middleware function
  fn(ctx: Context, next: Next) {
    // Create the dispatch function that runs middleware in order
    fn dispatch(index: Int) -> Unit {
      if index >= middlewares.length() {
        // No more middleware, call the final next
        next()
        return
      }

      // Get current middleware
      let mw = middlewares[index]

      // Create next function that will call the next middleware
      let next_fn = fn() {
        dispatch(index + 1)
      }

      // Execute current middleware with context and next function
      mw(ctx, next_fn)
    }

    // Start dispatching from the first middleware
    dispatch(0)
  }
}
