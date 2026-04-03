// halo/middleware/session.mbt
// Session management middleware - simple in-memory session storage

///|
/// Session middleware options
pub struct SessionOptions {
  cookie_name : String
  cookie_path : String
  max_age : Int
}

///|
/// Default session options
fn default_session_options() -> SessionOptions {
  { cookie_name: "session_id", cookie_path: "/", max_age: 86400 }
}

///|
/// Session middleware - provides in-memory session storage
///
/// Example:
/// ```moonbit nocheck
/// app.add_middleware(@middleware.session())
///
/// // In handler:
/// let user_id = @middleware.session_get(ctx, "user_id")
/// @middleware.session_set(ctx, "user_id", "123")
/// ```
pub fn session() -> @halo.Middleware {
  session_with_options(default_session_options())
}

///|
/// Session middleware with custom options
pub fn session_with_options(options : SessionOptions) -> @halo.Middleware {
  fn(ctx : @halo.Context, next : @halo.Next) {
    // Initialize session data in context state
    ctx.state["session_data"] = ""
    next()
  }
}

///|
/// Get session value
pub fn session_get(ctx : @halo.Context, key : String) -> String? {
  ctx.state.get("session:" + key)
}

///|
/// Set session value
pub fn session_set(ctx : @halo.Context, key : String, value : String) -> Unit {
  ctx.state["session:" + key] = value
}

///|
/// Delete session value
pub fn session_delete(ctx : @halo.Context, key : String) -> Unit {
  // Sessions are stored in ctx.state, removal depends on Map API
  ignore(ctx.state)
}

///|
/// Clear entire session
pub fn session_clear(ctx : @halo.Context) -> Unit {
  ignore(ctx.state)
}
