# Nix Integration Guide for AI Agents

This guide provides instructions for AI coding agents to work with Nix integration in this monorepo. Nix provides hermetic dependencies and reproducible builds across all languages and tools.

## Overview

This monorepo uses Nix for:
- **System Dependencies**: Compilers, tools, and system libraries
- **Development Environment**: Consistent shell with all required tools
- **Hermetic Builds**: Bazel builds use Nix-provided dependencies
- **Reproducibility**: Same builds across different machines and CI

## Setup and Configuration

### Prerequisites

Ensure Nix is installed and you're in the development environment:
```bash
nix develop
# This provides all tools: bazel, gcc, python, node, etc.
```

### Nix Integration with Bazel

The integration is handled through `rules_nixpkgs` in WORKSPACE:

```python
load("@io_tweag_rules_nixpkgs//nixpkgs:nixpkgs.bzl", 
     "nixpkgs_git_repository", 
     "nixpkgs_package",
     "nixpkgs_cc_configure",
     "nixpkgs_python_configure")

nixpkgs_git_repository(
    name = "nixpkgs",
    revision = "23.11",  # Pin to specific version
    sha256 = "...",
)

# Configure hermetic toolchains
nixpkgs_cc_configure(repository = "@nixpkgs")
nixpkgs_python_configure(repository = "@nixpkgs")
```

## Common Nix Patterns

### Adding System Dependencies

For system packages needed by your applications:

```python
# In WORKSPACE
nixpkgs_package(
    name = "postgresql",
    attribute_path = "postgresql",
    repository = "@nixpkgs",
)

nixpkgs_package(
    name = "redis",
    attribute_path = "redis",
    repository = "@nixpkgs",
)
```

### Language-Specific Toolchains

#### Python
```python
nixpkgs_python_configure(
    name = "nixpkgs_python_toolchain",
    python3_attribute_path = "python311",
    repository = "@nixpkgs",
)
```

#### Node.js
```python
load("@io_tweag_rules_nixpkgs//nixpkgs:toolchains/nodejs.bzl", "nixpkgs_nodejs_configure")

nixpkgs_nodejs_configure(
    name = "nixpkgs_nodejs",
    attribute_path = "nodejs_18",
    repository = "@nixpkgs",
)
```

#### Rust
```python
load("@io_tweag_rules_nixpkgs//nixpkgs:toolchains/rust.bzl", "nixpkgs_rust_configure")

nixpkgs_rust_configure(
    name = "nixpkgs_rust",
    repository = "@nixpkgs",
)
```

### Development Tools

For development-only tools (not in production builds):

```python
nixpkgs_package(
    name = "jq",
    attribute_path = "jq",
    repository = "@nixpkgs",
)

nixpkgs_package(
    name = "curl",
    attribute_path = "curl",
    repository = "@nixpkgs",
)
```

## Flake.nix Configuration

The `flake.nix` at the repo root defines the development environment:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            # Build tools
            bazel_6
            gcc
            
            # Language runtimes
            python311
            nodejs_18
            rustc
            cargo
            go
            
            # Development tools
            git
            jq
            curl
            
            # Language-specific tools
            (python311.withPackages (ps: with ps; [ pip uv ]))
          ];
        };
      });
}
```

## Implementation Patterns

### Package Configuration Files

For packages requiring configuration files:

```python
nixpkgs_package(
    name = "nginx",
    attribute_path = "nginx",
    repository = "@nixpkgs",
    build_file_content = """
package(default_visibility = ["//visibility:public"])

filegroup(
    name = "bin",
    srcs = glob(["bin/**"]),
)

filegroup(
    name = "conf",
    srcs = glob(["conf/**"]),
)
"""
)
```

### Custom Nix Expressions

For complex package requirements:

```python
nixpkgs_package(
    name = "custom_python",
    repository = "@nixpkgs",
    nix_file_content = """
    let pkgs = import <nixpkgs> {};
    in pkgs.python311.withPackages (ps: with ps; [
      flask
      requests
      pytest
    ])
    """,
)
```

### Cross-Platform Builds

Handle platform differences:

```python
nixpkgs_package(
    name = "platform_tool",
    attribute_path = select({
        "@platforms//os:linux": "linuxPackages.tool",
        "@platforms//os:macos": "darwin.tool", 
        "//conditions:default": "tool",
    }),
    repository = "@nixpkgs",
)
```

## Testing

### Testing Nix Integration

Verify Nix packages are available:

```python
sh_test(
    name = "nix_tools_test",
    srcs = ["test_nix_tools.sh"],
    data = [
        "@postgresql//:bin",
        "@redis//:bin",
    ],
)
```

### Development Environment Tests

Test that development shell has required tools:

```bash
#!/bin/bash
# test_dev_env.sh
set -e

# Test tools are available
command -v bazel
command -v python3
command -v node
command -v rustc

# Test versions are as expected
python3 --version | grep "3.11"
node --version | grep "v18"
```

## Deployment

### Container Images

Use Nix packages in container images:

```python
load("@rules_oci//oci:defs.bzl", "oci_image")

oci_image(
    name = "app_image",
    base = "@nixpkgs_distroless",
    tars = [
        ":app",
        "@postgresql//:bin",
    ],
    entrypoint = ["/app"],
)
```

### Static Binaries

Create self-contained binaries:

```python
nixpkgs_package(
    name = "static_glibc",
    attribute_path = "glibc.static",
    repository = "@nixpkgs",
)

cc_binary(
    name = "static_app",
    srcs = ["main.c"],
    linkstatic = True,
    deps = ["@static_glibc//:lib"],
)
```

## Common Tasks

### Adding a New System Dependency

1. Identify the Nix package name: `nix search nixpkgs <package>`
2. Add nixpkgs_package rule to WORKSPACE
3. Reference in BUILD files as `@package_name//:bin` or `@package_name//:lib`
4. Test the build: `bazel build //...`

### Updating Nix Pin

1. Update revision in nixpkgs_git_repository
2. Update sha256 hash
3. Test all builds: `bazel test //...`
4. Update flake.lock: `nix flake update`

### Debugging Nix Integration

Check what Nix provides:
```bash
# Inspect package contents
nix-store -q --tree $(nix-build '<nixpkgs>' -A postgresql --no-out-link)

# Check build inputs
bazel query "deps(@postgresql//:bin)" --output graph
```

## Troubleshooting

### Package Not Found
- Verify package exists in Nix: `nix search nixpkgs <name>`
- Check attribute path is correct
- Ensure nixpkgs version includes the package

### Build Failures
- Check if system dependencies are declared
- Verify Nix packages are properly exposed in BUILD files
- Use `bazel clean` to reset build state

### Development Environment Issues
- Ensure `nix develop` is working
- Check flake.nix syntax: `nix flake check`
- Verify all tools are in buildInputs

### Cross-Platform Problems
- Use conditional expressions for platform-specific packages
- Test on target platforms
- Check that Nix packages support target architecture

## Advanced Patterns

### Nix Overlays

Customize package versions:

```nix
# In flake.nix
overlays = [
  (final: prev: {
    python311 = prev.python311.override {
      packageOverrides = python-final: python-prev: {
        # Custom package versions
      };
    };
  })
];
```

### Remote Caching

Cache Nix builds:

```bash
# In CI
nix-store --option substituters https://cache.nixos.org
nix-store --option trusted-public-keys cache.nixos.org-1:...
```

## Examples

See [language implementations](../../examples/language-implementations.md) for examples of Nix integration with specific languages and tools.