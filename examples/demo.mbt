// examples/demo.mbt
// Demo application showcasing Halo v0.3 features

///|
fn main {
  let app = @halo.App::new()

  // Core middleware
  ignore(app.add_middleware(@middleware.logger()))
  ignore(app.add_middleware(@middleware.error_handler()))
  ignore(app.add_middleware(@middleware.cors_allow_all()))

  // Bearer Token Authentication (optional)
  // Protects all routes except /public/* and /health
  // ignore(app.add_middleware(@middleware.bearer_auth(fn(token) {
  //   // Validate token - replace with your own logic
  //   token == "secret-token"
  // })))

  // Static files (optional)
  // ignore(app.add_middleware(@middleware.static_files("./public")))

  // Router with path parameters and wildcards
  let router = @router.Router::new()
    .get("/", fn(ctx, _) { ctx.set_body("Hello from Halo!") })
    .get("/json", fn(ctx, _) { ctx.set_json("{\"message\": \"Hello JSON\"}") })
    .get("/headers", fn(ctx, _) {
      // Example: getting request headers
      let user_agent = ctx.get_header_or("User-Agent", "unknown")
      let has_auth = ctx.has_header("Authorization")
      let auth_header = ctx.get_header("Authorization")
      let auth_value = match auth_header {
        Some(v) => v
        None => "not provided"
      }
      let body = "User-Agent: " + user_agent + "\nHas Authorization: " + (if has_auth { "yes" } else { "no" }) + "\nAuth Header: " + auth_value
      ctx.set_body(body)
    })
    .get("/public/info", fn(ctx, _) {
      // Public endpoint - not protected by auth middleware
      ctx.set_json("{\"message\": \"This is public info\"}")
    })
    .get("/protected", fn(ctx, _) {
      // Protected endpoint - requires valid Bearer token
      let token = @middleware.get_bearer_token(ctx)
      match token {
        Some(t) => ctx.set_json("{\"message\": \"Access granted\", \"token\": \"" + t + "\"}")
        None => ctx.set_json("{\"message\": \"No token found\"}")
      }
    })
    .get("/user/:id", fn(ctx, _) {
      let user_id = @router.param(ctx, "id")
      match user_id {
        Some(id) => ctx.set_body("User: " + id)
        None => {
          ctx.set_status(400)
          ctx.set_body("Missing user id")
        }
      }
    })
    .get("/files/:path*", fn(ctx, _) {
      let path = @router.param(ctx, "path")
      match path {
        Some(p) => ctx.set_body("File: " + p)
        None => {
          ctx.set_status(404)
          ctx.set_body("File not found")
        }
      }
    })
    .post("/api/data", fn(ctx, _) { ctx.set_body("Data created") })
    .handle_404(fn(ctx) {
      ctx.set_status(404)
      ctx.set_body("Route not found")
    })

  ignore(app.add_middleware(router.to_middleware()))

  println("Starting Halo server on :3000")
  app.listen(":3000")
}
