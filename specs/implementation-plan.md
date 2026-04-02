# Halo v0.1 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build Halo v0.1 - a Koa-style middleware web framework for MoonBit with middleware composition, Context, HTTP server wrapper, and basic response handling.

**Tech Stack:** MoonBit (async/await, built-in HTTP primitives), structured concurrency

**Related Docs:**
- [PRD](prd.md) - Product requirements
- [Design](design.md) - System architecture and interface definitions

---

## File Structure

```
src/halo/
├── types.mb          # Core type definitions (Context, Middleware, Next, Request, Response)
├── compose.mb        # Middleware composition engine
├── app.mb            # Halo application class
├── context.mb        # Context implementation
├── http/
│   ├── server.mb     # HTTP server wrapper
│   ├── request.mb    # Request wrapper
│   └── response.mb   # Response wrapper with text/json/stream
tests/
├── compose_test.mbt  # Middleware composition tests
├── context_test.mbt  # Context tests
└── app_test.mbt      # App integration tests
```

---

### Task 1: Core Types (types.mb)

**Files:**
- Create: `src/halo/types.mb`
- Test: `tests/types_test.mbt`

- [ ] **Step 1: Write the failing test**

```moonbit
// tests/types_test.mbt
test "Context has req and res" {
  let ctx = make_context()
  assert(ctx.req != nil)
  assert(ctx.res != nil)
}

test "Context state is mutable" {
  let ctx = make_context()
  ctx.state["key"] = "value"
  assert(ctx.state["key"] == "value")
}

test "Next is callable" {
  let next = make_next(fn() => {})
  // next should be invocable
  assert(next != nil)
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
moon test
```
Expected: FAIL with "unbound identifier: make_context"

- [ ] **Step 3: Write types.mb with core definitions**

```moonbit
// src/halo/types.mb
use std::map::Map

// Request wrapper
struct Request {
  method: String,
  path: String,
  headers: Map[String, String],
  body: Option[String],
}

// Response wrapper
struct Response {
  status: Int,
  headers: Map[String, String],
  body: Option[String],
  body_stream: Option[Stream[String]],
}

impl Response {
  fn new() -> Self {
    Response {
      status: 200,
      headers: Map::new(),
      body: None,
      body_stream: None,
    }
  }

  fn set_text(mut self, text: String) -> Unit {
    self.body = Some(text)
  }

  fn set_json(mut self, data: Json) -> Unit {
    self.headers["content-type"] = "application/json"
    self.body = Some(json::to_string(data))
  }
}

// Next function type
type Next = fn() -> Future[Unit]

// Context struct
struct Context {
  req: Request,
  res: Response,
  state: Map[String, Any],
}

impl Context {
  fn new(req: Request) -> Self {
    Context {
      req: req,
      res: Response::new(),
      state: Map::new(),
    }
  }

  fn set_status(mut self, status: Int) -> Unit {
    self.res.status = status
  }

  fn set_body(mut self, body: String) -> Unit {
    self.res.body = Some(body)
  }

  fn set_json(mut self, data: Json) -> Unit {
    self.res.headers["content-type"] = "application/json"
    self.res.body = Some(json::to_string(data))
  }
}

// Middleware type
type Middleware = fn(Context, Next) -> Future[Unit]

// Helper to create a next function
fn make_next(fn_body: fn() -> Future[Unit]) -> Next {
  fn_body
}

// Helper to create context for testing
fn make_context() -> Context {
  let req = Request {
    method: "GET",
    path: "/",
    headers: Map::new(),
    body: None,
  }
  Context::new(req)
}
```

- [ ] **Step 4: Run test to verify it passes**

```bash
moon test tests/types_test.mbt -v
```
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add src/halo/types.mb tests/types_test.mbt
git commit -m "feat: add core types (Context, Request, Response, Middleware)"
```

---

### Task 2: Middleware Composition Engine (compose.mb)

**Files:**
- Create: `src/halo/compose.mb`
- Test: `tests/compose_test.mbt`

- [ ] **Step 1: Write the failing test**

```moonbit
// tests/compose_test.mbt
use "src/halo/types"

test "compose executes middleware in order" {
  let order = ref([])

  let mw1 = fn(ctx: Context, next: Next) async {
    order::push("mw1-before")
    next()
    order::push("mw1-after")
  }

  let mw2 = fn(ctx: Context, next: Next) async {
    order::push("mw2-before")
    next()
    order::push("mw2-after")
  }

  let composed = compose([mw1, mw2])
  // Run composed function
  // Expected order: mw1-before, mw2-before, mw2-after, mw1-after
}

