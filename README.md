# Halo

**Halo** is a modern middleware web framework for MoonBit, inspired by Koa but built for structured concurrency and streaming.

> A halo of middleware around every request.

[![CI](https://github.com/wflixu/Halo/actions/workflows/ci.yml/badge.svg)](https://github.com/wflixu/Halo/actions/workflows/ci.yml)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

## ✨ Features

- **🧅 Onion Middleware** - Elegant before → next → after composition
- **⚡ Native Async** - Compiler-level async/await (no Promise/await syntax)
- **🧵 Structured Concurrency** - Automatic error propagation, request-scoped lifecycle
- **🌊 Streaming First** - Responses are streams, not buffers
- **🧩 Composable** - Everything is middleware

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

fn main {
  let app = @halo.App::new()

  // Logger middleware
  app.add_middleware(@middleware.logger())

  // Routes
  app.add_middleware(fn(ctx, _) {
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

fn main {
  let app = @halo.App::new()

  // Core middleware
  app.add_middleware(@middleware.logger())
  app.add_middleware(@middleware.error_handler())
  app.add_middleware(@middleware.cors_allow_all())
  app.add_middleware(@middleware.secure_headers())

  // Request parsing
  app.add_middleware(@middleware.body_parser())
  app.add_middleware(@middleware.cookie_parser())
  app.add_middleware(@middleware.session())

  // Static files
  app.add_middleware(@middleware.static_files("./public"))

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

  app.add_middleware(router.to_middleware())

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
| `sse_*()` | Server-Sent Events helpers |

## 🗺️ Roadmap

| Version | Status | Features |
|---------|--------|----------|
| **v0.1** | ✅ | Core middleware engine, HTTP server, Context |
| **v0.2** | ✅ | Router with path params (`:id`) and wildcards (`*`, `:param*`) |
| **v0.3** | ✅ | Built-in middleware: logger, error_handler, cors, static |
| **v0.4** | ✅ | body_parser, cookie_parser, session, secure_headers |
| **v0.5** | ✅ | SSE, request_id - compression, rate_limit, auth_jwt (planned) |

See [specs/roadmap.md](specs/roadmap.md) for detailed plans.

## 📁 Project Structure

```
wflixu/Halo/
├── moon.mod.json              # Module definition
├── halo/                      # Core package
│   ├── types.mbt              # Context, Request, Response, Middleware
│   ├── compose.mbt            # Onion model composition
│   ├── app.mbt                # App::new(), add_middleware(), listen()
│   └── http/                  # HTTP server wrappers
├── halo/router/               # Router middleware
│   ├── router.mbt             # HTTP method routing
│   ├── route.mbt              # Path matching
│   └── router_test.mbt
├── halo/middleware/           # Built-in middleware
│   ├── logger.mbt
│   ├── error_handler.mbt
│   ├── cors.mbt
│   ├── static.mbt
│   ├── body_parser.mbt
│   ├── cookie_parser.mbt
│   ├── session.mbt
│   ├── secure_headers.mbt
│   └── request_id.mbt
├── halo/helper/               # Helpers
│   └── sse.mbt                # Server-Sent Events
├── examples/                  # Examples
│   ├── demo.mbt
│   └── sse/
│       └── sse_demo.mbt
└── specs/                     # Documentation
    ├── design.md
    ├── roadmap.md
    └── router-design.md
```

## 🧠 Middleware Model

Halo uses the classic onion model:

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

## 🤝 Contributing

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
