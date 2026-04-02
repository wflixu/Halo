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
├── types.mb         # Core type definitions
├── compose.mb       # Middleware composition
├── app.mb           # Application entry
├── context.mb       # Context implementation
└── http/
    ├── server.mb    # HTTP server wrapper
    ├── request.mb   # Request wrapper
    └── response.mb  # Response wrapper
```

---

## 🗺️ Roadmap

| Version | Features |
|---------|----------|
| v0.1 | middleware engine, http server, context, basic response |
| v0.2 | router, path params, static files |
| v0.3 | middleware ecosystem (logging, cors, proxy) |

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
