# Language Implementation Examples

This document provides working examples of how to add different technologies to the monorepo. These examples demonstrate the integration patterns and can be used as templates for new implementations.

## Overview

Each example follows the same integration pattern:
1. **Bazel Rules**: Add appropriate `rules_*` to MODULE.bazel
2. **System Dependencies**: Ensure tools are available in flake.nix (usually already included)
3. **Language Dependencies**: Use native package managers (uv, npm, cargo)
4. **Build Configuration**: Create BUILD.bazel files with proper targets
5. **Testing**: Include test targets and validation

## Prerequisites

Before implementing any of these examples:
```bash
# Ensure you're in the development environment
nix develop

# Verify Bazel is working
bazel version
```

## Python Backend with uv

### uv environment notes
- Prefer a project-local `.venv/` (git-ignored) created via `uv venv` or `uv sync`.
- Drive execution with `uv run <cmd>` to avoid manual activation.
- Commit `uv.lock` for applications; optional for libraries.
- This repo’s `.gitignore` ignores `.venv/` to keep virtualenvs out of version control.

### Directory Structure
```
apps/backend/
├── BUILD.bazel
├── main.py
├── pyproject.toml
└── uv.lock
```

### MODULE.bazel Addition
```python
bazel_dep(name = "rules_python", version = "0.31.0")
```

### BUILD.bazel
```python
load("@rules_python//python:defs.bzl", "py_binary")

py_binary(
    name = "server",
    srcs = ["main.py"],
    main = "main.py",
    deps = [
        # uv-managed dependencies would be imported here
    ],
)
```

### pyproject.toml
```toml
[project]
name = "backend"
version = "0.1.0"
dependencies = [
    "fastapi>=0.100.0",
    "uvicorn[standard]>=0.20.0",
]

[tool.uv]
dev-dependencies = [
    "pytest>=7.0.0",
]

# Lockfile guidance
# For applications, generate and commit a lockfile:
#   uv lock
# Local env management (no activation needed):
#   uv sync
#   uv run python -m backend
```

## React Frontend

### Directory Structure
```
apps/frontend/
├── BUILD.bazel
├── package.json
├── src/
│   ├── index.js
│   └── index.html
└── webpack.config.js
```

### MODULE.bazel Addition
```python
bazel_dep(name = "rules_js", version = "1.40.0")
bazel_dep(name = "rules_nodejs", version = "6.0.0")
```

### BUILD.bazel
```python
load("@rules_js//js:defs.bzl", "js_library", "js_binary")

js_library(
    name = "app",
    srcs = glob(["src/**/*.js", "src/**/*.jsx"]),
    deps = [
        "@npm//react",
        "@npm//react-dom",
    ],
)

js_binary(
    name = "dev_server",
    data = [":app"],
    entry_point = "src/index.js",
)
```

## Rust CLI Tool

### Directory Structure
```
tools/rust-cli/
├── BUILD.bazel
├── Cargo.toml
└── src/
    └── main.rs
```

### MODULE.bazel Addition
```python
bazel_dep(name = "rules_rust", version = "0.48.0")
```

### BUILD.bazel
```python
load("@rules_rust//rust:defs.bzl", "rust_binary")

rust_binary(
    name = "cli",
    srcs = glob(["src/**/*.rs"]),
    edition = "2021",
    deps = [
        "@crates//:clap",
        "@crates//:serde",
    ],
)
```

## gRPC API Contracts

### Directory Structure
```
packages/api-contracts/
├── BUILD.bazel
└── proto/
    └── user.proto
```

### MODULE.bazel Addition
```python
bazel_dep(name = "rules_proto", version = "5.3.0-21.7")
bazel_dep(name = "rules_proto_grpc", version = "4.5.0")
```

### BUILD.bazel
```python
load("@rules_proto//proto:defs.bzl", "proto_library")
load("@rules_proto_grpc_python//:defs.bzl", "python_grpc_library")

proto_library(
    name = "user_proto",
    srcs = ["proto/user.proto"],
    visibility = ["//visibility:public"],
)

python_grpc_library(
    name = "user_py_grpc",
    protos = [":user_proto"],
    visibility = ["//visibility:public"],
)
```

## AWS CDK Infrastructure

### Directory Structure
```
infra/cdk-app/
├── BUILD.bazel
├── app.py
├── cdk.json
└── requirements.txt
```

### BUILD.bazel
```python
load("@rules_python//python:defs.bzl", "py_binary")

py_binary(
    name = "synth",
    srcs = ["app.py"],
    main = "app.py",
    args = ["synth"],
    deps = [
        # CDK dependencies
    ],
    data = ["//apps/backend:server"],  # Dependency on backend
)

py_binary(
    name = "deploy",
    srcs = ["app.py"],
    main = "app.py",
    args = ["deploy"],
    deps = [
        # CDK dependencies
    ],
)
```

## Key Integration Patterns

1. **Hermetic Dependencies**: All system-level dependencies come from Nix (compilers, tools)
2. **Language Dependencies**: Package managers (uv, npm, cargo) handle language-specific deps
3. **Cross-Language**: Proto definitions generate code for multiple languages
4. **Infrastructure**: Infrastructure depends on application code for deployment validation
5. **Testing**: All projects include test targets that run in CI

## Implementation Checklist

When implementing any of these examples, ensure you:

### Required Files
- [ ] Add necessary `bazel_dep()` entries to MODULE.bazel
- [ ] Create BUILD.bazel file with appropriate targets
- [ ] Include test targets in BUILD.bazel
- [ ] Add language-specific configuration files (pyproject.toml, package.json, etc.)

### Validation Steps
```bash
# 1. Verify the target builds
bazel build //path/to/your:target

# 2. Verify tests pass
bazel test //path/to/your:test_target

# 3. Verify the application runs
bazel run //path/to/your:target

# 4. Check for any missing dependencies
bazel query "deps(//path/to/your:target)" --output graph

# 5. Verify integration with existing code
bazel test //...
```

### Common Issues and Solutions

**Build failures with missing dependencies**:
```bash
# Check what Bazel thinks the dependencies are
bazel query "deps(//your/target:name)" --output build

# Verify external dependencies are available
bazel query @npm//... # for JavaScript
bazel query @pypi//... # for Python
bazel query @crates//... # for Rust
```

**Tests failing in CI but not locally**:
- Ensure all files are included in `srcs` or `data`
- Check that test dependencies are properly declared
- Verify no undeclared dependencies on system tools

**Cross-language dependencies not working**:
- Ensure proto targets have `visibility = ["//visibility:public"]`
- Check that generated code targets are properly named
- Verify language-specific proto rules are correctly loaded

## Next Steps

After implementing any of these examples:

1. **Update Documentation**: Add your implementation to the appropriate agent guide in `docs/agents/`
2. **Add CI Integration**: Ensure your targets are tested in `.github/workflows/ci.yml`
3. **Consider Dependencies**: Think about how your code relates to other parts of the monorepo
4. **Monitor Performance**: Check build times and cache hit rates for your targets

For more detailed implementation guidance, see the technology-specific guides in `docs/agents/`.
