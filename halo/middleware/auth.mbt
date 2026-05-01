// halo/middleware/auth.mbt
// Bearer Token Authentication middleware

///|
/// Auth options for Bearer Token authentication
pub struct AuthOptions {
  /// Token validation function - returns true if token is valid
  validate : (String) -> Bool
  /// Paths to exclude from authentication (prefix match)
  exclude : Array[String]
  /// Custom error message for invalid/missing token
  error_message : String
  /// Header name (default: "Authorization")
  header_name : String
}

///|
/// Default auth options - rejects all tokens, no exclusions
fn default_auth_options() -> AuthOptions {
  {
    validate: fn(_) { false },
    exclude: [],
    error_message: "Unauthorized",
    header_name: "Authorization",
  }
}

///|
/// Bearer Token authentication middleware
///
/// Validates the Authorization header contains a valid Bearer token.
/// Tokens are validated using the provided validation function.
///
/// Example:
/// ```moonbit nocheck
/// app.use(@middleware.bearer_auth(fn(token) {
///   // Your token validation logic here
///   token == "secret-token"
/// }))
/// ```
///
/// On missing or invalid token, returns 401 Unauthorized with JSON response:
/// `{ "error": "Unauthorized" }`
pub fn bearer_auth(validate_fn : (String) -> Bool) -> @halo.Middleware {
  let opts = default_auth_options()
  bearer_auth_with_options({
    validate: validate_fn,
    exclude: opts.exclude,
    error_message: opts.error_message,
    header_name: opts.header_name,
  })
}

///|
/// Bearer Token authentication middleware with custom options
///
/// Example:
/// ```moonbit nocheck
/// app.use(@middleware.bearer_auth_with_options({
///   validate: fn(token) { is_valid_token(token) },
///   exclude: ["/public", "/health", "/api/webhook"],
///   error_message: "Invalid or expired token",
/// }))
/// ```
pub fn bearer_auth_with_options(options : AuthOptions) -> @halo.Middleware {
  fn(ctx : @halo.Context, next : @halo.Next) {
    // Check if path should be excluded
    let is_excluded = check_path_excluded(ctx.req.path, options.exclude)

    if is_excluded {
      next()
      return
    }

    // Get Authorization header
    let auth_header = ctx.get_header(options.header_name)

    match auth_header {
      Some(header) =>
        // Extract Bearer token
        match extract_bearer_token(header) {
          Some(token) =>
            // Validate token
            if (options.validate)(token) {
              // Token is valid, continue
              next()
            } else {
              // Invalid token
              ctx.set_status(401)
              ctx.set_json("{ \"error\": \"" + options.error_message + "\" }")
            }
          None => {
            // Missing Bearer prefix
            ctx.set_status(401)
            ctx.set_json("{ \"error\": \"Missing Bearer token\" }")
          }
        }
      None => {
        // Missing Authorization header
        ctx.set_status(401)
        ctx.set_json("{ \"error\": \"" + options.error_message + "\" }")
      }
    }
  }
}

///|
/// Extract Bearer token from Authorization header value
///
/// Example:
/// ```moonbit nocheck
/// extract_bearer_token("Bearer abc123") // Returns Some("abc123")
/// extract_bearer_token("Basic abc123")  // Returns None
/// ```
fn extract_bearer_token(header : String) -> String? {
  if String::has_prefix(header, "Bearer ") {
    // Extract token after "Bearer " by splitting on space
    let parts = header.split(" ").to_array()
    if Array::length(parts) == 2 && parts[0].to_owned() == "Bearer" {
      let token = parts[1].to_owned()
      if String::length(token) > 0 {
        Some(token)
      } else {
        None
      }
    } else {
      None
    }
  } else {
    None
  }
}

///|
/// Check if the request path matches any excluded path prefix
fn check_path_excluded(path : String, exclude_paths : Array[String]) -> Bool {
  for excluded in exclude_paths {
    if String::has_prefix(path, excluded) {
      return true
    }
  }
  false
}

///|
/// Get Bearer token from request context
///
/// Returns the token string if present and valid, None otherwise.
///
/// Example:
/// ```moonbit nocheck
/// let token = @middleware.get_bearer_token(ctx)
/// match token {
///   Some(t) => println("Token: " + t)
///   None => println("No token")
/// }
/// ```
pub fn get_bearer_token(ctx : @halo.Context) -> String? {
  match ctx.get_header("Authorization") {
    Some(header) => extract_bearer_token(header)
    None => None
  }
}

///|
/// Get Bearer token from request context with custom header name
pub fn get_bearer_token_with_header(
  ctx : @halo.Context,
  header_name : String,
) -> String? {
  match ctx.get_header(header_name) {
    Some(header) => extract_bearer_token(header)
    None => None
  }
}

///|
/// Create auth options helper for testing
pub fn make_auth_options(
  validate_fn : (String) -> Bool,
  exclude : Array[String],
  error_message : String,
) -> AuthOptions {
  {
    validate: validate_fn,
    exclude,
    error_message,
    header_name: "Authorization",
  }
}
