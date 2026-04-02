// examples/demo.mbt

fn main {
  let app = @halo.App::new()

  // Logger middleware
  ignore(app.add_middleware(fn(_ctx, next) {
    println("Request received")
    next()
    println("Response sent")
  }))

  // Simple router
  ignore(app.add_middleware(fn(ctx, _) {
    if ctx.req.path == "/" {
      ctx.set_body("Hello from Halo!")
    } else if ctx.req.path == "/json" {
      ctx.set_json("{\"message\": \"Hello JSON\"}")
    } else {
      ctx.set_status(404)
      ctx.set_body("Not Found")
    }
  }))

  println("Starting Halo server on :3000")
  app.listen(":3000")
}
