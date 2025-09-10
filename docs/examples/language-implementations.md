# Language Implementation Examples

This document provides comprehensive working examples of how to integrate different technologies into the monorepo. These examples complement the detailed guides in `docs/agents/` and serve as practical templates for implementation.

## Overview

This monorepo supports multiple programming languages and technology stacks through a unified Bazel + Nix architecture. Each technology integration follows consistent patterns:

1. **Hermetic System Dependencies**: Core tools (compilers, runtimes) provided by Nix
2. **Language-Specific Package Management**: Native package managers for dependencies
3. **Bazel Build Integration**: Unified build system with cross-language dependencies
4. **Testing and Validation**: Comprehensive test coverage with CI integration
5. **Deployment Ready**: Container images and deployment configurations

## Prerequisites

Ensure you're properly set up:
```bash
# Enter the development environment
nix develop

# Verify tools are available
bazel version        # Build system
python --version     # Python 3.11+
node --version       # Node.js 18+
rustc --version      # Rust 1.70+
go version          # Go 1.21+
java --version      # Java 17+
```

For detailed setup instructions, see the technology-specific guides in `docs/agents/`.

## Python Development Examples

### FastAPI Web Service

**Directory Structure:**
```
apps/python-api/
├── BUILD.bazel
├── pyproject.toml
├── uv.lock
├── src/
│   ├── main.py
│   ├── api/
│   │   └── users.py
│   └── models/
│       └── user.py
└── tests/
    └── test_api.py
```

**Key Files:**

MODULE.bazel addition:
```python
bazel_dep(name = "rules_python", version = "0.31.0")

pip = use_extension("@rules_python//python/extensions:pip.bzl", "pip")
pip.parse(
    hub_name = "pypi",
    python_version = "3.11",
    requirements_lock = "//:requirements_lock.txt",
)
use_repo(pip, "pypi")
```

BUILD.bazel:
```python
load("@rules_python//python:defs.bzl", "py_binary", "py_library", "py_test")

py_library(
    name = "api_lib",
    srcs = glob(["src/**/*.py"]),
    deps = [
        "@pypi//fastapi",
        "@pypi//uvicorn",
        "@pypi//pydantic",
    ],
    visibility = ["//visibility:public"],
)

py_binary(
    name = "server",
    srcs = ["src/main.py"],
    main = "src/main.py",
    deps = [":api_lib"],
)

py_test(
    name = "test",
    srcs = glob(["tests/**/*.py"]),
    deps = [
        ":api_lib",
        "@pypi//pytest",
        "@pypi//httpx",
    ],
)
```

pyproject.toml:
```toml
[project]
name = "python-api"
version = "0.1.0"
dependencies = [
    "fastapi>=0.100.0",
    "uvicorn[standard]>=0.20.0",
    "pydantic>=2.0.0",
]

[tool.uv]
dev-dependencies = [
    "pytest>=7.0.0",
    "httpx>=0.24.0",
]
```

**Commands:**
```bash
# Setup dependencies
uv sync

# Development server
bazel run //apps/python-api:server

# Run tests
bazel test //apps/python-api:test
```

### Data Processing Pipeline

**Directory Structure:**
```
packages/data-utils/
├── BUILD.bazel
├── pyproject.toml
├── src/
│   ├── processors/
│   │   ├── csv_processor.py
│   │   └── json_processor.py
│   └── utils/
│       └── validation.py
└── tests/
    └── test_processors.py
```

BUILD.bazel:
```python
py_library(
    name = "data_utils",
    srcs = glob(["src/**/*.py"]),
    deps = [
        "@pypi//pandas",
        "@pypi//numpy",
        "@pypi//pydantic",
    ],
    visibility = ["//visibility:public"],
)
```

## JavaScript/TypeScript Examples

### React Single Page Application

**Directory Structure:**
```
apps/react-app/
├── BUILD.bazel
├── package.json
├── tsconfig.json
├── webpack.config.js
├── src/
│   ├── index.tsx
│   ├── App.tsx
│   ├── components/
│   │   ├── Header.tsx
│   │   └── UserList.tsx
│   └── __tests__/
│       └── App.test.tsx
└── public/
    └── index.html
```

**Key Files:**

