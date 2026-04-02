# wflixu/Halo

**Halo** is a modern middleware web framework for MoonBit, inspired by Koa but built for structured concurrency and streaming.

A halo of middleware around every request.

---

## ✨ Features

- **🧅 Onion Middleware** - Elegant before → next → after composition
- **⚡ Native Async** - Compiler-level async/await (no Promise/await syntax needed)
- **🧵 Structured Concurrency** - Automatic error propagation, request-scoped lifecycle
- **🌊 Streaming First** - Responses are streams, not buffers
- **🧩 Composable** - Everything is middleware

---

## 🚀 Quick Start

```moonbit
use wflixu/Halo

fn main {
  let app = Halo.new()

  app.use(fn(ctx, next) async {
    println("{ctx.req.method} {ctx.req.path}")
    next()
  })

  app.use(fn(ctx, _) async {
    ctx.text("Hello, Halo!")
  })

  app.listen(":3000")
}
```

---

## 📦 Installation

Add to your `moon.mod.json`:

```json
{
  "name": "your/module",
  "dependencies": {
    "wflixu/Halo": "*"
  }
}
```

---

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

---

## 📦 API Overview

### Create App

```moonbit
let app = Halo.new()
```

### Use Middleware

```moonbit
app.use(fn(ctx, next) async {
  // before logic
  next()
  // after logic
})
```

### Send Response

```moonbit
ctx.text("hello")
ctx.json({"msg": "hello"})
ctx.set_status(200)
```

### Start Server

```moonbit
app.listen(":3000")
```

---

## 🧩 Core Concepts

### Context

```moonbit
struct Context {
  req: Request,
  res: Response,
  state: Map[String, Any],
}
```

- `req` — Request info (method, path, headers, body)
- `res` — Response control (status, headers, body)
- `state` — Cross-middleware shared data

### Middleware

```moonbit
type Middleware = fn(Context, Next) -> Future[Unit]
```

---

## ⚖️ Why Halo?

| Feature | Koa | Halo |
|---------|-----|------|
| Async model | Promise | Compiler async |
| Concurrency | Manual | Structured |
| Error handling | Manual try/catch | Auto propagation |
| Streaming | Limited | Native support |
| Runtime | Node.js | MoonBit native |

---

## 🏗️ Philosophy

Halo is not about copying Koa — it's about building a more modern middleware runtime on MoonBit.

**Core principles:**
- Simple over configurable
- Composition over inheritance
- Streaming over buffering
- Structured concurrency over callbacks

---

## 📁 Project Structure

```
halo/
├── types.mbt              # Core type definitions
├── compose.mbt            # Middleware composition
├── app.mbt                # Application entry
└── http/
    ├── server.mbt         # HTTP server wrapper
    ├── request.mbt        # Request wrapper
    └── response.mbt       # Response wrapper
```

---

## 🗺️ Roadmap

| Version | Features |
|---------|----------|
| **v0.1** ✅ | middleware engine, http server, context, basic response |
| **v0.2** 📋 | router, path params (`:id`), wildcards (`*`), route groups |
| **v0.3** 📋 | built-in middleware: logger, error_handler, cors, static |
| **v0.4** 📋 | body_parser, cookie, session, secure_headers |
| **v0.5** 🔮 | rate_limit, compression, etag, auth_jwt |

See [specs/roadmap.md](specs/roadmap.md) for detailed plans.

---

## 🧰 Built-in Middleware (Coming Soon)

Halo provides zero-config middleware for common web development needs:

```moonbit
use wflixu/Halo/halo
use wflixu/Halo/halo/middleware

let app = @halo.App::new()

// Core middleware (every app needs these)
app.add_middleware(@middleware.logger())
app.add_middleware(@middleware.error_handler())
app.add_middleware(@middleware.cors())

// Request processing
app.add_middleware(@middleware.body_parser())
app.add_middleware(@middleware.session())

// Static files
app.add_middleware(@middleware.static("./public"))
```

**Available in v0.3+:**
- `logger` - Request logging
- `error_handler` - Unified error handling
- `cors` - Cross-origin requests
- `static` - Static file serving

**Planned for v0.4+:**
- `body_parser` - JSON/Form parsing
- `cookie` / `session` - Session management
- `secure_headers` - Security headers
- `rate_limit` - Request throttling

---

## ⚠️ Status

**🚧 Early stage** — API may change until v1.0

---

## 🤝 Contributing

Contributions welcome:
- Middleware implementations
- Router design
- Examples
- Documentation improvements

---

## 📄 License

MIT

---

## 💡 Inspiration

- [Koa](https://koajs.com) — Middleware onion model
- [Express](https://expressjs.com) — Simple API design
- [Hono](https://hono.dev) — Modern edge framework
