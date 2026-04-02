# Halo Roadmap & Implementation Plans

本文档汇总了 Halo 框架的所有版本规划和实现计划。

---

## Version Roadmap

| Version | Status | Features |
|---------|--------|----------|
| v0.1 | ✅ Done | Middleware engine, HTTP server, Context, basic response |
| v0.2 | Planned | Router, path params, static files |
| v0.3 | Planned | Built-in middleware (logger, error_handler, cors, static) |
| v0.4 | Planned | body_parser, cookie, session, secure_headers |
| v0.5 | Future | rate_limit, compression, etag, request_id, auth_jwt |

---

## v0.1 Implementation Plan

**Status:** ✅ Complete

**Goal:** Build Halo v0.1 - a Koa-style middleware web framework for MoonBit.

**Files Created:**
```
halo/
├── types.mbt          # Core type definitions
├── compose.mbt        # Middleware composition engine
├── app.mbt            # Application class
├── types_test.mbt     # Type tests
├── compose_test.mbt   # Compose tests
├── app_test.mbt       # App tests
└── http/
    ├── server.mbt     # HTTP server wrapper
    ├── request.mbt    # Request wrapper
    ├── response.mbt   # Response wrapper
    └── http_test.mbt  # HTTP tests
```

**Commits:**
- `feat: add core types (Context, Request, Response, Middleware)`
- `feat: add middleware composition engine`
- `feat: add HTTP server wrapper`
- `feat: add App class with use() and listen()`
- `demo: add example Halo application`

**Tests:** 21/21 passing

---

## v0.2 Router Plan

**Status:** 📋 Planned

**Related Docs:** [router-design.md](router-design.md)

**Goal:** Add routing middleware with path parameters and wildcard matching.

**Planned Files:**
```
halo/
├── router/
│   ├── moon.pkg
│   ├── router.mbt         # Router main module
│   ├── matcher.mbt        # Path matching algorithm
│   └── router_test.mbt    # Router tests
```

**Features:**
- [ ] Static routes (`/users`)
- [ ] Path parameters (`/user/:id`)
- [ ] Wildcards (`/files/*`, `:path*`)
- [ ] HTTP method routing (GET, POST, PUT, DELETE)
- [ ] 404/405 handlers
- [ ] Route groups (`/api/v1`)
- [ ] Per-route middleware

**API Example:**
```moonbit
let router = Router::new()

router
  .get("/", home_handler)
  .get("/user/:id", get_user)
  .post("/user", create_user)
  .any("/api/*", api_handler)

app.add_middleware(router.to_middleware())
```

---

## v0.3 Middleware Core Plan

**Status:** 📋 Planned

**Goal:** Add essential built-in middleware for every web application.

**Planned Files:**
```
halo/
└── middleware/
    ├── moon.pkg
    ├── logger.mbt           # Request logging
    ├── error_handler.mbt    # Unified error handling
    ├── cors.mbt             # Cross-origin resource sharing
    └── static.mbt           # Static file serving
```

### logger

```moonbit
app.add_middleware(@middleware.logger())
// Output: [20ms] GET /users -> 200
```

### error_handler

```moonbit
app.add_middleware(@middleware.error_handler())
// Catches all errors, returns standard JSON format
```

### cors

```moonbit
app.add_middleware(@middleware.cors.allow_all())
app.add_middleware(@middleware.cors.allow_origins(["https://example.com"]))
```

### static

```moonbit
app.add_middleware(@middleware.static("./public"))
app.add_middleware(@middleware.static("./assets", prefix="/static"))
```

---

## v0.4 Middleware Common Plan

**Status:** 📋 Planned

**Goal:** Add commonly-used middleware for 80% of web applications.

**Planned Files:**
```
halo/
└── middleware/
    ├── body_parser.mbt      # Request body parsing
    ├── cookie.mbt           # Cookie parsing
    ├── session.mbt          # Session management
    └── secure_headers.mbt   # Security headers
```

### body_parser

```moonbit
app.add_middleware(@middleware.body_parser())

// In handler:
let json_data = ctx.body.json
let form_data = ctx.body.form
```

### cookie_parser

```moonbit
app.add_middleware(@middleware.cookie_parser())

// In handler:
let token = ctx.cookies["token"]
```

### session

```moonbit
app.add_middleware(@middleware.session())

// In handler:
ctx.session["user_id"] = "123"
let user_id = ctx.session["user_id"]
```

### secure_headers

```moonbit
app.add_middleware(@middleware.secure_headers())
// Sets: X-Frame-Options, X-Content-Type-Options, etc.
```

---

## v0.5 Middleware Advanced Plan

**Status:** 🔮 Future

**Goal:** Add advanced middleware for specific scenarios.

**Planned:**
- `rate_limit` - Request rate limiting (per IP, per user)
- `compression` - gzip / brotli response compression
- `etag` - Automatic ETag generation for caching
- `request_id` - Unique request tracing ID
- `timeout` - Request timeout with automatic cancellation
- `auth_jwt` - JWT token validation

---

## File Conventions

### Package Structure

```
wflixu/Halo/
├── moon.mod.json          # Module definition
├── halo/                  # Main package
│   ├── moon.pkg
│   └── *.mbt
├── halo/router/           # Sub-package
│   ├── moon.pkg
│   └── *.mbt
├── halo/middleware/       # Sub-package
│   ├── moon.pkg
│   └── *.mbt
└── examples/
    └── demo.mbt
```

### Import Paths

```moonbit
// Main package
use wflixu/Halo/halo

// Sub-packages
use wflixu/Halo/halo/router
use wflixu/Halo/halo/middleware
```

### Testing

- Blackbox tests: `*_test.mbt` (same directory as source)
- Whitebox tests: `*_wbtest.mbt` (same directory as source)

Run tests: `moon test`

---

## Design Principles

1. **Simple over configurable** - Sensible defaults, optional customization
2. **Composition over inheritance** - Everything is middleware
3. **Streaming over buffering** - Efficient large payload handling
4. **Structured concurrency** - Automatic error propagation, cancellation
5. **Zero external dependencies** - All middleware built-in

---

## Related Documents

- [PRD](prd.md) - Product requirements and feasibility analysis
- [Design](design.md) - System architecture and interface definitions
- [Router Design](router-design.md) - Router middleware design spec
- [Implementation Plan](implementation-plan.md) - v0.1 detailed tasks (completed)
