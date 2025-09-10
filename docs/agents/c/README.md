# C/C++ Agent Guide

This guide provides instructions for AI coding agents to work with C/C++ projects in this monorepo.

## Overview

C/C++ development in this monorepo uses Bazel with hermetic toolchains provided by Nix. This ensures consistent builds across environments and provides proper dependency management.

## Setup and Configuration

### Prerequisites

Ensure you're in the development environment:
```bash
nix develop
bazel version
```

### Bazel Configuration

Add to MODULE.bazel:
```python
bazel_dep(name = "rules_cc", version = "0.0.8")
```

For hermetic C++ toolchain from Nix, configure in WORKSPACE:
```python
load("@io_tweag_rules_nixpkgs//nixpkgs:nixpkgs.bzl", "nixpkgs_cc_configure")

nixpkgs_cc_configure(
    repository = "@nixpkgs",
)
```

## Project Structure

### Basic C++ Application
```
apps/cpp-service/
├── BUILD.bazel
├── main.cpp
├── src/
│   ├── lib.cpp
│   └── lib.h
└── test/
    └── lib_test.cpp
```

### BUILD.bazel Example
```python
load("@rules_cc//cc:defs.bzl", "cc_binary", "cc_library", "cc_test")

cc_library(
    name = "lib",
    srcs = ["src/lib.cpp"],
    hdrs = ["src/lib.h"],
    visibility = ["//visibility:private"],
)

cc_binary(
    name = "service",
    srcs = ["main.cpp"],
    deps = [":lib"],
)

cc_test(
    name = "lib_test",
    srcs = ["test/lib_test.cpp"],
    deps = [
        ":lib",
        "@googletest//:gtest_main",
    ],
)
```

## Implementation Patterns

### External Dependencies

For system libraries (via Nix):
```python
# In WORKSPACE
load("@io_tweag_rules_nixpkgs//nixpkgs:nixpkgs.bzl", "nixpkgs_package")

nixpkgs_package(
    name = "openssl",
    attribute_path = "openssl.dev",
    repository = "@nixpkgs",
)
```

For C++ libraries (via rules_foreign_cc):
```python
# In MODULE.bazel
bazel_dep(name = "rules_foreign_cc", version = "0.10.1")

# In BUILD.bazel
load("@rules_foreign_cc//foreign_cc:defs.bzl", "cmake")

cmake(
    name = "boost",
    lib_source = "@boost//:all",
    out_static_libs = ["libboost_system.a"],
)
```

### Header-Only Libraries

```python
cc_library(
    name = "header_only_lib",
    hdrs = glob(["include/**/*.h"]),
    includes = ["include"],
    visibility = ["//visibility:public"],
)
```

### Cross-Platform Builds

Use select() for platform-specific code:
```python
cc_library(
    name = "platform_lib",
    srcs = select({
        "@platforms//os:linux": ["linux_impl.cpp"],
        "@platforms//os:macos": ["macos_impl.cpp"],
        "//conditions:default": ["generic_impl.cpp"],
    }),
    hdrs = ["interface.h"],
)
```

## Testing

### Unit Tests with GoogleTest

```python
cc_test(
    name = "unit_test",
    srcs = ["test.cpp"],
    deps = [
        ":my_library",
        "@googletest//:gtest_main",
    ],
)
```

### Integration Tests

```python
cc_test(
    name = "integration_test",
    srcs = ["integration_test.cpp"],
    data = ["//testdata:config_files"],
    deps = [
        ":service_lib",
        "@googletest//:gtest_main",
    ],
)
```

## Deployment

### Static Linking

```python
cc_binary(
    name = "static_service",
    srcs = ["main.cpp"],
    deps = [":service_lib"],
    linkstatic = True,
)
```

### Container Images

```python
load("@rules_oci//oci:defs.bzl", "oci_image", "oci_tarball")

oci_image(
    name = "service_image",
    base = "@distroless_cc",
    entrypoint = ["/service"],
    tars = [":service"],
)
```

## Common Tasks

### Adding a New Library

1. Create directory structure
2. Write BUILD.bazel with cc_library target
3. Include headers in hdrs and sources in srcs
4. Set appropriate visibility
5. Add tests

### Adding External Dependencies

1. For system packages: Use nixpkgs_package
2. For C++ libraries: Use rules_foreign_cc or http_archive
3. Update BUILD files to reference new dependencies
4. Verify builds work: `bazel build //...`

### Performance Optimization

```python
cc_binary(
    name = "optimized_service",
    srcs = ["main.cpp"],
    copts = ["-O3", "-DNDEBUG"],
    linkopts = ["-flto"],
    deps = [":service_lib"],
)
```

## Troubleshooting

### Linker Errors
- Check that all dependencies are declared in deps
- Verify library names and paths
- Use `bazel query "deps(//your:target)"` to inspect dependency tree

### Header Not Found
- Ensure headers are listed in hdrs
- Check includes path is correct
- Verify visibility settings

### Cross-Compilation Issues
- Use platform-specific selects
- Configure toolchain for target platform
- Test on actual target environment

## Examples

See [language implementations](../../examples/language-implementations.md) for complete working examples of C++ services in this monorepo.
