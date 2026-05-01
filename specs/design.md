# Halo — Architecture Design

## 1. Overview

Halo is a modern web framework for MoonBit, inspired by Koa's middleware onion model, built on MoonBit's native async runtime.

**Core Philosophy:**
- Simple over configurable
- Composition over inheritance
- Streaming over buffering
- Structured concurrency over callbacks

---

## 2. Architecture

### 2.1 Overall Architecture

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
│                   halo/http                              │
│         (Request, Response, Server — wraps async)        │
├─────────────────────────────────────────────────────────┤
│              moonbitlang/async/http|socket                │
│                (Native HTTP/Socket primitives)            │
└─────────────────────────────────────────────────────────┘
```

### 2.2 Module Dependency Graph

```
                    ┌──────────────┐
                    │  halo/http   │────── depends on ──────► moonbitlang/async/http
                    │  (HTTP层)    │                          moonbitlang/async/socket
                    └──────┬───────┘
                           │  imports
                           ▼
                    ┌──────────────┐
                    │    halo      │
                    │  (核心层)     │
                    └──────┬───────┘
                           │
          ┌────────────────┼────────────────┐
          │                │                │
          ▼                ▼                ▼
   ┌────────────┐   ┌────────────┐   ┌────────────┐
   │ middleware  │   │   router   │   │  helper    │
   │  (中间件)   │   │   (路由)    │   │  (辅助)    │
   └────────────┘   └────────────┘   └────────────┘
                          │
                          ▼
                   ┌──────────────┐
                   │   examples   │
                   └──────────────┘
```

### 2.3 Key Design Change (v0.6)

**Before (v0.5):** `halo` 直接依赖 `moonbitlang/async/http|socket`，`halo/http` 是死代码。

```
moonbitlang/async/http|socket
     ▲
     │  direct import
     │
   halo        halo/http (dead code, unused)
```

**After (v0.6):** `halo/http` 包装 `moonbitlang/async`，`halo` 只依赖 `halo/http`。

```
moonbitlang/async/http|socket
     ▲
     │  wrapped by
     │
  halo/http  ──── defines ───► Request, Response, Server
     ▲
     │  imported by
     │
   halo      ──── uses ────► Context { req: @http.Request, res: Ref[@http.Response] }
```

**Rationale:**
- `halo/http` 是 `moonbitlang/async/http` 的唯一包装层，屏蔽底层细节
- `halo`（核心框架）不直接依赖 async 库，只依赖自己抽象的 `halo/http`
- 如果将来切换底层 HTTP 实现，只改 `halo/http` 即可
- 层次清晰，职责单一

---

## 3. Module Design

### 3.1 `halo/http` — HTTP Abstraction Layer

**Responsibility:** Wrap `moonbitlang/async/http` and `moonbitlang/async/socket`, define Halo's own HTTP-level types.

**Files:**
- `request.mbt` — `Request` struct (method, path, headers, body) + `from_async()` conversion
- `response.mbt` — `Response` struct (status, headers, body) + `send()` to connection
- `server.mbt` — `Server` wrapper around `@async_http.Server`
- `moon.pkg` — imports `moonbitlang/async/http` and `moonbitlang/async/socket`

**No dependency on `halo` core.** This is a fundamental design rule — `halo/http` is independent and could theoretically be used standalone.

### 3.2 `halo` — Framework Core

**Responsibility:** Define the middleware system, types, and app infrastructure. Depends on `halo/http` for HTTP types and server.

**Files:**
- `types.mbt` — `Context`, `Next`, `Middleware` type definitions. Context references `@http.Request` and `@http.Response` (from `halo/http`).
- `context.mbt` — Context helper methods (`set_body`, `set_status`, etc.) and testing helpers (`make_context`, `make_next`, etc.).
- `compose.mbt` — Onion model middleware composition (unchanged).
- `app.mbt` — `App` struct, `mount()` middleware registration, `callback()`, `listen()`.

**Key Design Decisions:**
- `add_middleware()` renamed to `mount()` (Koa-compatible API)
- `mount()` returns `App` for chaining
- `App::listen()` delegates entirely to `@http.Server`
- No direct reference to `moonbitlang/async` anywhere in this layer

### 3.3 `halo/middleware` — Built-in Middleware

Unchanged in structure — each middleware is a file, all export factory functions returning `@halo.Middleware`.

### 3.4 `halo/router` — Router Middleware

Unchanged — router is just middleware. `Router::to_middleware()` returns `@halo.Middleware`.

### 3.5 `halo/helper` — Helper Utilities

Unchanged — provides utility functions like SSE helpers using `@halo.Context`.

---

## 4. Type Definitions

### 4.1 `halo/http` Types

```moonbit
// halo/http/request.mbt
pub struct Request {
  http_method: String
  path: String
  headers: Map[String, String]
  body: String?
}

// halo/http/response.mbt
pub struct Response {
  status: Ref[Int]
  headers: Ref[Map[String, String]]
  body: Ref[String?]
}

// halo/http/server.mbt
pub struct Server {
  address: String  // stored as string, parsed in run_forever (async context)
}
```

### 4.2 `halo` Core Types

```moonbit
// halo/types.mbt
pub struct Context {
  req: Request         // = @http.Request from halo/http
  res: Ref[Response]   // = @http.Response from halo/http
  state: Map[String, String]
}

