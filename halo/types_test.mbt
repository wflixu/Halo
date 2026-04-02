// tests/types_test.mbt
// Blackbox tests for types module

test "Context has req and res" {
  let ctx = make_context()
  // ctx.req and ctx.res should exist (they're structs, not Options)
  let _ = ctx.req
  let _ = ctx.res
}

test "Context state is mutable" {
  let ctx = make_context()
  ctx.state["key"] = "value"
  assert_eq(ctx.state["key"], "value")
}

test "Next is created" {
  let next = make_next()
  // next should exist
  let _ = next
}
