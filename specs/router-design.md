# Halo Router Design

## Overview

Halo 路由中间件设计灵感来自 Hono，提供简洁、高性能的路由功能，作为 Halo 中间件生态的核心组件。

---

## Design Goals

1. **链式 API** - 流畅的方法链定义路由
2. **路径参数** - `:param` 语法捕获动态值
3. **通配符匹配** - `*` 支持任意层级匹配
4. **中间件集成** - 路由本身就是中间件，可组合
5. **高性能** - 使用高效的路由匹配算法

---

## API Design

### Basic Usage

```moonbit
use halo/router

let router = Router::new()

router
  .get("/", home_handler)
  .get("/user/:id", get_user)
  .post("/user", create_user)
  .put("/user/:id", update_user)
  .delete("/user/:id", delete_user)

app.add_middleware(router)
```

### HTTP Methods

支持所有标准 HTTP 方法：

```moonbit
router
  .get(path, handler)      // GET
  .post(path, handler)     // POST
  .put(path, handler)      // PUT
  .patch(path, handler)    // PATCH
  .delete(path, handler)   // DELETE
  .options(path, handler)  // OPTIONS
  .head(path, handler)     // HEAD
  .any(path, handler)      // 匹配所有方法
```

---

## Path Matching

### 1. Static Routes

精确匹配固定路径：

```moonbit
router.get("/users", list_users)     // 只匹配 /users
router.get("/api/v1/users", v1_users) // 匹配 /api/v1/users
```

### 2. Path Parameters

使用 `:param` 捕获动态值：

```moonbit
router.get("/user/:id", get_user)
// /user/123  -> params = {"id": "123"}
// /user/abc  -> params = {"id": "abc"}

router.get("/user/:id/post/:postId", get_post)
// /user/42/post/99 -> params = {"id": "42", "postId": "99"}
```

### 3. Wildcards

使用 `*` 匹配剩余路径：

```moonbit
router.get("/files/*", files_handler)
// /files/a       -> 匹配
// /files/a/b/c   -> 匹配
```

使用 `:param*` 捕获通配符值：

```moonbit
router.get("/files/:path*", files_handler)
// /files/js/app.js -> params = {"path": "js/app.js"}
```

### 4. Optional Parameters

使用 `?` 表示可选参数：

```moonbit
router.get("/user/:id?", get_user_or_list)
// /user      -> 匹配，params = {}
// /user/123  -> 匹配，params = {"id": "123"}
```

---

## Handler Signature

路由处理器是特殊的中间件函数：

```moonbit
type Handler = fn(Context, Next) -> Future[Unit]
```

Handler 可以：
- 从 `ctx.params` 读取路径参数
- 调用 `next()` 继续后续中间件
- 直接返回响应（中断中间件链）

### Accessing Route Params

```moonbit
let handler = fn(ctx, next) async {
  let user_id = ctx.params["id"]
  let path = ctx.params["path*"]  // 通配符参数
  ctx.set_json({"user_id": user_id})
}
```

---

## Router Options

### Strict Mode

控制尾部斜杠处理：

```moonbit
let router = Router::new()
  .strict(true)   // /users 和 /users/ 是不同的
  .strict(false)  // /users 和 /users/ 视为相同（默认）
```

### Case Sensitive

控制路径大小写敏感：

```moonbit
let router = Router::new()
  .case_sensitive(true)   // /User 和 /user 不同
  .case_sensitive(false)  // /User 和 /user 相同（默认）
```

---

## Advanced Features

### Route Groups / Prefix

为路由添加公共前缀，便于组织：

```moonbit
let api = router.group("/api")
api
  .get("/users", list_users)      // /api/users
  .get("/users/:id", get_user)    // /api/users/:id

let v1 = api.group("/v1")
v1
  .get("/status", status_handler) // /api/v1/status
```

### Middleware Per Route

为单条路由添加中间件：

```moonbit
router
  .get("/public", public_handler)
  .get("/private", auth_middleware, private_handler)  // 多个参数，最后是 handler
  .get("/admin", [auth_middleware, admin_middleware], admin_handler)  // 中间件数组
```

### Route Guards

在执行 handler 前运行守卫逻辑：

```moonbit
router
  .get("/admin/*")
  .guard(is_authenticated)
  .guard(has_admin_role)
  .handle(admin_handler)
```

---

## Context Extensions

路由中间件需要在 Context 中添加：

```moonbit
struct Context {
  req: Request,
  res: Response,
  state: Map[String, Any],
  params: Map[String, String],    // 新增：路径参数
  matched_route: Option[String],  // 新增：匹配的路径模式
}
```

