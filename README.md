# General Monorepo Template

A polyglot monorepo template built with Bazel and Nix for hermetic, reproducible builds across multiple languages and technologies.

## Philosophy

### Why Bazel + Nix?

This template combines the power of two complementary tools to solve critical challenges in polyglot development:

**Bazel** provides:
- Fine-grained dependency management within your source code
- Incremental builds and remote caching
- Multi-language build orchestration
- Precise change detection and affected target analysis

**Nix** provides:
- Hermetic system-level dependencies (compilers, toolchains, libraries)
- Perfectly reproducible development environments
- Version-pinned external dependencies
- Access to the vast nixpkgs ecosystem

Together, they create a fully hermetic build environment that:
- Closes Bazel's reproducibility gaps by providing explicit, version-controlled toolchains
- Scales from single projects to massive monorepos
- Enables true "works on my machine" → "works everywhere" reproducibility

## Quick Start

### Prerequisites
- [Nix](https://nixos.org/download.html) with flake support enabled
- Git

### Setup
```bash
# Clone or create from template
git clone <your-repo> && cd <your-repo>

# Enter development environment (installs all tools)
nix develop

# Verify setup
bazel build //...
bazel test //...
```

### Activate flake.nix
Use the Nix flake dev shell to get all required tools (Bazel, Python, Node, Rust, Go, Graphviz, etc.) on your PATH before running commands:

```bash
# Interactive shell (from repo root)
nix develop

# Explicitly target the default dev shell
nix develop .#default

# One-shot: run a command inside the dev shell without entering it
nix develop -c bazel build //...
nix develop -c bazel test //...
```

Optional: auto-activate the dev shell when you cd into the repo using direnv + nix-direnv:

```bash
# Install direnv and nix-direnv (one-time, via your OS/Nix)
# Then in the repo root:
echo 'use flake' > .envrc
direnv allow
```

## Repository Structure

```
├── apps/           # Deployable applications (web servers, mobile apps)
├── packages/       # Shared libraries and modules  
├── infra/          # Infrastructure as Code (AWS CDK, Terraform, etc.)
├── tools/          # Repository-wide tooling and utilities
├── nix/            # Nix configuration for system dependencies
├── docs/           # Documentation and guides
└── .github/        # CI/CD workflows
```

## Core Commands

### Building and Testing
```bash
# Build all targets
bazel build //...

# Test all targets  
bazel test //...

# Build specific target
bazel build //apps/backend:server

# Run application
bazel run //apps/frontend:dev_server
```

### Development Workflows
```bash
# List all buildable targets
bazel query //...

# Find dependencies of a target
bazel query "deps(//apps/backend:server)"

# Find what depends on a target (reverse deps)
bazel query "rdeps(//..., //packages/api:user_proto)"

# Visualize dependency graph (uses Graphviz `dot`, included in the dev shell)
bazel query "deps(//apps/backend:server)" --output graph | dot -Tpng > deps.png
```

### Change Impact Analysis
```bash
# Find affected targets for changed files
bazel query "rdeps(//..., $(bazel query 'owner(path/to/changed/file)'))"

# Test only affected targets
bazel test $(bazel query "kind('.*_test', rdeps(//..., $(bazel query 'owner(path/to/changed/file)')))")
```

## Key Features

- **🔒 Hermetic builds** - All dependencies explicitly declared and version-pinned
- **🌍 Language agnostic** - Add any language with appropriate Bazel rules  
- **♻️ Reproducible** - Identical builds across all environments
- **⚡ Incremental** - Only rebuild what changed
- **🔍 Precise** - Fine-grained dependency tracking
- **☁️ Scalable** - Remote build and test execution
- **🚀 CI/CD ready** - GitHub Actions with smart change detection

## Technology Support

This template supports adding any technology through Bazel's extensive rule ecosystem:

- **Backend**: Python (uv), Go, Rust, Java, Scala, C++
- **Frontend**: JavaScript/TypeScript (npm), React, Angular, Vue
- **Mobile**: Android, iOS (with proper toolchains)
- **Data**: Protocol Buffers, gRPC, Apache Beam
- **Infrastructure**: AWS CDK, Terraform, Kubernetes manifests
- **Documentation**: Sphinx, MkDocs, GitBook

## Documentation

- **[Architecture Guide](ARCHITECTURE.md)** - System design and integration patterns
- **[Development Guide](DEVELOPMENT.md)** - Detailed workflows and troubleshooting
- **[Language Examples](docs/examples/language-implementations.md)** - Implementation patterns for different technologies
- **[Agent Guides](docs/agents/)** - Documentation for AI coding agents (coming soon)

## Contributing

1. Make changes in feature branches
2. Run `bazel test //...` to verify all tests pass
3. Use `bazel query` commands to understand impact
4. Submit PR with clear description of changes

## License

[Add your license here]
