# Development Guide

This guide provides practical workflows, commands, and troubleshooting for developing in this Bazel + Nix monorepo.

## Environment Setup

### First-Time Setup

1. **Install Nix** with flakes enabled:
   ```bash
   # Install Nix
   curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
   
   # Verify flakes are enabled
   nix --version
   ```

2. **Clone and enter environment**:
   ```bash
   git clone <repository-url>
   cd general-monorepo-template
   nix develop  # This may take several minutes on first run
   ```

3. **Verify setup**:
   ```bash
   bazel version      # Should show Bazel 6.x
   which python       # Should point to Nix store
   which node         # Should point to Nix store
   ```

### Daily Development

```bash
# Enter development environment (run this in each new terminal)
nix develop

# Quick health check
bazel build //...
bazel test //...
```

## Common Workflows

### Adding New Code

1. **Create the directory structure**:
   ```bash
   mkdir -p apps/my-service/src
   ```

2. **Write your code**:
   ```python
   # apps/my-service/src/main.py
   def hello():
       return "Hello from my service!"
   ```

3. **Create BUILD.bazel**:
   ```python
   # apps/my-service/BUILD.bazel
   load("@rules_python//python:defs.bzl", "py_binary", "py_test")
   
   py_binary(
       name = "server",
       srcs = ["src/main.py"],
       main = "src/main.py",
   )
   
   py_test(
       name = "test",
       srcs = ["src/test_main.py"],
       deps = [":server"],
   )
   ```

4. **Test your changes**:
   ```bash
   bazel build //apps/my-service:server
   bazel test //apps/my-service:test
   bazel run //apps/my-service:server
   ```

### Managing Dependencies

#### Internal Dependencies

```python
# Reference other targets in the monorepo
py_binary(
    name = "server",
    srcs = ["main.py"],
    deps = [
        "//packages/database:client",     # Internal library
        "//packages/api:user_py_proto",   # Generated code
    ],
)
```

#### External Dependencies

**Python (uv)**:
```bash
# Add to pyproject.toml, then update BUILD.bazel
cd apps/my-python-service
uv add fastapi
# Update BUILD.bazel to reference @pypi//fastapi
```

**JavaScript (npm)**:
```bash
# Add to package.json, then update BUILD.bazel  
cd apps/my-frontend
npm install react
# Update BUILD.bazel to reference @npm//react
```

**Rust (cargo)**:
```bash
# Add to Cargo.toml, then update BUILD.bazel
cd tools/my-rust-tool
cargo add clap
# Update BUILD.bazel to reference @crates//:clap
```

### Working with Protocol Buffers

1. **Define the proto**:
   ```protobuf
   // packages/api/proto/user.proto
   syntax = "proto3";
   package user.v1;
   
   message User {
     string id = 1;
     string name = 2;
   }
   ```

2. **Create BUILD.bazel**:
   ```python
   # packages/api/BUILD.bazel
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

3. **Use in your code**:
   ```python
   # apps/backend/main.py
   from packages.api.user_pb2 import User
   
   user = User(id="123", name="Alice")
   ```

## Testing

### Running Tests

```bash
# Run all tests
bazel test //...

# Run tests for specific package
bazel test //apps/backend/...

# Run specific test
bazel test //apps/backend:unit_test

# Run tests with verbose output
bazel test //apps/backend:test --test_output=all

# Run tests that match pattern
bazel test //... --test_tag_filters=integration
```

### Writing Tests

```python
# apps/backend/test_main.py
import unittest
from apps.backend.main import hello

class TestMain(unittest.TestCase):
    def test_hello(self):
        self.assertEqual(hello(), "Hello World")

if __name__ == '__main__':
    unittest.main()
```

```python
# apps/backend/BUILD.bazel
py_test(
    name = "test",
    srcs = ["test_main.py"],
    deps = [":main"],
    tags = ["unit"],  # Use tags to categorize tests
)
```

## Change Impact Analysis

### Finding What Changed

```bash
# See what files changed
git diff --name-only HEAD~1

# Find Bazel targets that own changed files
bazel query 'owner(path/to/changed/file.py)'

