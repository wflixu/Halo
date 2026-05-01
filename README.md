# Halo

**Halo** is a modern middleware web framework for MoonBit, inspired by Koa but built for structured concurrency and streaming.

> A halo of middleware around every request.

[![CI](https://github.com/wflixu/Halo/actions/workflows/ci.yml/badge.svg)](https://github.com/wflixu/Halo/actions/workflows/ci.yml)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

## ✨ Features

- **Onion Middleware** - Elegant before → next → after composition
- **Native Async** - Compiler-level async runtime (no await/callback syntax)
- **Structured Concurrency** - Automatic error propagation, request-scoped lifecycle
- **Streaming First** - Responses are streams, not buffers
- **Composable** - Everything is middleware

## 🚀 Quick Start

### Installation

Add to your `moon.mod.json`:

```json
{
  "name": "your/module",
  "dependencies": {
    "wflixu/Halo": "*"
  }
}
```

### Hello World

```moonbit
use wflixu/Halo/halo
use wflixu/Halo/halo/middleware

async fn main {
  let app = @halo.App::new()

  // Logger middleware
  app.use(@middleware.logger())

  // Routes
  app.use(fn(ctx, _) {
    if ctx.req.path == "/" {
      ctx.set_body("Hello, Halo!")
    } else if ctx.req.path == "/json" {
      ctx.set_json("{\"msg\": \"Hello JSON\"}")
    } else {
      ctx.set_status(404)
      ctx.set_body("Not Found")
    }
  })

  app.listen(":3000")
}
```

## 📦 Built-in Middleware

Halo provides zero-config middleware for common web development needs:

```moonbit
use wflixu/Halo/halo
use wflixu/Halo/halo/middleware
use wflixu/Halo/halo/router

async fn main {
  let app = @halo.App::new()

  // Core middleware
  app.use(@middleware.logger())
  app.use(@middleware.error_handler())
  app.use(@middleware.cors_allow_all())
  app.use(@middleware.secure_headers())

  // Request parsing
  app.use(@middleware.body_parser())
  app.use(@middleware.cookie_parser())
  app.use(@middleware.session())

  // Static files
  app.use(@middleware.static_files("./public"))

  // Router
  let router = @router.Router::new()
    .get("/", fn(ctx, _) { ctx.set_body("Home") })
    .get("/user/:id", fn(ctx, _) {
      let id = @router.param(ctx, "id")
      ctx.set_body("User: " + id.val)
    })
    .post("/api/data", fn(ctx, _) {
      let json = @middleware.get_json(ctx)
      ctx.set_body("Data received")
    })

  app.use(router.to_middleware())

  app.listen(":3000")
}
```

### Available Middleware

| Middleware | Description |
|------------|-------------|
| `logger()` | Request logging |
| `error_handler()` | Unified error handling |
| `cors_allow_all()` / `cors_allow_origins([...])` | CORS support |
| `secure_headers()` | Security headers (X-Frame-Options, HSTS, etc.) |
| `body_parser()` | JSON/form body parsing |
| `cookie_parser()` | Cookie parsing |
| `session()` | Session management |
| `static_files(root)` | Static file serving |
| `request_id()` | Request tracing ID |
| `bearer_auth(...)` / `bearer_auth_with_options(...)` | Bearer Token authentication |
| `rate_limit_ip_based(...)` / `rate_limit_user_based(...)` | Rate limiting (IP/user-based) |
| `compression()` / `compression_with_options(...)` | Response compression (gzip/brotli) |
| `etag()` / `etag_with_options(...)` | ETag generation for HTTP caching |
| `timeout()` / `timeout_with_options(...)` | Request timeout with automatic cancellation |
| `jwt_auth(...)` / `jwt_auth_with_options(...)` | JWT token validation |
| `sse_*()` | Server-Sent Events helpers |

## 🗺️ Roadmap

| Version | Status | Features |
|---------|--------|----------|
| **v0.1** | ✅ | Core middleware engine, HTTP server, Context |
| **v0.2** | ✅ | Router with path params (`:id`) and wildcards (`*`, `:param*`) |
| **v0.3** | ✅ | Built-in middleware: logger, error_handler, cors, static |
| **v0.4** | ✅ | body_parser, cookie_parser, session, secure_headers |
| **v0.5** | ✅ | SSE, request_id, Bearer Token auth, rate limiting, compression, etag, timeout, JWT auth |
| **v0.6** | ✅ | Architecture refactoring: `halo/http` wraps `moonbitlang/async`, `halo` → `halo/http` layered deps; Koa-style `app.use()` API |

## Project Structure

```
wflixu/Halo/
├── moon.mod.json              # Module definition
├── halo/http/                 # HTTP abstraction layer (wraps moonbitlang/async)
│   ├── moon.pkg              # imports moonbitlang/async/http|socket
│   ├── request.mbt           # Request type + from_async() conversion
│   ├── response.mbt          # Response type + send() to connection
│   └── server.mbt            # Server wrapper (new → run_forever)
├── halo/                      # Framework core
│   ├── types.mbt             # Context, Middleware, Next (uses @http.Request/Response)
│   ├── compose.mbt           # Onion model composition
│   ├── app.mbt               # App::new(), use(), listen()
│   ├── context.mbt           # Context methods
│   └── router/               # Router middleware
│       ├── router.mbt         # HTTP method routing
│       ├── route.mbt         # Path matching
│       └── router_test.mbt
├── halo/middleware/           # Built-in middleware
│   ├── logger.mbt            # Request logging
│   ├── error_handler.mbt     # Unified error handling
│   ├── cors.mbt              # CORS support
│   ├── static.mbt            # Static file serving
│   ├── body_parser.mbt       # JSON/form body parsing
│   ├── cookie_parser.mbt     # Cookie parsing
│   ├── session.mbt           # Session management
│   ├── secure_headers.mbt    # Security headers
│   ├── request_id.mbt        # Request tracing ID
│   ├── auth.mbt              # Bearer Token authentication
│   ├── rate_limit.mbt        # Rate limiting (IP/user-based)
│   ├── compression.mbt       # Response compression (gzip/brotli)
│   ├── etag.mbt              # ETag generation for caching
│   ├── timeout.mbt           # Request timeout handling
│   └── jwt_auth.mbt          # JWT token validation
├── halo/helper/              # Helpers
│   └── sse.mbt               # Server-Sent Events
├── examples/                 # Examples
│   ├── demo.mbt
│   └── sse/
│       └── sse_demo.mbt
└── specs/                    # Documentation
    ├── design.md
    └── router-design.md
```

## Middleware Model

Halo uses the classic onion model — every request passes through middleware layers before and after the handler:

```
Request
  ↓
Middleware 1 (before)
  ↓
Middleware 2 (before)
  ↓
Handler
  ↑
Middleware 2 (after)
  ↑
Middleware 1 (after)
  ↓
Response
```

### Dependency Flow

```
request → @async_http.Server
              → @http.Request::from_async()     # convert to Halo Request
                  → App::callback()              # run middleware chain
                      → Context { req, res, state }
                          → Middleware[0].before → next → Middleware[1].before → ... → Handler
                          → Middleware[n].after ← ...
                  ← Response
              → @http.Response::send()          # send to connection
```

## Contributing

Contributions welcome!

```bash
# Clone repository
git clone https://github.com/wflixu/Halo.git
cd Halo

# Run tests
moon test

# Format code
moon fmt

# Update package interfaces
moon info
```

## 📄 License

MIT License - see [LICENSE](LICENSE) for details.

## 💡 Inspiration

- [Koa](https://koajs.com) — Middleware onion model
- [Express](https://expressjs.com) — Simple API design
- [Hono](https://hono.dev) — Modern edge framework



