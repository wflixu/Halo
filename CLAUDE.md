# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Halo is a Koa-style middleware web framework for MoonBit, implementing the onion model with structured concurrency and streaming-first response handling.

## Commands

```bash
# Run all tests
moon test

# Run tests with snapshot updates
moon test --update

# Format code
moon fmt

# Update package interfaces
moon info

# Check uncovered code
moon coverage analyze > uncovered.log

# Standard pre-commit workflow
moon info && moon fmt
```

## Architecture

**Module Structure:**
- `src/halo/` - Framework core
  - `types.mb` - Core types (Context, Request, Response, Middleware, Next)
  - `compose.mb` - Middleware composition engine (onion model)
  - `app.mb` - Application entry point
  - `context.mb` - Context implementation
  - `http/` - HTTP server wrappers

**Middleware Pattern:**
```moonbit
type Middleware = fn(Context, Next) -> Future[Unit]
```

Onion execution: `mw1.before → mw2.before → handler → mw2.after → mw1.after`

## Key Files

- `moon.mod.json` - Module metadata (name: `wflixu/Halo`)
- `moon.pkg` - Package dependencies per directory
- `.mbti` files - Generated package interfaces (check diffs for API changes)

## Testing Conventions

- `_test.mbt` - Blackbox tests (public API)
- `_wbtest.mbt` - Whitebox tests (internal implementation)
- Prefer `assert_eq` for stable results
- Use snapshot tests for complex outputs

## Design Philosophy

- Simple over configurable
- Composition over inheritance
- Streaming over buffering
- Structured concurrency over callbacks