pub type Next = () -> Unit
pub type Middleware = (Context, Next) -> Unit
```

### 4.3 Context Methods

```moonbit
// Convenience methods on Context
impl Context {
  fn set_body(self, body: String) -> Unit
  fn set_status(self, status: Int) -> Unit
  fn set_json(self, json_str: String) -> Unit
  fn get_header(self, name: String) -> String?
  fn get_header_or(self, name: String, default: String) -> String
  fn has_header(self, name: String) -> Bool
}
```

---

## 5. API Design

### 5.1 App API (Koa-compatible)

```moonbit
// Create app
let app = @halo.App::new()

// Register middleware — mount() replaces add_middleware()
app.mount(@middleware.logger())
app.mount(@middleware.cors_allow_all())
app.mount(router.to_middleware())

// Start server
app.listen(":3000")  // or app.listen("127.0.0.1:3000")
```

### 5.2 `App::mount()` Method

```moonbit
pub fn App::use(self : App, mw : @halo.Middleware) -> App {
  let middlewares = self.middlewares
  middlewares.push(mw)
  { middlewares, }
}
```

Returns `App` for method chaining (consistent with router API).

### 5.3 `App::listen()` — Delegates to `@http.Server`

```moonbit
pub async fn App::listen(self : App, address : String) -> Unit {
  let handler = self.callback()
  let server = @http.Server::new(address)
  server.run_forever(handler)
}
```

### 5.4 `App::callback()` — Returns Handler

```moonbit
pub fn App::callback(self : App) -> (@http.Request) -> @http.Response {
  let composed = compose(self.middlewares)
  fn(req : @http.Request) -> @http.Response {
    let ctx = make_context_with_request(req)
    composed(ctx, make_next())
    ctx.res.val
  }
}
```

---

## 6. Request Lifecycle

```
HTTP Request (from client)
    │
    ▼
@async_http.Server            moonbitlang/async receives connection
    │
    ▼
@http.Request::from_async()   halo/http converts to Halo Request
    │
    ▼
App::callback()                halo creates Context, runs middleware chain
    │
    ▼
Middleware[0].before
    │
    ▼
Middleware[1].before
    │
    ▼
... → Handler
    │
    ▼
Middleware[1].after
    │
    ▼
Middleware[0].after
    │
    ▼
Response (from middleware chain)
    │
    ▼
@http.Response::send()         halo/http sends response to connection
    │
    ▼
HTTP Response (to client)
```

---

## 7. Module Interface Mapping

### 7.1 `halo/http` Public API

```moonbit
// request.mbt
pub struct Request
pub fn Request::new(http_method, path, headers, body) -> Request
pub fn from_async(raw: @async_http.Request) -> Request

// response.mbt
pub struct Response
pub fn Response::new() -> Response
pub fn Response::new_with(status, headers, body) -> Response
pub async fn Response::send(self, conn: @async_http.ServerConnection) -> Unit

// server.mbt
pub struct Server
pub fn Server::new(address: String) -> Server
pub async fn Server::run_forever(self, handler: (Request) -> Response) -> Unit
```

### 7.2 `halo` Public API

```moonbit
// types.mbt
pub struct Context { req: @http.Request, res: Ref[@http.Response], state: Map[String, String] }
pub type Next = () -> Unit
pub type Middleware = (Context, Next) -> Unit

// Context methods
pub fn Context::set_body(self, body: String) -> Unit
pub fn Context::set_status(self, status: Int) -> Unit
pub fn Context::set_json(self, json_str: String) -> Unit
pub fn Context::get_header(self, name: String) -> String?
pub fn Context::get_header_or(self, name: String, default: String) -> String
pub fn Context::has_header(self, name: String) -> Bool

// Testing helpers
pub fn make_context() -> Context
pub fn make_next() -> Next
pub fn make_request(http_method, path, headers, body) -> @http.Request
pub fn make_response(status, headers, body) -> @http.Response
pub fn make_context_with_request(req: @http.Request) -> Context

// compose.mbt
pub fn compose(middlewares: Array[Middleware]) -> Middleware

// app.mbt
pub struct App { middlewares: Array[Middleware] }
pub fn App::new() -> App
pub fn App::use(self, mw: Middleware) -> App
pub fn App::middleware_count(self) -> Int
pub fn App::callback(self) -> (@http.Request) -> @http.Response
pub async fn App::listen(self, address: String) -> Unit
```

---

## 8. Error Handling Strategy

TODO: Improve `error_handler` middleware to properly catch panics.

Current: `error_handler` is a no-op middleware that just invokes next() without try-catch.
Target: In future versions, wrap `next()` in try-catch, return standardized JSON error responses.

---

## 9. Performance Considerations

- Middleware chain is built once at startup (`compose()` is called once in `callback()`)
- `Ref` for Response allows mutation through shared reference
- No dynamic dispatch — middleware stack is an `Array` of closures
- `Server::run_forever` is `async` — the runtime handles concurrency
- All types are stack-allocated, no heap allocations for request/response objects

---

## 10. Future Considerations

- **Streaming bodies**: Add `body_stream` field to Response for SSE/large payloads
- **Typed state**: Type-safe `ctx.state` instead of `Map[String, String]`
- **HTTP/2**: Support when `moonbitlang/async` adds it
- **Better error handling**: First-class error handling middleware with try-catch
