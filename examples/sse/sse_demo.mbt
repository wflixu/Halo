// examples/sse_demo.mbt
// Server-Sent Events (SSE) demo

///|
fn main {
  let app = @halo.App::new()

  // Core middleware
  ignore(app.add_middleware(@middleware.logger()))
  ignore(app.add_middleware(@middleware.cors_allow_all()))

  // SSE endpoint
  ignore(
    app.add_middleware(fn(ctx, _) {
      if ctx.req.path == "/events" {
        @helper.sse_set_headers(ctx)

        // Send initial connection message
        @helper.sse_send_event(ctx, "connected", "{\"status\": \"connected\"}")

        // Stream progress events
        let count = 5
        let mut i = 0
        while i < count {
          let data = "{\"count\": " + Int::to_string(i) + "}"
          @helper.sse_send_event(ctx, "progress", data)
          i = i + 1
        }

        // Send completion message
        @helper.sse_send_event(ctx, "complete", "{\"status\": \"done\"}")
        return
      }

      // HTML page with EventSource client
      if ctx.req.path == "/" {
        ignore(ctx.set_body(html_page()))
        return
      }

      // JSON API endpoint
      if ctx.req.path == "/api/info" {
        ignore(
          ctx.set_json("{\"name\": \"Halo SSE Demo\", \"version\": \"0.5\"}"),
        )
        return
      }

      ctx.set_status(404)
      ignore(ctx.set_body("Not Found"))
    }),
  )

  println("Starting Halo SSE demo server on :3000")
  println("Open http://localhost:3000 in browser to see SSE events")
  app.listen(":3000")
}

///|
/// HTML page with EventSource client
fn html_page() -> String {
  "<!DOCTYPE html><html><head><meta charset=\"UTF-8\"><title>Halo SSE Demo</title></head><body>" +
  "<h1>Halo SSE Demo</h1><p>Server-Sent Events demonstration</p>" +
  "<div id=\"events\">Connecting...</div>" +
  "<script>var e=document.getElementById('events'),h='';" +
  "var s=new EventSource('/events');" +
  "s.onopen=function(){h+='<p>Connected</p>';e.innerHTML=h;};" +
  "s.addEventListener('connected',function(ev){h+='<p>Server: '+ev.data+'</p>';e.innerHTML=h;});" +
  "s.addEventListener('progress',function(ev){h+='<p>Progress: '+ev.data+'</p>';e.innerHTML=h;});" +
  "s.addEventListener('complete',function(ev){h+='<p>Complete: '+ev.data+'</p>';e.innerHTML=h;});" +
  "</script></body></html>"
}
