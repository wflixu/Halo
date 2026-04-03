// halo/helper/sse.mbt
// Server-Sent Events (SSE) helper functions

/// Set SSE response headers
/// Content-Type: text/event-stream
/// Cache-Control: no-cache
/// Connection: keep-alive
pub fn sse_set_headers(ctx : @halo.Context) -> Unit {
  let headers = ctx.res.val.headers.val
  headers["Content-Type"] = "text/event-stream"
  headers["Cache-Control"] = "no-cache"
  headers["Connection"] = "keep-alive"
  headers["Access-Control-Allow-Origin"] = "*"
}

/// Send SSE event with default event type "message"
pub fn sse_send(ctx : @halo.Context, data : String) -> Unit {
  sse_send_event(ctx, "message", data)
}

/// Send SSE event with custom event type
pub fn sse_send_event(ctx : @halo.Context, event : String, data : String) -> Unit {
  let event_line = "event: " + event
  let data_line = "data: " + data
  let message = event_line + "\n" + data_line + "\n\n"

  // Append to response body
  let existing = ctx.res.val.body.val
  match existing {
    Some(body) => {
      ctx.res.val.body.val = Some(body + message)
    }
    None => {
      ctx.res.val.body.val = Some(message)
    }
  }
}

/// Send SSE event with ID (for reconnection)
pub fn sse_send_with_id(ctx : @halo.Context, event : String, data : String, id : String) -> Unit {
  let event_line = "event: " + event
  let data_line = "data: " + data
  let id_line = "id: " + id
  let message = event_line + "\n" + data_line + "\n" + id_line + "\n\n"

  let existing = ctx.res.val.body.val
  match existing {
    Some(body) => {
      ctx.res.val.body.val = Some(body + message)
    }
    None => {
      ctx.res.val.body.val = Some(message)
    }
  }
}

/// Send SSE event with retry interval (milliseconds)
pub fn sse_send_with_retry(ctx : @halo.Context, event : String, data : String, retry_ms : Int) -> Unit {
  let event_line = "event: " + event
  let data_line = "data: " + data
  let retry_line = "retry: " + Int::to_string(retry_ms)
  let message = event_line + "\n" + data_line + "\n" + retry_line + "\n\n"

  let existing = ctx.res.val.body.val
  match existing {
    Some(body) => {
      ctx.res.val.body.val = Some(body + message)
    }
    None => {
      ctx.res.val.body.val = Some(message)
    }
  }
}

/// Send raw SSE message (all fields already formatted)
pub fn sse_send_raw(ctx : @halo.Context, message : String) -> Unit {
  let formatted = message + "\n\n"

  let existing = ctx.res.val.body.val
  match existing {
    Some(body) => {
      ctx.res.val.body.val = Some(body + formatted)
    }
    None => {
      ctx.res.val.body.val = Some(formatted)
    }
  }
}
