// halo/middleware/etag.mbt
// ETag middleware for HTTP caching

///|
/// ETag options
pub struct EtagOptions {
  /// Enable weak ETags (default: false)
  weak : Bool
  /// Minimum size in bytes to generate ETag (default: 1)
  min_size : Int
  /// Hash algorithm (default: "md5")
  algorithm : String
}

///|
/// Default ETag options
fn default_etag_options() -> EtagOptions {
  { weak: false, min_size: 1, algorithm: "md5" }
}

///|
/// Create ETag middleware with default options
///
/// Example:
/// ```moonbit nocheck
/// app.use(@middleware.etag())
/// ```
pub fn etag() -> @halo.Middleware {
  etag_with_options(default_etag_options())
}

///|
/// Create ETag middleware with custom options
///
/// Example:
/// ```moonbit nocheck
/// app.use(@middleware.etag_with_options({
///   weak: true,
///   min_size: 100,
/// }))
/// ```
pub fn etag_with_options(options : EtagOptions) -> @halo.Middleware {
  fn(ctx : @halo.Context, next : @halo.Next) {
    // Continue the middleware chain first
    next()

    // After response is generated, compute and set ETag
    let body = ctx.res.val.body.val

    match body {
      Some(body_str) => {
        // Check minimum size
        if String::length(body_str) < options.min_size {
          return
        }

        // Only generate ETag if not already set by handler
        let existing_etag = ctx.res.val.headers.val.get("ETag")
        if existing_etag == None {
          // Generate ETag based on body content
          let etag_value = compute_etag(body_str, options.weak)

          // Set ETag header
          ctx.res.val.headers.val["ETag"] = etag_value
        }

        // Check if client sent If-None-Match header
        let if_none_match = ctx.get_header("If-None-Match")

        match if_none_match {
          Some(client_etag) => {
            // Get the current ETag (either set by handler or computed)
            let current_etag = ctx.res.val.headers.val.get("ETag")
            match current_etag {
              Some(etag_value) =>
                // Compare ETags (handle both weak and strong comparison)
                if etags_match(etag_value, client_etag) {
                  // 304 Not Modified
                  ctx.set_status(304)
                  ctx.res.val.body.val = None
                  // Remove body-related headers for 304
                  ignore(Map::remove(ctx.res.val.headers.val, "Content-Length"))
                }
              None => ()
            }
          }
          None => ()
        }
      }
      None => ()
    }
  }
}

///|
/// Generate ETag value from body content
fn compute_etag(body : String, weak : Bool) -> String {
  // In production, this would use a real hash function
  // For now, use a simple approach based on content length and checksum
  let len = String::length(body)
  let checksum = simple_checksum(body)

  let etag_raw = Int::to_string(len) + "-" + checksum

  if weak {
    "W/\"" + etag_raw + "\""
  } else {
    "\"" + etag_raw + "\""
  }
}

///|
/// Simple checksum for string (placeholder for real hash)
fn simple_checksum(data : String) -> String {
  // Simple hash: sum of all character codes
  // This is NOT cryptographically secure, just for demonstration
  let sum : Ref[Int] = { val: 0 }
  let chars = String::to_array(data)
  let len = Array::length(chars)
  for i in 0..<len {
    let ch = Array::get(chars, i).unwrap()
    sum.val = sum.val + ch.to_int()
  }
  // Add length to make it more unique
  sum.val = sum.val + String::length(data)
  Int::to_string(sum.val)
}

///|
/// Check if two ETags match
/// Supports both weak and strong comparison
pub fn etags_match(etag1 : String, etag2 : String) -> Bool {
  // Remove W/ prefix and quotes for comparison
  // Simple approach: just compare the raw values
  let raw1 = extract_etag_value(etag1)
  let raw2 = extract_etag_value(etag2)
  raw1 == raw2
}

///|
/// Extract raw ETag value (remove W/ and quotes)
fn extract_etag_value(etag : String) -> String {
  let without_w = String::replace(etag, old="W/", new="")
  String::replace(without_w, old="\"", new="")
}

///|
/// Generate ETag for static content (for use in handlers)
///
/// Example:
/// ```moonbit nocheck
/// let etag = @middleware.generate_etag_for_file(content, false)
/// ctx.res.headers["ETag"] = etag
/// ```
pub fn generate_etag_for_content(content : String, weak : Bool) -> String {
  compute_etag(content, weak)
}

///|
/// Validate If-None-Match header against current ETag
/// Returns true if client's cached version is still valid (304 response)
pub fn is_not_modified(ctx : @halo.Context, current_etag : String) -> Bool {
  match ctx.get_header("If-None-Match") {
    Some(client_etag) => etags_match(current_etag, client_etag)
    None => false
  }
}

///|
/// Set cache-related headers for optimal caching
pub fn set_cache_headers(
  ctx : @halo.Context,
  max_age : Int,
  public : Bool,
) -> Unit {
  let cache_control = if public {
    "public, max-age=" + Int::to_string(max_age)
  } else {
    "private, max-age=" + Int::to_string(max_age)
  }
  ctx.res.val.headers.val["Cache-Control"] = cache_control
}

///|
/// Helper to create etag options for testing
pub fn make_etag_options(
  weak : Bool,
  min_size : Int,
  algorithm : String,
) -> EtagOptions {
  { weak, min_size, algorithm }
}