### Context Methods

```moonbit
impl Context {
  fn param(self, name: String) -> Option[String]  // 获取单个参数
  fn params(self) -> Map[String, String]          // 获取所有参数
}
```

---

## Matching Algorithm

### 优先级规则

1. **静态路由优先级最高**
   - `/users/profile` 比 `/users/:id` 优先匹配

2. **参数数量少的优先**
   - `/users/:id` 比 `/users/:category/:id` 优先

3. **通配符优先级最低**
   - `/files/*` 最后匹配

### 匹配流程

```
请求：GET /user/123

1. 收集所有匹配的路由规则
   - GET /user/:id   ✓ 匹配
   - GET /user/*     ✓ 匹配
   - POST /user/:id  ✗ 方法不匹配

2. 按优先级排序
   - 静态 > 参数 > 通配符

3. 依次执行，第一个非 404 的 handler 胜出
```

---

## Error Handling

### 404 Not Found

没有路由匹配时：

```moonbit
router.handle_404(fn(ctx) async {
  ctx.set_status(404)
  ctx.set_json({"error": "Not Found"})
})
```

### 405 Method Not Allowed

路径匹配但方法不匹配：

```moonbit
router.handle_405(fn(ctx, allowed_methods: List[String]) async {
  ctx.set_status(405)
  ctx.set_header("Allow", allowed_methods.join(", "))
  ctx.set_json({"error": "Method Not Allowed"})
})
```

---

## File Structure

```
halo/
├── router.mbt        # Router 主模块
├── route.mbt         # Route 规则定义
├── matcher.mbt       # 路径匹配算法
└── router_test.mbt   # 测试
```

### Module Exports

```moonbit
// router.mbt
pub struct Router
pub fn Router::new() -> Router
pub fn Router::get(self, path: String, handler: Handler) -> Router
pub fn Router::post(self, path: String, handler: Handler) -> Router
// ...其他方法
pub fn Router::to_middleware(self) -> Middleware  // 转换为中间件
```

---

## Integration with Halo

### Router as Middleware

路由器本质上是一个中间件：

```moonbit
// 内部实现
fn router_middleware(ctx: Context, next: Next) async {
  match router.find(ctx.req.method, ctx.req.path) {
    Some(route) => {
      ctx.params = route.params
      ctx.matched_route = Some(route.pattern)
      route.handler(ctx, next)
    }
    None => {
      // 没有匹配，调用 next 返回 404
      next()
    }
  }
}
```

### Complete Example

```moonbit
use halo/app
use halo/router

fn main {
  let app = App::new()
  let router = Router::new()

  router
    .get("/", fn(ctx, _) async {
      ctx.set_body("Home")
    })
    .get("/user/:id", fn(ctx, _) async {
      let id = ctx.params["id"]
      ctx.set_json({"id": id})
    })

  app.add_middleware(router.to_middleware())
  app.listen(":3000")
}
```

---

## Performance Considerations

### 1. 路由预编译

路由注册时构建匹配树，而不是每次请求线性搜索：

```
/
├── user/
│   ├── :id/
│   │   └── post/:postId
│   └── me
└── api/
    └── * (wildcard)
```

### 2. 方法索引

按 HTTP 方法分组路由：

```moonbit
routes : Map[String, List[Route]]  // method -> routes
```

### 3. 缓存匹配结果

对频繁访问的路径缓存匹配结果。

---

## Comparison Table

| Feature | Hono | Halo Router |
|---------|------|-------------|
| Path params | `:id` | `:id` |
| Wildcards | `*` | `*`, `:param*` |
| Optional params | `:id?` | `:id?` |
| Route groups | `app.route('/api')` | `router.group('/api')` |
| Per-route middleware | ✓ | ✓ |
| 404 handler | ✓ | ✓ |
| 405 handler | ✓ | ✓ |
| Method chaining | ✓ | ✓ |
| Regex matching | ✓ | 暂不支持（v0.2） |

---

## Roadmap

### v0.2 (Initial Release)
- [ ] Static routes
- [ ] Path parameters (`:param`)
- [ ] Wildcards (`*`, `:param*`)
- [ ] Method routing (GET, POST, etc.)
- [ ] 404/405 handlers

### v0.3
- [ ] Route groups
- [ ] Per-route middleware
- [ ] Optional parameters (`:param?`)
- [ ] Route guards

### v0.4 (Future)
- [ ] Regex matching
- [ ] Named routes
- [ ] Route reverse lookup
- [ ] OpenAPI/Swagger 集成
