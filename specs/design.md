# Halo v0.1 System Design

## 1. Overview

Halo 是一个基于 MoonBit 的现代 Web 框架，采用 Koa 风格的 Middleware 洋葱模型。

**核心定位：**
- 简洁（像 Koa）
- 高性能（MoonBit 编译优化 + 原生 async）
- Structured Concurrency（结构化并发）

---

## 2. Architecture

### 2.1 整体架构

```
┌─────────────────────────────────────────────────────────┐
│                      Application                         │
│                         (App)                            │
├─────────────────────────────────────────────────────────┤
│                   Middleware Stack                       │
│  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐    │
│  │ Logger  │→ │  Auth   │→ │ Router  │→ │ Handler │    │
│  └────┬────┘  └────┬────┘  └────┬────┘  └────┬────┘    │
│       ↑           ↑           ↑           ↑            │
│       └───────────┴───────────┴───────────┘            │
│                    Onion Model                          │
├─────────────────────────────────────────────────────────┤
│                      Context                             │
│            (req, res, state per request)                 │
├─────────────────────────────────────────────────────────┤
│                   HTTP Server Wrapper                    │
│              (MoonBit native HTTP primitive)             │
└─────────────────────────────────────────────────────────┘
```

### 2.2 请求生命周期

```
Request → Middleware[0].before
        → Middleware[1].before
        → Middleware[2].before
        → Handler
        → Middleware[2].after
        → Middleware[1].after
        → Middleware[0].after
        → Response
```

---

## 3. Module Design

### 3.1 Module Dependency Graph

```
                    ┌─────────┐
                    │  App    │
                    └────┬────┘
                         │
         ┌───────────────┼───────────────┐
         │               │               │
         ▼               ▼               ▼
   ┌──────────┐   ┌──────────┐   ┌──────────┐
   │ Compose  │   │ Context  │   │  Server  │
   └────┬─────┘   └────┬─────┘   └────┬─────┘
        │              │              │
        │              │              │
        ▼              ▼              ▼
   ┌─────────────────────────────────────┐
   │            Types                     │
   │  (Request, Response, Middleware)     │
   └─────────────────────────────────────┘
```

### 3.2 Module Responsibilities

| Module | Responsibility |
|--------|----------------|
| `types.mb` | Core type definitions |
| `compose.mb` | Middleware composition engine |
| `app.mb` | Application entry point, middleware registration |
| `context.mb` | Request/Response context encapsulation |
| `http/server.mb` | HTTP server lifecycle |
| `http/request.mb` | Request wrapper |
| `http/response.mb` | Response wrapper |

---

## 4. Interface Definitions

### 4.1 Types

```moonbit
// Core types
type Next = fn() -> Future[Unit]
type Middleware = fn(Context, Next) -> Future[Unit]

struct Request {
  method: String,
  path: String,
  headers: Map[String, String],
  body: Option[String],
}

struct Response {
  status: Int,
  headers: Map[String, String],
  body: Option[String],
  body_stream: Option[Stream[String]],
}

struct Context {
  req: Request,
  res: Response,
  state: Map[String, Any],
}
```

### 4.2 App Interface

```moonbit
struct App {
  middlewares: List[Middleware],
}

impl App {
  fn new() -> Self
  fn use(self, mw: Middleware) -> Self
  fn listen(self, address: String) -> Unit
}
```

### 4.3 Context Interface

```moonbit
impl Context {
  fn new(req: Request) -> Self
  fn set_status(self, status: Int) -> Unit
  fn set_body(self, body: String) -> Unit
  fn set_json(self, data: Json) -> Unit
}
```

### 4.4 Compose Interface

```moonbit
fn compose(middlewares: List[Middleware]) -> Middleware
// Returns a single middleware that executes the chain
```

---

## 5. Key Design Decisions

### 5.1 Middleware Signature

**Decision:** `fn(Context, Next) -> Future[Unit]`

**Rationale:**
- Context provides request/response encapsulation
- Next as closure enables onion model
- Future[Unit] for async composition

### 5.2 Onion Model Implementation

**Approach:** Right-to-left composition building

```
compose([mw1, mw2, mw3]) =
  mw1(() => mw2(() => mw3(() => final_next)))
```

Each middleware wraps the next, creating nested execution.

### 5.3 Context vs Direct Request/Response

**Decision:** Encapsulate in Context struct

**Rationale:**
- Single object passed through middleware chain
- State map for cross-middleware data sharing
- Clean API surface

### 5.4 Response Handling

**Decision:** Support both buffered (text/json) and streaming

```moonbit
struct Response {
  body: Option[String],       // Buffered
  body_stream: Option[Stream], // Streaming
}
```

---

## 6. Data Flow

### 6.1 Request Processing

```
┌──────────────┐
│ HTTP Request │
└──────┬───────┘
       │
       ▼
┌──────────────┐
│ wrap_request │ → Request {method, path, headers, body}
└──────┬───────┘
       │
       ▼
┌──────────────┐
│ Context::new │ → Context {req, res, state}
└──────┬───────┘
       │
       ▼
┌──────────────┐
│   compose    │ → Execute middleware chain
└──────┬───────┘
       │
       ▼
┌──────────────┐
│ apply_to_    │ → Write to HTTP Response
│   response   │
└──────────────┘
```

### 6.2 Middleware Execution Flow

```
compose([logger, auth, router])

Execution:
  logger.before
    auth.before
      router (handler)
    auth.after
  logger.after
```

---

## 7. Error Handling Strategy

### 7.1 Error Propagation

- Errors bubble up through middleware chain
- Final error handler middleware catches all

### 7.2 Error Handler Middleware

```moonbit
let error_handler = fn(ctx: Context, next: Next) async {
  try {
    next()
  } catch err {
    ctx.set_status(500)
    ctx.set_json({"error": err.message})
  }
}

// Must be first middleware
app.use(error_handler)
```

---

## 8. Performance Considerations

### 8.1 Zero-Cost Abstractions

- Middleware chain built once at startup
- No runtime type checking
- Direct function calls (no reflection)

### 8.2 Streaming Support

- Large responses use Stream, not buffered String
- Prevents memory issues for big payloads

### 8.3 Async Efficiency

- MoonBit compiled async (no Promise overhead)
- Structured concurrency for cancellation

---

## 9. Extension Points

### 9.1 Custom Middleware

Users can write any middleware:

```moonbit
let cors = fn(ctx: Context, next: Next) async {
  ctx.res.headers["Access-Control-Allow-Origin"] = "*"
  next()
}
```

### 9.2 Router (v0.2)

Router is just middleware:

```moonbit
fn router(routes: Map[String, Handler]) -> Middleware {
  fn(ctx: Context, next: Next) async {
    match routes.get(ctx.req.path) {
      Some(h) => h(ctx),
      None => next(),
    }
  }
}
```

### 9.3 Future Adapters

- WASM adapter (edge runtimes)
- Different HTTP backends

---

## 10. API Usage Example

```moonbit
use halo/app

fn main {
  let app = App::new()

  // Logger middleware
  app.use(fn(ctx, next) async {
    println("{ctx.req.method} {ctx.req.path}")
    next()
    println("Response: {ctx.res.status}")
  })

  // Simple router
  app.use(fn(ctx, next) async {
    match (ctx.req.method, ctx.req.path) {
      ("GET", "/") => ctx.set_body("Hello"),
      ("GET", "/json") => ctx.set_json({"msg": "Hi"}),
      _ => {
        ctx.set_status(404)
        ctx.set_body("Not Found")
      }
    }
  })

  app.listen(":3000")
}
```
