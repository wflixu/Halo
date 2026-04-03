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

---

## 11. Built-in Middleware Ecosystem

Halo 提供开箱即用的内置中间件，覆盖 80% 的常见 Web 开发需求。

### 11.1 Middleware Layers

| Layer | Version | Middleware | Description |
|-------|---------|------------|-------------|
| **Core** | v0.3 | `logger`, `error_handler`, `cors`, `static` | 每个应用都需要 |
| **Common** | v0.4 | `body_parser`, `cookie`, `session`, `secure_headers` | 80% 应用需要 |
| **Advanced** | v0.5+ | `rate_limit`, `compression`, `etag`, `request_id`, `auth_jwt` | 高级场景 |

### 11.2 Middleware Directory Structure

```
halo/
├── middleware/              # 内置中间件集合
│   ├── moon.pkg
│   ├── logger.mbt           # 请求日志
│   ├── error_handler.mbt    # 统一错误处理
│   ├── cors.mbt             # 跨域资源共享
│   ├── static.mbt           # 静态文件服务
│   ├── body_parser.mbt      # 请求体解析
│   ├── cookie.mbt           # Cookie 解析
│   ├── session.mbt          # 会话管理
│   ├── secure_headers.mbt   # 安全响应头
│   ├── rate_limit.mbt       # 请求限流
│   └── compression.mbt      # 响应压缩
```

### 11.3 API Design Pattern

```moonbit
use halo/middleware

// 零配置默认使用
app.add_middleware(@middleware.logger())
app.add_middleware(@middleware.error_handler())
app.add_middleware(@middleware.cors())

// 自定义配置
app.add_middleware(@middleware.cors.allow_origins(["https://example.com"]))
app.add_middleware(@middleware.static("./public", prefix="/assets"))
app.add_middleware(@middleware.rate_limit.ip_based(100, 60))  // 100 次/分钟
```

### 11.4 Recommended Presets

**最小化 API 模板：**
```moonbit
let app = App::new()
app.add_middleware(@middleware.logger())
app.add_middleware(@middleware.error_handler())
app.add_middleware(@middleware.cors())
app.add_middleware(router)
```

**完整 Web 应用模板：**
```moonbit
let app = App::new()

// 基础中间件
app.add_middleware(@middleware.logger())
app.add_middleware(@middleware.error_handler())
app.add_middleware(@middleware.cors())
app.add_middleware(@middleware.secure_headers())

// 请求处理
app.add_middleware(@middleware.body_parser())
app.add_middleware(@middleware.cookie_parser())
app.add_middleware(@middleware.session())

// 静态文件
app.add_middleware(@middleware.static("./public"))

// 路由
app.add_middleware(router)
```

### 11.5 Design Principles

1. **零配置可用** - 默认配置就能用
2. **可组合** - 中间件可以叠加
3. **类型安全** - 返回类型明确
4. **性能优先** - 高频中间件（如 logger）要高效
5. **不依赖外部库** - 全部内置，避免依赖地狱

---

## 12. Server-Sent Events (SSE) Support

### 12.1 Overview

SSE (Server-Sent Events) 是一种单向服务器到客户端的实时通信协议，基于 HTTP，天然支持断线重连。

**使用场景：**
- 实时通知推送
- 股票行情/数据流
- 构建日志/进度实时更新
- AI 流式响应（如 LLM token 流）

### 12.2 API Design

```moonbit
use halo/helper/sse

// 方式 1: SSE Helper
app.add_middleware(@helper.sse.emit(ctx, "notification", "{\"msg\": \"Hello\"}"))

// 方式 2: Stream response
app.add_middleware(fn(ctx, next) {
  if ctx.req.path == "/stream" {
    @helper.sse.set_headers(ctx)  // 设置 SSE 响应头
    @helper.sse.send(ctx, "start", "{\"status\": \"connected\"}")
    
    // 流式发送事件
    for i in 1..10 {
      @helper.sse.send(ctx, "progress", "{\"count\": " + Int::to_string(i) + "}")
    }
    
    @helper.sse.send(ctx, "end", "{\"status\": \"complete\"}")
    return
  }
  next()
})
```

### 12.3 SSE Response Format

SSE 事件格式（每行一个字段，双换行分隔事件）：

```
event: notification
data: {"msg": "Hello"}

event: progress
data: {"count": 1}
id: 1
retry: 3000
```

### 12.4 Module Design

```
halo/
└── helper/
    ├── moon.pkg
    └── sse.mbt           # SSE helper functions
```

### 12.5 Core Functions

```moonbit
/// Set SSE response headers
/// Content-Type: text/event-stream
/// Cache-Control: no-cache
/// Connection: keep-alive
pub fn set_headers(ctx : Context) -> Unit

/// Send SSE event with default event type "message"
pub fn send(ctx : Context, data : String) -> Unit

/// Send SSE event with custom event type
pub fn send_event(ctx : Context, event : String, data : String) -> Unit

/// Send SSE event with ID (for reconnection)
pub fn send_with_id(ctx : Context, event : String, data : String, id : String) -> Unit

/// Send SSE event with retry interval (milliseconds)
pub fn send_with_retry(ctx : Context, event : String, data : String, retry_ms : Int) -> Unit

/// Flush response buffer (ensure client receives immediately)
pub fn flush(ctx : Context) -> Unit
```

### 12.6 Implementation Notes

1. **流式响应** - SSE 需要流式支持，Response 需要 body_stream 字段
2. **缓冲刷新** - 每次 send 后需要 flush 确保客户端立即收到
3. **长连接** - SSE 是长连接，需要保持连接不被中间件截断
4. **错误处理** - 客户端断线检测（可选）

### 12.7 Usage Example

```moonbit
// examples/sse_demo.mbt
use halo/app
use halo/helper/sse

fn main {
  let app = @halo.App::new()

  app.add_middleware(@middleware.logger())
  app.add_middleware(@middleware.cors_allow_all())

  // SSE endpoint
  app.add_middleware(fn(ctx, _) {
    if ctx.req.path == "/events" {
      @helper.sse.set_headers(ctx)
      @helper.flush(ctx)

      let count = 5
      let mut i = 0
      while i < count {
        let data = "{\"count\": " + Int::to_string(i) + "}"
        @helper.sse.send_event(ctx, "progress", data)
        @helper.flush(ctx)
        i = i + 1
      }

      @helper.sse.send_event(ctx, "end", "{\"status\": \"done\"}")
      return
    }

    // HTML page with EventSource
    if ctx.req.path == "/" {
      ctx.set_body(html_page())
      return
    }

    ctx.set_status(404)
  })

  app.listen(":3000")
}

fn html_page() -> String {
  \"\"\"
  <!DOCTYPE html>
  <html>
  <body>
    <div id="events"></div>
    <script>
      const es = new EventSource("/events");
      es.onmessage = (e) => {
        document.getElementById("events").innerHTML += e.data + "<br>";
      };
    </script>
  </body>
  </html>
  \"\"\"
}
```

### 12.8 Future Extensions

1. **SSE Middleware** - 自动管理连接生命周期
2. **Broadcast** - 多客户端广播支持
3. **Room/Channel** - 房间/频道订阅模式
4. **Reconnection** - 断线重连事件 ID 管理
