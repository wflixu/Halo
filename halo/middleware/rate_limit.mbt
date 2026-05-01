// halo/middleware/rate_limit.mbt
// Rate limiting middleware

///|
/// Rate limit strategy
pub enum RateLimitStrategy {
  IpBased
  UserBased
  // HeaderBased - reserved for future use
}

///|
/// Rate limit options
pub struct RateLimitOptions {
  /// Maximum number of requests allowed in the window
  max_requests : Int
  /// Time window in seconds
  window_seconds : Int
  /// Limit strategy (default: IpBased)
  strategy : RateLimitStrategy
  /// Custom error message
  error_message : String
  /// Status code for rate limit exceeded (default: 429)
  status_code : Int
}

///|
/// Default rate limit options (100 requests per minute, IP-based)
fn default_rate_limit_options() -> RateLimitOptions {
  {
    max_requests: 100,
    window_seconds: 60,
    strategy: IpBased,
    error_message: "Too many requests",
    status_code: 429,
  }
}

///|
/// Rate limit state - tracks request counts
priv struct RateLimitState {
  /// Request count
  count : Ref[Int]
  /// Window start time (Unix timestamp in seconds)
  window_start : Ref[Int]
}

///|
/// Global store for rate limit state (per key)
/// In production, this should be backed by Redis or similar
let rate_limit_store : Ref[Map[String, RateLimitState]] = { val: Map::new() }

///|
/// Create IP-based rate limit middleware
///
/// Example:
/// ```moonbit nocheck
/// // 100 requests per minute per IP
/// app.use(@middleware.rate_limit_ip_based(100, 60))
/// ```
pub fn rate_limit_ip_based(
  max_requests : Int,
  window_seconds : Int,
) -> @halo.Middleware {
  let opts = default_rate_limit_options()
  rate_limit_with_options({
    max_requests,
    window_seconds,
    strategy: opts.strategy,
    error_message: opts.error_message,
    status_code: opts.status_code,
  })
}

///|
/// Create user-based rate limit middleware
///
/// Example:
/// ```moonbit nocheck
/// // 1000 requests per hour per user
/// app.use(@middleware.rate_limit_user_based(1000, 3600))
/// ```
pub fn rate_limit_user_based(
  max_requests : Int,
  window_seconds : Int,
) -> @halo.Middleware {
  let opts = default_rate_limit_options()
  rate_limit_with_options({
    max_requests,
    window_seconds,
    strategy: UserBased,
    error_message: opts.error_message,
    status_code: opts.status_code,
  })
}

///|
/// Create rate limit middleware with custom options
///
/// Example:
/// ```moonbit nocheck
/// app.use(@middleware.rate_limit_with_options({
///   max_requests: 50,
///   window_seconds: 60,
///   strategy: IpBased,
///   error_message: "Rate limit exceeded, please slow down",
///   status_code: 429,
/// }))
/// ```
pub fn rate_limit_with_options(options : RateLimitOptions) -> @halo.Middleware {
  fn(ctx : @halo.Context, next : @halo.Next) {
    // Get identifier based on strategy
    let identifier = get_identifier(ctx, options.strategy)

    // Check rate limit
    if check_rate_limit(identifier, options) {
      // Within limit, continue
      next()
    } else {
      // Rate limit exceeded
      ctx.set_status(options.status_code)
      ctx.set_json(
        "{ \"error\": \"" +
        options.error_message +
        "\", \"retry_after\": " +
        Int::to_string(options.window_seconds) +
        " }",
      )
    }
  }
}

