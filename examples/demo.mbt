// examples/demo.mbt

fn main {
  let app = @halo.App::new()

  // Logger middleware
  ignore(app.use(fn(ctx, next) {
    println("{ctx.req.http_method} {ctx.req.path}")
    next()
    println("Response: {ctx.res.val.status.val}")
  }))

  // Simple router
  ignore(app.use(fn(ctx, _) {
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
