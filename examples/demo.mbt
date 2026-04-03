// examples/demo.mbt
// Demo application showcasing Halo v0.3 features

///|
fn main {
  let app = @halo.App::new()

  // Core middleware
  ignore(app.add_middleware(@middleware.logger()))
  ignore(app.add_middleware(@middleware.error_handler()))
  ignore(app.add_middleware(@middleware.cors_allow_all()))

  // Static files (optional)
  // ignore(app.add_middleware(@middleware.static_files("./public")))

  // Router with path parameters and wildcards
  let router = @router.Router::new()
    .get("/", fn(ctx, _) { ctx.set_body("Hello from Halo!") })
    .get("/json", fn(ctx, _) { ctx.set_json("{\"message\": \"Hello JSON\"}") })
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