///|
/// Get identifier based on strategy
fn get_identifier(ctx : @halo.Context, strategy : RateLimitStrategy) -> String {
  match strategy {
    IpBased =>
      // Get IP from X-Forwarded-For or X-Real-IP header
      match ctx.get_header("X-Forwarded-For") {
        Some(ip) => {
          // X-Forwarded-For can contain multiple IPs, take the first one
          let ips = String::split(ip, ",")
          let arr = ips.to_array()
          if Array::length(arr) > 0 {
            arr[0].to_owned().to_string()
          } else {
            "unknown"
          }
        }
        None =>
          match ctx.get_header("X-Real-IP") {
            Some(ip) => ip.to_string()
            None => "unknown"
          }
      }
    UserBased =>
      // Try to get user ID from state (set by auth middleware)
      match ctx.state.get("user_id") {
        Some(user_id) => user_id
        None => "anonymous"
      }
  }
}

///|
/// Check if request is within rate limit
fn check_rate_limit(identifier : String, options : RateLimitOptions) -> Bool {
  let current_time = get_current_timestamp()
  let store = rate_limit_store.val

  match store.get(identifier) {
    Some(state) => {
      let window_start = state.window_start.val
      let count = state.count.val

      // Check if we're in a new window
      if current_time - window_start >= options.window_seconds {
        // Reset window
        state.count.val = 1
        state.window_start.val = current_time
        true
        // Same window, check count
      } else if count >= options.max_requests {
        false
      } else {
        state.count.val = count + 1
        true
      }
    }
    None => {
      // New identifier, create state
      let new_state : RateLimitState = {
        count: { val: 1 },
        window_start: { val: current_time },
      }
      let _ = Map::set(rate_limit_store.val, identifier, new_state)
      true
    }
  }
}

///|
/// Get current Unix timestamp in seconds
/// Note: Uses a simple counter as placeholder - replace with actual time API
fn get_current_timestamp() -> Int {
  // Placeholder: In production, use MoonBit's time API
  // For now, use a simple incrementing counter
  static_counter.val
}

///|
/// Static counter for timestamp placeholder
let static_counter : Ref[Int] = { val: 0 }

///|
/// Reset rate limit store (useful for testing)
pub fn reset_rate_limit_store() -> Unit {
  rate_limit_store.val = Map::new()
}

///|
/// Set current timestamp for testing
pub fn set_current_timestamp(ts : Int) -> Unit {
  static_counter.val = ts
}

///|
/// Advance current timestamp by seconds (for testing)
pub fn advance_timestamp(seconds : Int) -> Unit {
  static_counter.val = static_counter.val + seconds
}

///|
/// Get remaining requests for an identifier
pub fn get_remaining_requests(
  identifier : String,
  options : RateLimitOptions,
) -> Int {
  let current_time = get_current_timestamp()
  let store = rate_limit_store.val

  match store.get(identifier) {
    Some(state) => {
      let window_start = state.window_start.val
      let count = state.count.val

      if current_time - window_start >= options.window_seconds {
        options.max_requests
      } else {
        options.max_requests - count
      }
    }
    None => options.max_requests
  }
}

///|
/// Get rate limit headers to add to response
pub fn get_rate_limit_headers(
  identifier : String,
  options : RateLimitOptions,
) -> Map[String, String] {
  let remaining = get_remaining_requests(identifier, options)
  let headers = Map::new()
  headers["X-RateLimit-Limit"] = Int::to_string(options.max_requests)
  headers["X-RateLimit-Remaining"] = Int::to_string(remaining)
  headers["X-RateLimit-Reset"] = Int::to_string(
    get_current_timestamp() + options.window_seconds,
  )
  headers
}

///|
/// Helper to create rate limit options for testing
pub fn make_rate_limit_options(
  max_requests : Int,
  window_seconds : Int,
  strategy : RateLimitStrategy,
  _header_name : String,
  error_message : String,
  status_code : Int,
) -> RateLimitOptions {
  { max_requests, window_seconds, strategy, error_message, status_code }
}

///|
/// Get IpBased strategy variant
pub fn ip_based_strategy() -> RateLimitStrategy {
  IpBased
}

///|
/// Get UserBased strategy variant
pub fn user_based_strategy() -> RateLimitStrategy {
  UserBased
}