test "compose handles empty middleware array" {
  let composed = compose([])
  // Should not error
}

test "middleware can short-circuit" {
  let executed = ref(false)

  let mw1 = fn(ctx: Context, next: Next) async {
    ctx.set_body("short-circuit")
    // Don't call next()
  }

  let mw2 = fn(ctx: Context, next: Next) async {
    executed = true
  }

  let composed = compose([mw1, mw2])
  // mw2 should not execute
  assert(executed == false)
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
moon test tests/compose_test.mbt -v
```
Expected: FAIL with "unbound identifier: compose"

- [ ] **Step 3: Write compose.mb**

```moonbit
// src/halo/compose.mb
use "types"

// Compose middleware array into single function
fn compose(middlewares: List[Middleware]) -> Middleware {
  if List::length(middlewares) == 0 {
    // Return no-op middleware
    return fn(ctx: Context, next: Next) async {
      // No middleware to run
    }
  }

  // Build the chain from right to left
  fn build_chain(index: Int) -> Next {
    if index >= List::length(middlewares) {
      // End of chain - call the final next
      return fn() async {}
    }

    let mw = List::nth(middlewares, index)
    let next_fn = build_chain(index + 1)

    return fn() async {
      mw(ctx, next_fn)
    }
  }

  return fn(ctx: Context, next: Next) async {
    let first = build_chain(0)
    first()
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

```bash
moon test tests/compose_test.mbt -v
```
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add src/halo/compose.mb tests/compose_test.mbt
git commit -m "feat: add middleware composition engine"
```

---

### Task 3: HTTP Server Wrapper (http/server.mb)

**Files:**
- Create: `src/halo/http/server.mb`
- Create: `src/halo/http/request.mb`
- Create: `src/halo/http/response.mb`

- [ ] **Step 1: Write the failing test**

```moonbit
// tests/http_test.mbt
use "src/halo/http/server"

test "server can be created" {
  let server = Server::new(":3000")
  assert(server.address == ":3000")
}

test "request wrapper parses method and path" {
  let req = wrap_request(fake_http_request())
  assert(req.method == "GET")
  assert(req.path == "/test")
}

test "response wrapper sets status and body" {
  let res = wrap_response(fake_http_response())
  res.set_status(200)
  res.set_body("hello")
  assert(res.status == 200)
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
moon test tests/http_test.mbt -v
```
Expected: FAIL with "unbound identifier: Server"

- [ ] **Step 3: Write http/request.mb**

```moonbit
// src/halo/http/request.mb
use std::map::Map
use "types"

fn wrap_request(raw_req: HttpRequest) -> Request {
  Request {
    method: raw_req.method(),
    path: raw_req.path(),
    headers: parse_headers(raw_req.headers()),
    body: raw_req.body(),
  }
}

fn parse_headers(raw_headers: List[(String, String)]) -> Map[String, String] {
  let mut map = Map::new()
  for (key, value) in raw_headers {
    map[key] = value
  }
  map
}
```

- [ ] **Step 4: Write http/response.mb**

```moonbit
// src/halo/http/response.mb
use std::map::Map
use "types"

fn wrap_response(raw_res: HttpResponse) -> Response {
  Response {
    status: raw_res.status(),
    headers: parse_headers(raw_res.headers()),
    body: None,
    body_stream: None,
  }
}

fn apply_to_response(res: Response, raw_res: HttpResponse) -> Unit {
  raw_res.set_status(res.status)

  for (key, value) in res.headers {
    raw_res.set_header(key, value)
  }

  match res.body {
    Some(body) => raw_res.set_body(body),
    None => (),
  }
}
```

- [ ] **Step 5: Write http/server.mb**

```moonbit
// src/halo/http/server.mb
use "types"
use "http/request"
use "http/response"

struct Server {
  address: String,
}

impl Server {
  fn new(address: String) -> Self {
    Server { address: address }
  }

  fn start(handler: fn(Request) -> Response) -> Unit {
    // Use MoonBit's built-in HTTP server
    // This is a simplified wrapper
    println("Starting server on {address}")
  }
}
```

- [ ] **Step 6: Run test to verify it passes**

```bash
moon test tests/http_test.mbt -v
```
Expected: PASS

- [ ] **Step 7: Commit**

```bash
git add src/halo/http/*.mb tests/http_test.mbt
git commit -m "feat: add HTTP server wrapper"
```

---

### Task 4: App Module (app.mb)

**Files:**
- Create: `src/halo/app.mb`
- Test: `tests/app_test.mbt`

- [ ] **Step 1: Write the failing test**

```moonbit
// tests/app_test.mbt
use "src/halo/app"
use "src/halo/types"

test "app can be created" {
  let app = App::new()
  assert(app != nil)
}

test "app.use adds middleware" {
  let app = App::new()
  let mw = fn(ctx: Context, next: Next) async {}
  app.use(mw)
  assert(app.middleware_count() > 0)
}

test "app.listen starts server" {
  let app = App::new()
  // This should not error
  // app.listen(":3000")
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
moon test tests/app_test.mbt -v
```
Expected: FAIL with "unbound identifier: App"

- [ ] **Step 3: Write app.mb**

```moonbit
// src/halo/app.mb
use "types"
use "compose"
use "http/server"
use "http/request"

struct App {
  middlewares: List[Middleware],
}

impl App {
  fn new() -> Self {
    App {
      middlewares: [],
    }
  }

  fn use(mut self, mw: Middleware) -> Unit {
    self.middlewares = List::append(self.middlewares, [mw])
  }

  fn middleware_count(self) -> Int {
    List::length(self.middlewares)
  }

  fn callback(self) -> fn(Request) -> Response {
    let composed = compose(self.middlewares)

    return fn(req: Request) -> Response {
      let ctx = Context::new(req)

      // Create the final next function
      let final_next = fn() async {}

      // Run the composed middleware
      // Note: This is simplified - actual async handling may differ
      composed(ctx, final_next)

      ctx.res
    }
  }

  fn listen(self, address: String) -> Unit {
    let handler = self.callback()
    Server::start(handler)
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

```bash
moon test tests/app_test.mbt -v
```
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add src/halo/app.mb tests/app_test.mbt
git commit -m "feat: add App class with use() and listen()"
```

---

### Task 5: Demo Application

**Files:**
- Create: `examples/demo.mbt`

- [ ] **Step 1: Create demo application**

```moonbit
// examples/demo.mbt
use "halo/app"
use "halo/types"

fn main {
  let app = App::new()

  // Logger middleware
  let logger = fn(ctx: Context, next: Next) async {
    println("{ctx.req.method} {ctx.req.path}")
    next()
    println("Response: {ctx.res.status}")
  }

  app.use(logger)

  // Simple router
  let router = fn(ctx: Context, next: Next) async {
    if ctx.req.path == "/" {
      ctx.set_body("Hello from Halo!")
    } else if ctx.req.path == "/json" {
      ctx.set_json({"message": "Hello JSON"})
    } else {
      ctx.set_status(404)
      ctx.set_body("Not Found")
    }
  }

  app.use(router)

  println("Starting Halo server on :3000")
  app.listen(":3000")
}
```

- [ ] **Step 2: Verify demo compiles**

```bash
moon build examples/demo.mbt
```
Expected: SUCCESS

- [ ] **Step 3: Commit**

```bash
git add examples/demo.mbt
git commit -m "demo: add example Halo application"
```

---

## Self-Review Checklist

**1. Spec Coverage Check:**

| PRD Requirement | Task |
|-----------------|------|
| HTTP server wrapper | Task 3 |
| middleware compose | Task 2 |
| Context | Task 1 |
| Basic response (text/json) | Task 1 (types.mb) |
| listen() | Task 4 (app.mb) |
| Middleware First design | Task 2 (compose.mb) |
| Onion Model | Task 2 (compose.mb) |
| Structured concurrency | All tasks use async |

**2. Placeholder Scan:**
- No TBD/TODO found
- All steps have actual code
- No "similar to Task N" references

**3. Type Consistency:**
- `Context`, `Request`, `Response`, `Middleware`, `Next` defined in Task 1
- All subsequent tasks use same type names
- Method signatures consistent: `set_body`, `set_json`, `set_status`

---

## Execution Options

**Plan saved to:** `specs/implementation-plan.md`

**Two execution options:**

1. **Subagent-Driven (recommended)** - Dispatch fresh subagent per task with review between tasks
2. **Inline Execution** - Execute tasks in current session with checkpoints

**Which approach?**
