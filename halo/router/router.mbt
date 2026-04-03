// halo/router/router.mbt
// Router core - HTTP method routing and middleware integration

/// Router struct - manages routes and acts as middleware
pub struct Router {
  routes : Array[Route]
  not_found_handler : Option[(@halo.Context) -> Unit]
}

/// Create a new Router instance
pub fn Router::new() -> Router {
  { routes: [], not_found_handler: None }
}

/// Register a GET route
pub fn Router::get(self : Router, path : String, handler : Handler) -> Router {
  let route = Route::new("GET", path, handler)
  let routes = self.routes
  routes.push(route)
  { routes: routes, not_found_handler: self.not_found_handler }
}

/// Register a POST route
pub fn Router::post(self : Router, path : String, handler : Handler) -> Router {
  let route = Route::new("POST", path, handler)
  let routes = self.routes
  routes.push(route)
  { routes: routes, not_found_handler: self.not_found_handler }
}

/// Register a PUT route
pub fn Router::put(self : Router, path : String, handler : Handler) -> Router {
  let route = Route::new("PUT", path, handler)
  let routes = self.routes
  routes.push(route)
  { routes: routes, not_found_handler: self.not_found_handler }
}

/// Register a PATCH route
pub fn Router::patch(self : Router, path : String, handler : Handler) -> Router {
  let route = Route::new("PATCH", path, handler)
  let routes = self.routes
  routes.push(route)
  { routes: routes, not_found_handler: self.not_found_handler }
}

/// Register a DELETE route
pub fn Router::delete(self : Router, path : String, handler : Handler) -> Router {
  let route = Route::new("DELETE", path, handler)
  let routes = self.routes
  routes.push(route)
  { routes: routes, not_found_handler: self.not_found_handler }
}

/// Register an OPTIONS route
pub fn Router::options(self : Router, path : String, handler : Handler) -> Router {
  let route = Route::new("OPTIONS", path, handler)
  let routes = self.routes
  routes.push(route)
  { routes: routes, not_found_handler: self.not_found_handler }
}

/// Register a HEAD route
pub fn Router::head(self : Router, path : String, handler : Handler) -> Router {
  let route = Route::new("HEAD", path, handler)
  let routes = self.routes
  routes.push(route)
  { routes: routes, not_found_handler: self.not_found_handler }
}

/// Register a route that matches any method
pub fn Router::any(self : Router, path : String, handler : Handler) -> Router {
  let route = Route::new("*", path, handler)
  let routes = self.routes
  routes.push(route)
  { routes: routes, not_found_handler: self.not_found_handler }
}

/// Set custom 404 handler
pub fn Router::handle_404(self : Router, handler : (@halo.Context) -> Unit) -> Router {
  { routes: self.routes, not_found_handler: Some(handler) }
}

/// Find matching route for the given method and path
fn Router::find(self : Router, http_method : String, path : String) -> Option[(Route, Map[String, String])] {
  let routes = self.routes
  let routes_len = Array::length(routes)
  let mut i = 0

  while i < routes_len {
    let route = routes[i]
    if route.matches_method(http_method) {
      let match_result = route.do_match(path)
      if match_result.matched {
        return Some((route, match_result.params))
      }
    }
    i = i + 1
  }
  None
}

/// Convert router to middleware
pub fn Router::to_middleware(self : Router) -> @halo.Middleware {
  fn(ctx : @halo.Context, next : @halo.Next) {
    let http_method = ctx.req.http_method
    let path = ctx.req.path

    match self.find(http_method, path) {
      Some((route, params)) => {
        // Store params in context state for handler access
        let keys : Array[String] = []
        for k in Map::keys(params) {
          keys.push(k)
        }
        let keys_len = Array::length(keys)
        let mut j = 0
        while j < keys_len {
          let key = keys[j]
          ctx.state["param:" + key] = params[key]
          j = j + 1
        }
        ctx.state["matched_route"] = route.pattern
        (route.handler)(ctx, next)
      }
      None => {
        // No route matched - use custom 404 or return 404
        match self.not_found_handler {
          Some(handler) => {
            handler(ctx)
          }
          None => {
            ctx.res.val.status.val = 404
            ctx.res.val.body.val = Some("Not Found")
          }
        }
      }
    }
  }
}

/// Helper to get route parameter from context state
pub fn param(ctx : @halo.Context, name : String) -> Option[String] {
  ctx.state.get("param:" + name)
}
