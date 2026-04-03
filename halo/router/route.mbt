// halo/router/route.mbt
// Route definition and path matching

/// HTTP methods supported by the router
pub type HttpMethod = String

/// Handler function type - same as Middleware signature
pub type Handler = (@halo.Context, @halo.Next) -> Unit

/// A single route definition
pub struct Route {
  /// HTTP method (GET, POST, etc.)
  http_method : HttpMethod
  /// Path pattern (e.g., "/user/:id")
  pattern : String
  /// Handler function
  handler : Handler
  /// Parsed path segments for matching
  segments : Array[(String, Bool)]  // (segment, is_param)
  /// Has wildcard at end
  has_wildcard : Bool
  /// Wildcard param name if :param*
  wildcard_name : Option[String]
}

/// Create a new Route from pattern and handler
pub fn Route::new(http_method : String, pattern : String, handler : Handler) -> Route {
  let (segments, has_wildcard, wildcard_name) = parse_pattern(pattern)
  { http_method: http_method, pattern: pattern, handler: handler, segments: segments, has_wildcard: has_wildcard, wildcard_name: wildcard_name }
}

/// Parse path pattern into segments
fn parse_pattern(pattern : String) -> (Array[(String, Bool)], Bool, Option[String]) {
  let parts_iter = String::split(pattern, "/")
  let segments : Array[(String, Bool)] = []
  let mut has_wildcard = false
  let mut wildcard_name : Option[String] = None

  for part in parts_iter {
    let part_str = part.to_string()

    if part_str == "" {
      continue
    }

    if String::has_prefix(part_str, ":") {
      if String::has_suffix(part_str, "*") {
        let name = part_str[1:-1].to_string()
        segments.push((name, true))
        has_wildcard = true
        wildcard_name = Some(name)
      } else {
        let name = part_str[1:].to_string()
        segments.push((name, true))
      }
    } else if part_str == "*" {
      has_wildcard = true
      segments.push(("*", true))
    } else {
      segments.push((part_str, false))
    }
  }

  (segments, has_wildcard, wildcard_name)
}

/// Match result for a route
pub struct MatchResult {
  matched : Bool
  params : Map[String, String]
}

/// Create empty match result (no match)
pub fn MatchResult::none() -> MatchResult {
  { matched: false, params: Map::new() }
}

/// Create successful match with params
pub fn MatchResult::success(params : Map[String, String]) -> MatchResult {
  { matched: true, params: params }
}

/// Match a route against a request path
pub fn Route::do_match(self : Route, path : String) -> MatchResult {
  let path_iter = String::split(path, "/")
  let path_parts : Array[String] = []
  for p in path_iter {
    let s = p.to_string()
    if s != "" {
      path_parts.push(s)
    }
  }

  let params : Map[String, String] = Map::new()
  let mut path_idx = 0
  let parts_len = Array::length(path_parts)
  let segs = self.segments
  let segs_len = Array::length(segs)
  let mut i = 0

  while i < segs_len {
    let seg = segs[i]
    let segment = seg.0
    let is_param = seg.1

    // Check if this is a wildcard param (e.g., :param*)
    let is_wildcard_param = is_param && self.has_wildcard && self.wildcard_name != None

    if segment == "*" || is_wildcard_param {
      // Wildcard - capture rest of path
      let rest_parts : Array[String] = []
      let mut j = path_idx
      while j < parts_len {
        rest_parts.push(path_parts[j])
        j = j + 1
      }
      let rest = Array::join(rest_parts, "/")

      if segment == "*" {
        // Bare wildcard *
        if rest != "" {
          params["*"] = rest
          return MatchResult::success(params)
        }
        return MatchResult::none()
      } else {
        // Named wildcard :param*
        // Capture the param name from wildcard_name
        let param_name = match self.wildcard_name {
          Some(name) => name
          None => "*"  // fallback
        }
        params[param_name] = rest
        return MatchResult::success(params)
      }
    }

    if path_idx >= parts_len {
      if is_param && self.has_wildcard {
        return MatchResult::success(params)
      }
      return MatchResult::none()
    }

    let path_part = path_parts[path_idx]

    if is_param {
      params[segment] = path_part
      path_idx = path_idx + 1
    } else {
      if path_part != segment {
        return MatchResult::none()
      }
      path_idx = path_idx + 1
    }

    i = i + 1
  }

  if !self.has_wildcard && path_idx < parts_len {
    return MatchResult::none()
  }

  if path_idx >= parts_len || self.has_wildcard {
    MatchResult::success(params)
  } else {
    MatchResult::none()
  }
}

/// Check if route matches the given method
pub fn Route::matches_method(self : Route, http_method : String) -> Bool {
  self.http_method == http_method || self.http_method == "*"
}