MODULE.bazel addition:
```python
bazel_dep(name = "aspect_rules_js", version = "1.40.0")
bazel_dep(name = "aspect_rules_ts", version = "2.2.0")
bazel_dep(name = "aspect_rules_webpack", version = "0.14.0")

npm = use_extension("@aspect_rules_js//npm:extensions.bzl", "npm")
npm.npm_translate_lock(
    name = "npm",
    pnpm_lock = "//:pnpm-lock.yaml",
)
use_repo(npm, "npm")
```

BUILD.bazel:
```python
load("@aspect_rules_js//js:defs.bzl", "js_binary", "js_test")
load("@aspect_rules_ts//ts:defs.bzl", "ts_config", "ts_project")
load("@aspect_rules_webpack//webpack:defs.bzl", "webpack_bundle")

ts_config(
    name = "tsconfig",
    src = "tsconfig.json",
)

ts_project(
    name = "src",
    srcs = glob(["src/**/*.ts", "src/**/*.tsx"]),
    declaration = True,
    tsconfig = ":tsconfig",
    deps = [
        "@npm//react",
        "@npm//react-dom",
        "@npm//@types/react",
        "@npm//@types/react-dom",
    ],
)

webpack_bundle(
    name = "bundle",
    entry_point = "src/index.tsx",
    config = "webpack.config.js",
    deps = [":src"],
    data = glob(["public/**/*"]),
)

js_test(
    name = "test",
    data = [
        ":src",
        "@npm//jest",
        "@npm//@testing-library/react",
    ],
    entry_point = "jest.config.js",
)
```

### Node.js Express API

**Directory Structure:**
```
apps/node-api/
├── BUILD.bazel
├── package.json
├── tsconfig.json
├── src/
│   ├── server.ts
│   ├── routes/
│   │   └── users.ts
│   └── middleware/
│       └── auth.ts
└── tests/
    └── server.test.ts
```

BUILD.bazel:
```python
ts_project(
    name = "api_lib",
    srcs = glob(["src/**/*.ts"]),
    tsconfig = ":tsconfig",
    deps = [
        "@npm//express",
        "@npm//@types/express",
        "@npm//cors",
    ],
)

js_binary(
    name = "server",
    data = [":api_lib"],
    entry_point = "src/server.js",
    env = {"NODE_ENV": "production"},
)
```

## Rust Examples

### CLI Tool with Clap

**Directory Structure:**
```
tools/rust-cli/
├── BUILD.bazel
├── Cargo.toml
├── src/
│   ├── main.rs
│   ├── commands/
│   │   ├── mod.rs
│   │   ├── build.rs
│   │   └── deploy.rs
│   └── config/
│       └── mod.rs
└── tests/
    └── integration_test.rs
```

**Key Files:**

MODULE.bazel addition:
```python
bazel_dep(name = "rules_rust", version = "0.48.0")

rust = use_extension("@rules_rust//rust:extensions.bzl", "rust")
rust.toolchain(edition = "2021", versions = ["1.70.0"])
use_repo(rust, "rust_toolchains")

crate = use_extension("@rules_rust//crate_universe:extension.bzl", "crate")
crate.from_cargo(
    name = "crates",
    cargo_lockfile = "//:Cargo.lock",
    manifests = ["//:Cargo.toml"],
)
use_repo(crate, "crates")
```

BUILD.bazel:
```python
load("@rules_rust//rust:defs.bzl", "rust_binary", "rust_test")

rust_binary(
    name = "cli",
    srcs = glob(["src/**/*.rs"]),
    edition = "2021",
    deps = [
        "@crates//:clap",
        "@crates//:anyhow",
        "@crates//:serde",
        "@crates//:tokio",
    ],
)

rust_test(
    name = "integration_test",
    srcs = ["tests/integration_test.rs"],
    deps = [
        ":cli",
        "@crates//:assert_cmd",
        "@crates//:tempfile",
    ],
)
```

### Async Web Service

**Directory Structure:**
```
apps/rust-service/
├── BUILD.bazel
├── Cargo.toml
├── src/
│   ├── main.rs
│   ├── handlers/
│   │   └── users.rs
│   └── models/
│       └── user.rs
└── config/
    └── service.toml
```

BUILD.bazel:
```python
rust_binary(
    name = "service",
    srcs = glob(["src/**/*.rs"]),
    edition = "2021",
    deps = [
        "@crates//:axum",
        "@crates//:tokio",
        "@crates//:serde",
        "@crates//:tracing",
    ],
)
```

## Go Examples

### HTTP Service with Gin

**Directory Structure:**
```
apps/go-service/
├── BUILD.bazel
├── go.mod
├── main.go
├── internal/
│   ├── handlers/
│   │   └── users.go
│   └── config/
│       └── config.go
└── pkg/
    └── models/
        └── user.go
```

