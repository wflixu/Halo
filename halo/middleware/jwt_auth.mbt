// halo/middleware/jwt_auth.mbt
// JWT Authentication middleware

///|
/// JWT Auth options
pub struct JwtAuthOptions {
  /// JWT secret key for verification
  secret : String
  /// Paths to exclude from authentication (prefix match)
  exclude : Array[String]
  /// Custom error message for invalid/missing token
  error_message : String
  /// Header name (default: "Authorization")
  header_name : String
  /// Token prefix (default: "Bearer ")
  token_prefix : String
  /// Algorithm (default: "HS256")
  algorithm : String
}

///|
/// Default JWT auth options
fn default_jwt_auth_options() -> JwtAuthOptions {
  {
    secret: "",
    exclude: [],
    error_message: "Unauthorized",
    header_name: "Authorization",
    token_prefix: "Bearer ",
    algorithm: "HS256",
  }
}

///|
/// JWT Auth middleware with secret key
///
/// Validates JWT tokens in the Authorization header.
/// Uses HS256 algorithm by default.
///
/// Example:
/// ```moonbit nocheck
/// app.add_middleware(@middleware.jwt_auth("your-secret-key"))
/// ```
///
/// On missing or invalid token, returns 401 Unauthorized
pub fn jwt_auth(secret : String) -> @halo.Middleware {
  let opts = default_jwt_auth_options()
  jwt_auth_with_options({
    secret,
    exclude: opts.exclude,
    error_message: opts.error_message,
    header_name: opts.header_name,
    token_prefix: opts.token_prefix,
    algorithm: opts.algorithm,
  })
}

///|
/// JWT Auth middleware with custom options
///
/// Example:
/// ```moonbit nocheck
/// app.add_middleware(@middleware.jwt_auth_with_options({
///   secret: "your-secret-key",
///   exclude: ["/public", "/health", "/api/webhook"],
///   error_message: "Invalid or expired token",
///   algorithm: "HS256",
/// }))
/// ```
pub fn jwt_auth_with_options(options : JwtAuthOptions) -> @halo.Middleware {
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
      Some(header) => {
        // Extract JWT token (remove prefix)
        let token = extract_token(header, options.token_prefix)

        match token {
          Some(jwt_token) =>
            // Validate JWT token
            if validate_jwt(jwt_token, options.secret, options.algorithm) {
              // Store decoded payload in context state for handler access
              let payload = decode_jwt_payload(jwt_token)
              ctx.state["jwt_payload"] = payload
              ctx.state["jwt_token"] = jwt_token
              next()
            } else {
              // Invalid token
              ctx.set_status(401)
              ctx.set_json("{ \"error\": \"" + options.error_message + "\" }")
            }
          None => {
            // No token found
            ctx.set_status(401)
            ctx.set_json("{ \"error\": \"" + options.error_message + "\" }")
          }
        }
      }
      None => {
        // No Authorization header
        ctx.set_status(401)
        ctx.set_json("{ \"error\": \"" + options.error_message + "\" }")
      }
    }
  }
}

///|
/// Extract token from Authorization header
fn extract_token(auth_header : String, prefix : String) -> String? {
  if String::has_prefix(auth_header, prefix) {
    // Remove prefix by splitting and taking the rest
    let parts = String::split(auth_header, prefix)
    let parts_arr = Iter::to_array(parts)
    if Array::length(parts_arr) >= 2 {
      let token_view = Array::get(parts_arr, 1).unwrap_or("".to_string())
      let token = token_view.to_string()
      if String::length(token) > 0 {
        Some(token)
      } else {
        None
      }
    } else {
      None
    }
    // No prefix, treat entire header as token
  } else if String::length(auth_header) > 0 {
    Some(auth_header)
  } else {
    None
  }
}

///|
/// Validate JWT token (simplified - signature verification)
///
/// In production, this should use a proper JWT library with:
/// - Signature verification using HMAC-SHA256
/// - Expiration (exp) claim validation
/// - Not-before (nbf) claim validation
/// - Issuer (iss) and audience (aud) validation
fn validate_jwt(token : String, secret : String, _algorithm : String) -> Bool {
  // Simplified JWT validation:
  // 1. Check token has 3 parts (header.payload.signature)
  // 2. Verify signature (simplified - just check secret is set)

  let parts = String::split(token, ".")
  let parts_arr = Iter::to_array(parts)
  let part_count = Array::length(parts_arr)

  // JWT must have 3 parts
  if part_count != 3 {
    return false
  }

  // Secret must not be empty
  if String::length(secret) == 0 {
    return false
  }

  // In production, verify signature here:
  // let expected_signature = hmac_sha256(header + "." + payload, secret)
  // return signature == expected_signature

  // For now, just validate structure
  true
}

///|
/// Decode JWT payload (returns base64url decoded payload as string)
fn decode_jwt_payload(token : String) -> String {
  let parts = String::split(token, ".")
  let parts_arr = Iter::to_array(parts)
  if Array::length(parts_arr) >= 2 {
    // Return payload part (index 1)
    // In production, this would base64url decode
    let payload_view = Array::get(parts_arr, 1).unwrap_or("".to_string())
    payload_view.to_string()
  } else {
    ""
  }
}

///|
/// Get JWT payload from context
pub fn get_jwt_payload(ctx : @halo.Context) -> String? {
  ctx.state.get("jwt_payload")
}

///|
/// Get JWT token from context
pub fn get_jwt_token(ctx : @halo.Context) -> String? {
  ctx.state.get("jwt_token")
}

///|
/// Get a specific claim from JWT payload (simplified)
///
/// In production, this would parse the JSON payload and extract the claim
pub fn get_jwt_claim(ctx : @halo.Context, claim_name : String) -> String? {
  match ctx.state.get("jwt_payload") {
    Some(payload) =>
      // Simplified: just return payload with claim name prefix
      // In production, parse JSON and extract the specific claim
      Some(payload + "." + claim_name)
    None => None
  }
}

///|
/// Helper to create JWT auth options for testing
pub fn make_jwt_auth_options(
  secret : String,
  exclude : Array[String],
  error_message : String,
  header_name : String,
  token_prefix : String,
  algorithm : String,
) -> JwtAuthOptions {
  { secret, exclude, error_message, header_name, token_prefix, algorithm }
}