# Find all targets affected by changes
bazel query "rdeps(//..., $(bazel query 'owner(path/to/changed/file.py)'))"
```

### Smart Testing

```bash
# Test only what's affected by your changes
CHANGED_FILES=$(git diff --name-only origin/main)
AFFECTED_TARGETS=$(bazel query "rdeps(//..., $(bazel query "owner($CHANGED_FILES)"))")
AFFECTED_TESTS=$(bazel query "kind('.*_test', $AFFECTED_TARGETS)")
bazel test $AFFECTED_TESTS
```

### Dependency Visualization

```bash
# Visualize dependencies of a target
bazel query "deps(//apps/backend:server)" --output graph | dot -Tpng > deps.png

# Find dependency paths between targets
bazel query "somepath(//apps/backend:server, //packages/database:client)"
```

## Debugging and Troubleshooting

### Common Issues

**"command not found" errors**:
```bash
# Make sure you're in the Nix environment
nix develop
which bazel  # Should show /nix/store/... path
```

**Build failures with "No such file or directory"**:
```bash
# Check if files are properly listed in BUILD.bazel
bazel query //path/to/target --output=build

# Verify file paths are correct
ls -la apps/my-service/
```

**Test failures in CI but not locally**:
```bash
# Make sure all dependencies are declared
bazel test //apps/my-service:test --verbose_failures

# Check for undeclared dependencies
bazel test //apps/my-service:test --experimental_strict_java_deps=error
```

### Build Performance

```bash
# Profile build performance
bazel build //... --profile=profile.json
bazel analyze-profile profile.json

# Check cache hit rates
bazel build //... --experimental_ui_show_cache_hit_rates

# Use remote cache (if available)
bazel build //... --remote_cache=https://your-cache-server
```

### Debugging Build Rules

```bash
# See exactly what Bazel is doing
bazel build //apps/backend:server -s

# Debug a specific target
bazel build //apps/backend:server --verbose_failures --sandbox_debug

# Show build actions
bazel aquery 'mnemonic("PythonZipper", //apps/backend:server)'
```

## CI/CD Integration

### GitHub Actions

The included `.github/workflows/ci.yml` provides:
- Nix environment setup
- Bazel caching
- Affected target testing
- Build artifact collection

### Local CI Simulation

```bash
# Simulate CI environment locally
nix develop --command bash -c "
  bazel test //... --test_output=errors
  bazel build //...
"
```

### Cache Management

```bash
# Clean local cache
bazel clean

# Clean everything (including external dependencies)
bazel clean --expunge

# See cache stats
bazel info

# Configure cache size
echo 'build --local_ram_resources=8192' >> .bazelrc.local
```

## Advanced Workflows

### Remote Development

```bash
# Use remote execution (if configured)
bazel build //... --remote_executor=grpc://your-remote-executor

# Use remote cache
bazel build //... --remote_cache=grpc://your-cache-server
```

### Cross-Platform Builds

```bash
# Build for different platforms
bazel build //apps/backend:server --platforms=@io_bazel_rules_go//go/toolchain:linux_amd64
bazel build //apps/backend:server --platforms=@io_bazel_rules_go//go/toolchain:darwin_amd64
```

### Custom Toolchains

```python
# Define custom toolchain in BUILD.bazel
toolchain(
    name = "my_custom_toolchain",
    toolchain = ":my_toolchain_impl",
    toolchain_type = "//tools:my_toolchain_type",
)
```

## Best Practices

### File Organization

- Keep BUILD.bazel files small and focused
- Group related targets in the same BUILD file
- Use consistent naming conventions
- Document complex build rules

### Dependency Management

- Minimize dependencies between packages
- Use interfaces/protocols for cross-package communication
- Avoid circular dependencies
- Prefer composition over inheritance

### Testing Strategy

- Write tests close to the code they test
- Use tags to organize test suites
- Include integration tests for critical paths
- Test failure scenarios and edge cases

### Performance Optimization

- Use `select()` for conditional dependencies
- Minimize glob patterns in `srcs`
- Cache expensive computations
- Profile builds regularly

This guide should get you productive quickly while following best practices for this monorepo architecture.