**Key Files:**

MODULE.bazel addition:
```python
bazel_dep(name = "rules_go", version = "0.46.0")
bazel_dep(name = "gazelle", version = "0.36.0")

go_deps = use_extension("@gazelle//:extensions.bzl", "go_deps")
go_deps.from_file(go_mod = "//:go.mod")
use_repo(go_deps, "com_github_gin_gonic_gin")
```

BUILD.bazel:
```python
load("@rules_go//go:def.bzl", "go_binary", "go_library", "go_test")

go_library(
    name = "service_lib",
    srcs = glob(["**/*.go"], exclude = ["main.go", "*_test.go"]),
    importpath = "github.com/yourorg/monorepo/apps/go-service",
    deps = [
        "@com_github_gin_gonic_gin//:gin",
        "@org_uber_go_zap//:zap",
    ],
)

go_binary(
    name = "service",
    embed = [":service_lib"],
    src = "main.go",
)

go_test(
    name = "service_test",
    srcs = glob(["**/*_test.go"]),
    embed = [":service_lib"],
)
```

### CLI Tool with Cobra

**Directory Structure:**
```
tools/go-cli/
├── BUILD.bazel
├── go.mod
├── main.go
└── cmd/
    ├── root.go
    └── build.go
```

BUILD.bazel:
```python
go_binary(
    name = "cli",
    srcs = glob(["**/*.go"]),
    deps = [
        "@com_github_spf13_cobra//:cobra",
        "@com_github_spf13_viper//:viper",
    ],
)
```

## Java Examples

### Spring Boot Application

**Directory Structure:**
```
apps/java-service/
├── BUILD.bazel
├── pom.xml
├── src/
│   ├── main/
│   │   ├── java/
│   │   │   └── com/yourorg/service/
│   │   │       ├── ServiceApplication.java
│   │   │       └── controller/
│   │   │           └── UserController.java
│   │   └── resources/
│   │       └── application.yml
│   └── test/
│       └── java/
│           └── com/yourorg/service/
```

**Key Files:**

MODULE.bazel addition:
```python
bazel_dep(name = "rules_java", version = "7.5.0")
bazel_dep(name = "rules_jvm_external", version = "6.0")

maven = use_extension("@rules_jvm_external//:extensions.bzl", "maven")
maven.install(
    artifacts = [
        "org.springframework.boot:spring-boot-starter-web:3.2.0",
        "org.springframework.boot:spring-boot-starter-test:3.2.0",
    ],
    repositories = ["https://repo1.maven.org/maven2"],
)
use_repo(maven, "maven")
```

BUILD.bazel:
```python
load("@rules_java//java:defs.bzl", "java_binary", "java_library", "java_test")

java_library(
    name = "service_lib",
    srcs = glob(["src/main/java/**/*.java"]),
    resources = glob(["src/main/resources/**/*"]),
    deps = [
        "@maven//:org_springframework_boot_spring_boot_starter_web",
    ],
)

java_binary(
    name = "service",
    main_class = "com.yourorg.service.ServiceApplication",
    runtime_deps = [":service_lib"],
)

java_test(
    name = "service_test",
    srcs = glob(["src/test/java/**/*.java"]),
    deps = [
        ":service_lib",
        "@maven//:org_springframework_boot_spring_boot_starter_test",
    ],
)
```

## Infrastructure Examples

### AWS CDK Stack

**Directory Structure:**
```
infra/aws-cdk/
├── BUILD.bazel
├── app.py
├── cdk.json
├── requirements.txt
└── stacks/
    ├── network_stack.py
    └── compute_stack.py
```

BUILD.bazel:
```python
load("@rules_python//python:defs.bzl", "py_binary")

py_binary(
    name = "synth",
    srcs = ["app.py"],
    main = "app.py",
    args = ["synth"],
    deps = [
        "@pypi//aws-cdk-lib",
        "@pypi//constructs",
    ],
)

py_binary(
    name = "deploy",
    srcs = ["app.py"],
    main = "app.py", 
    args = ["deploy"],
    deps = [
        "@pypi//aws-cdk-lib",
        "@pypi//constructs",
    ],
)
```

### Kubernetes Manifests

**Directory Structure:**
```
infra/k8s/
├── BUILD.bazel
├── base/
│   ├── kustomization.yaml
│   ├── deployment.yaml
│   └── service.yaml
└── overlays/
    ├── dev/
    └── prod/
```

