# AI Agent Guides

This directory contains comprehensive guides for AI coding agents to effectively work with this monorepo template. Each guide provides specific instructions, patterns, and best practices for implementing features in different technology stacks.

## Available Guides

### Language-Specific Guides
- **[Python](python/)** - Backend services, APIs, data processing with uv dependency management
- **[JavaScript](javascript/)** - Frontend applications, Node.js services with npm/yarn
- **[Rust](rust/)** - CLI tools, high-performance services, system utilities

### Domain-Specific Guides  
- **[Infrastructure](infrastructure/)** - AWS CDK, Terraform, Kubernetes, deployment automation
- **[Protocols](protocols/)** - gRPC, Protocol Buffers, API contracts, service interfaces

## Guide Structure

Each guide follows a consistent structure:

```
technology/
├── README.md           # Overview and getting started
├── setup.md           # Initial project setup and configuration
├── patterns.md        # Common implementation patterns
├── dependencies.md    # Dependency management strategies
├── testing.md         # Testing approaches and frameworks
├── deployment.md      # Build and deployment configurations
└── examples/          # Complete example implementations
```

## Quick Start for Agents

1. **Understand the Foundation**: Read the main [Architecture Guide](../../ARCHITECTURE.md) to understand the Bazel + Nix integration
2. **Choose Your Technology**: Select the appropriate guide for your implementation task
3. **Follow the Patterns**: Use the established patterns for consistent integration
4. **Validate Implementation**: Use the provided testing and validation steps

## General Principles for All Technologies

### Integration Requirements
- All code must include proper BUILD.bazel files
- Dependencies must be declared explicitly
- Tests must be included for all new functionality
- Documentation should be updated for significant changes

### Bazel Integration
- Use appropriate `rules_*` for your technology
- Ensure hermetic builds with explicit dependencies  
- Include both unit and integration tests
- Follow visibility best practices

### Nix Integration
- System dependencies come from flake.nix
- Language-specific tools are available in the development shell
- All builds should be reproducible across environments

## Contributing New Guides

When adding support for new technologies:

1. Create the technology directory structure
2. Document setup and configuration requirements
3. Provide at least 2-3 working examples
4. Include testing strategies
5. Update this README with the new guide

## Agent Interaction Patterns

### Discovery Commands
```bash
# List all buildable targets
bazel query //...

# Find targets by type
bazel query "kind('py_binary', //...)"

# Analyze dependencies
bazel query "deps(//apps/backend:server)"
```

### Development Workflow
```bash
# Create new component
mkdir -p apps/my-service
# ... write code and BUILD.bazel ...
bazel build //apps/my-service:server
bazel test //apps/my-service:test
```

### Change Impact Analysis
```bash
# Find affected targets
bazel query "rdeps(//..., //packages/shared:utils)"

# Test only what changed
bazel test $(affected_targets)
```

These guides enable AI agents to quickly understand and implement solutions within the established monorepo patterns, ensuring consistency and maintainability across all contributions.