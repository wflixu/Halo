// src/halo/compose_test.mbt
// Blackbox tests for middleware composition engine

test "compose executes middleware in order" {
  let order : Ref[Array[String]] = { val : [] }

  let mw1 = fn(_ctx: Context, next: Next) {
    let _ = order.val.push("mw1-before")
    next()
    let _ = order.val.push("mw1-after")
  }

  let mw2 = fn(_ctx: Context, next: Next) {
    let _ = order.val.push("mw2-before")
    next()
    let _ = order.val.push("mw2-after")
  }

  let composed = compose([mw1, mw2])
  let ctx = make_context()
  let next = make_next()
  composed(ctx, next)

  // Expected order: mw1-before, mw2-before, mw2-after, mw1-after
  assert_eq(order.val[0], "mw1-before")
  assert_eq(order.val[1], "mw2-before")
  assert_eq(order.val[2], "mw2-after")
  assert_eq(order.val[3], "mw1-after")
}

test "compose handles empty middleware array" {
  let composed = compose([])
  let ctx = make_context()
  let next = make_next()
  // Should not error when running empty middleware chain
  composed(ctx, next)
}

test "middleware can short-circuit" {
  let mw2_executed : Ref[Bool] = { val : false }

  let mw1 = fn(_ctx: Context, _next: Next) {
    // Don't call next() - short-circuit
  }

  let mw2 = fn(_ctx: Context, _next: Next) {
    mw2_executed.val = true
  }

  let composed = compose([mw1, mw2])
  let ctx = make_context()
  let next = make_next()
  composed(ctx, next)

  // mw2 should not execute because mw1 short-circuited
  assert_eq(mw2_executed.val, false)
}

test "middleware chain calls next at the end" {
  let final_next_called : Ref[Bool] = { val : false }

  let mw = fn(_ctx: Context, next: Next) {
    next()
  }

  let final_next = fn() {
    final_next_called.val = true
  }

  let composed = compose([mw])
  let ctx = make_context()
  composed(ctx, final_next)

  // final next should be called
  assert_eq(final_next_called.val, true)
}