BUILD.bazel:
```python
load("@io_bazel_rules_k8s//k8s:objects.bzl", "k8s_objects")

k8s_objects(
    name = "k8s_dev",
    objects = [
        "//infra/k8s/base:deployment",
        "//infra/k8s/base:service", 
    ],
)
```

## Container Images

### OCI Images with Bazel

MODULE.bazel addition:
```python
bazel_dep(name = "rules_oci", version = "1.5.0")

oci = use_extension("@rules_oci//oci:extensions.bzl", "oci")
oci.pull(
    name = "distroless_python",
    image = "gcr.io/distroless/python3",
    platforms = ["linux/amd64"],
)
use_repo(oci, "distroless_python")
```

BUILD.bazel patterns:
```python
load("@rules_oci//oci:defs.bzl", "oci_image", "oci_push")

oci_image(
    name = "app_image",
    base = "@distroless_python",
    entrypoint = ["/usr/bin/python3"],
    cmd = ["/app/main.py"],
    tars = ["//apps/python-api:app_tar"],
    env = {"PORT": "8080"},
)

oci_push(
    name = "push",
    image = ":app_image",
    repository = "gcr.io/my-project/app",
)
```

## Cross-Language Integration

### gRPC API Contracts

**Directory Structure:**
```
packages/api-contracts/
├── BUILD.bazel
├── proto/
│   ├── user.proto
│   └── service.proto
└── generated/
    ├── python/
    ├── typescript/
    └── rust/
```

**Key Files:**

MODULE.bazel addition:
```python
bazel_dep(name = "rules_proto", version = "5.3.0-21.7")
bazel_dep(name = "rules_proto_grpc", version = "4.5.0")
```

BUILD.bazel:
```python
load("@rules_proto//proto:defs.bzl", "proto_library")
load("@rules_proto_grpc//python:defs.bzl", "python_grpc_library")
load("@rules_proto_grpc//js:defs.bzl", "js_grpc_web_library")

proto_library(
    name = "api_proto",
    srcs = glob(["proto/*.proto"]),
    visibility = ["//visibility:public"],
)

# Python bindings
python_grpc_library(
    name = "api_py_grpc",
    protos = [":api_proto"],
    visibility = ["//visibility:public"],
)

# TypeScript bindings
js_grpc_web_library(
    name = "api_ts_grpc",
    protos = [":api_proto"],
    visibility = ["//visibility:public"],
)
```

### Shared Library Dependencies

**Cross-language utilities:**
```python
# Python utility used by multiple services
py_library(
    name = "shared_utils",
    srcs = ["utils.py"],
    visibility = ["//visibility:public"],
    deps = ["//packages/api-contracts:api_py_grpc"],
)

# TypeScript service consuming Python-generated proto
ts_project(
    name = "frontend_lib",
    deps = [
        "//packages/api-contracts:api_ts_grpc",
        "@npm//grpc-web",
    ],
)
```

## Key Integration Patterns

This monorepo demonstrates several important integration patterns:

### 1. Hermetic System Dependencies
- All compilers, runtimes, and system tools provided by Nix
- Consistent development environment across machines
- No "works on my machine" issues

### 2. Language-Specific Package Management
- Python: `uv` for fast dependency resolution and virtual environments
- JavaScript/TypeScript: `npm/pnpm` for package management
- Rust: `cargo` for crate dependencies
- Go: `go mod` for module management  
- Java: `maven` for JAR dependencies

### 3. Unified Build System
- Single `bazel build //...` command builds entire monorepo
- Incremental builds and intelligent caching
- Cross-language dependency tracking
- Parallel execution for fast builds

### 4. Cross-Language Code Generation
- Protocol Buffers generate type-safe clients in all languages
- Shared API contracts ensure consistency
- OpenAPI specifications for REST APIs

### 5. Infrastructure as Code
- CDK stacks written in Python
- Kubernetes manifests managed with Kustomize
- Container images built with Bazel rules
- Deployment dependencies on application code

### 6. Testing Strategy
- Unit tests in each language's native framework
- Integration tests that span multiple services
- Contract testing for API boundaries
- Infrastructure testing with realistic environments

## Implementation Checklist

When implementing any of these examples, follow this systematic approach:

### Planning Phase
- [ ] Review the appropriate guide in `docs/agents/` for detailed patterns
- [ ] Identify cross-language dependencies (shared libraries, proto contracts)
- [ ] Plan directory structure following monorepo conventions
- [ ] Choose appropriate testing strategy

### Setup Phase
- [ ] Add necessary `bazel_dep()` entries to MODULE.bazel
- [ ] Create language-specific configuration files:
  - Python: `pyproject.toml` with uv configuration
  - JavaScript/TypeScript: `package.json` and `tsconfig.json`
  - Rust: `Cargo.toml` and workspace configuration
  - Go: `go.mod` with module path
  - Java: `pom.xml` for Maven dependencies
- [ ] Set up package manager lockfiles (`uv.lock`, `pnpm-lock.yaml`, etc.)

### Implementation Phase
- [ ] Create BUILD.bazel file with appropriate targets:
  - Library targets for reusable code
  - Binary targets for executables
  - Test targets for all code
  - Data dependencies for configuration files
- [ ] Implement core functionality following language best practices
- [ ] Add comprehensive error handling and logging
- [ ] Include configuration management

### Validation Phase
```bash
# 1. Verify clean build from scratch
bazel clean && bazel build //path/to/your:target

# 2. Run all tests
bazel test //path/to/your:test_target

# 3. Verify the application works end-to-end
bazel run //path/to/your:target

# 4. Check dependency graph for issues
bazel query "deps(//path/to/your:target)" --output graph

# 5. Verify no regressions in existing code
bazel test //...

# 6. Test container images if applicable
bazel build //path/to/your:image
```

### Integration Phase
- [ ] Update CI/CD configuration to include new targets
- [ ] Add monitoring and observability hooks
- [ ] Update relevant documentation
- [ ] Consider deployment strategies

## Common Issues and Solutions

### Build Failures

**Missing system dependencies:**
```bash
# Check what tools are available in Nix environment
which python java node rustc go

# Verify Bazel rules are properly loaded
bazel query @rules_python//... --output package
```

**Dependency resolution issues:**
```bash
# For Python
uv lock --upgrade  # Regenerate lockfile
bazel run @pypi//:requirements.update  # Update Bazel deps

# For JavaScript  
pnpm install       # Update lockfile
bazel run @npm//:npm_update  # Update Bazel deps

# For Rust
cargo update       # Update Cargo.lock
bazel run @crates//:repin  # Update Bazel deps
```

### Runtime Issues

**Environment configuration:**
- Ensure all environment variables are declared in BUILD.bazel `env` attributes
- Use configuration files in `data` dependencies
- Avoid hardcoded paths or system-specific assumptions

**Cross-language communication:**
- Verify proto definitions are properly versioned
- Check that gRPC services use consistent serialization
- Test API contracts with integration tests

### Performance Problems

**Build performance:**
```bash
# Enable build profiling
bazel build --profile=profile.json //...

# Check for missing incremental build optimizations
bazel build --experimental_profile_include_target_label //...

# Use remote caching if available
bazel build --remote_cache=grpc://cache.example.com //...
```

**Runtime performance:**
- Profile applications under realistic load
- Monitor memory usage and GC behavior
- Use appropriate container resource limits

## Best Practices Summary

### Code Organization
1. **Single Responsibility**: Each package/module has a clear, focused purpose
2. **Dependency Management**: Explicit dependencies, no hidden coupling
3. **Interface Design**: Clean APIs with proper error handling
4. **Testing**: Comprehensive test coverage at unit and integration levels

### Bazel Integration  
1. **Granular Targets**: Small, focused build targets for better caching
2. **Proper Visibility**: Use `//visibility:public` sparingly, prefer package-level visibility
3. **Data Dependencies**: Include all runtime dependencies in `data` attributes
4. **Test Organization**: Separate unit and integration tests with appropriate tags

### Development Workflow
1. **Incremental Development**: Build and test frequently during development
2. **Local Validation**: Always test locally before pushing changes
3. **Documentation**: Keep README files and agent guides up-to-date
4. **Performance Monitoring**: Track build times and cache hit rates

## Getting Help

If you encounter issues:

1. **Check Agent Guides**: Detailed patterns in `docs/agents/[language]/README.md`
2. **Review Examples**: Working examples in this document
3. **Query Dependencies**: Use `bazel query` to understand dependency relationships
4. **Build Analysis**: Use `bazel info` and build profiles to debug performance
5. **Community Resources**: Bazel documentation, language-specific guides

For complex integration scenarios, consider creating a minimal reproduction case and iterating from there.
