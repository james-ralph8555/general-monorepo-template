# AI Agent Development Guides

This directory contains comprehensive guides for AI coding agents to effectively work with this monorepo template. Each guide provides specific instructions, patterns, and best practices for implementing robust, production-ready features in different technology stacks.

## Available Technology Guides

### Backend Languages
- **[Python](python/)** - Web APIs (FastAPI/Django), data processing, ML pipelines with uv dependency management
- **[Go](go/)** - High-performance HTTP services, CLI tools, microservices with concurrent patterns  
- **[Java](java/)** - Enterprise applications, Spring Boot services, Maven integration with Bazel
- **[Rust](rust/)** - System tools, async web services, performance-critical applications

### Frontend & Full-Stack
- **[JavaScript/TypeScript](javascript/)** - React applications, Node.js APIs, modern build tooling

### Infrastructure & DevOps
- **[Infrastructure](infrastructure/)** - AWS CDK, Terraform, Kubernetes, deployment automation, monitoring
- **[C/C++](c/)** - System programming, native libraries, performance-critical components

### Platform Integration
- **[Nix](nix/)** - Hermetic dependency management, reproducible builds, development environments

## What Each Guide Contains

Every technology guide is a comprehensive, self-contained resource that includes:

### Core Information
- **Overview & Setup** - Technology stack introduction and initial configuration
- **Project Structure** - Directory layouts and file organization patterns
- **BUILD.bazel Patterns** - Bazel integration with language-specific rules
- **Implementation Examples** - Real-world code patterns and best practices

### Development Workflow
- **Dependency Management** - Package managers integration (uv, npm, cargo, etc.)
- **Testing Strategies** - Unit, integration, and end-to-end testing approaches
- **Performance Optimization** - Language-specific optimization techniques
- **Deployment** - Container images, static binaries, and production configurations

### Troubleshooting & Best Practices
- **Common Issues** - Solutions to frequent problems
- **Security Guidelines** - Security best practices for each technology
- **Monitoring & Observability** - Logging, metrics, and debugging approaches

## Quick Start for AI Agents

### 1. Understand the Foundation
- Read the monorepo [Overview](../../README.md) for high-level architecture
- Review [examples/language-implementations.md](../examples/language-implementations.md) for practical templates
- Understand that this uses **Bazel + Nix** for hermetic, reproducible builds

### 2. Choose Your Technology Stack
Select the appropriate guide based on your implementation requirements:
- **Backend APIs**: Python (FastAPI), Go (Gin), Java (Spring Boot)
- **Frontend**: JavaScript/TypeScript (React, Node.js)
- **CLI Tools**: Rust, Go, or Python depending on performance needs
- **Infrastructure**: Infrastructure guide for CDK, Terraform, Kubernetes
- **System Programming**: C/C++ for native libraries and performance-critical code

### 3. Follow the Established Patterns
Each guide provides battle-tested patterns for:
- Bazel BUILD.bazel file configuration
- Cross-language dependency management
- Testing and validation approaches
- Container image creation and deployment

### 4. Validate Your Implementation
Every guide includes validation steps to ensure your code integrates properly:
```bash
# Build your component
bazel build //path/to/your:target

# Run tests
bazel test //path/to/your:test

# Verify no regressions
bazel test //...
```

## Core Architecture Principles

This monorepo enforces consistent patterns across all technologies:

### Hermetic Build System (Bazel + Nix)
- **Bazel** provides fast, incremental builds with intelligent caching
- **Nix** ensures reproducible development environments with pinned system dependencies
- **Integration** creates fully hermetic builds that work identically across all machines

### Dependency Management Strategy
- **System Dependencies**: Managed by Nix (compilers, runtimes, tools)
- **Language Dependencies**: Native package managers (uv, npm, cargo, maven)
- **Cross-Language**: Protocol Buffers for type-safe service contracts
- **Build Dependencies**: Explicitly declared in BUILD.bazel files

### Testing Philosophy
- **Unit Tests**: Fast, isolated tests for individual components
- **Integration Tests**: Service-to-service communication testing  
- **Contract Tests**: API compatibility across language boundaries
- **Infrastructure Tests**: Deployment and configuration validation

### Security & Quality Standards
- **Input Validation**: All external inputs validated at service boundaries
- **Secrets Management**: Environment variables and secret management services
- **Container Security**: Distroless images, non-root users, minimal attack surface
- **Code Quality**: Linting, formatting, and static analysis integrated into builds

## Essential Commands for AI Agents

### Project Discovery
```bash
# Enter development environment
nix develop

# List all available build targets
bazel query //...

# Find targets by type
bazel query "kind('py_binary', //...)"        # Python executables
bazel query "kind('rust_binary', //...)"      # Rust executables  
bazel query "kind('js_binary', //...)"        # JavaScript executables

# Analyze dependencies  
bazel query "deps(//apps/backend:server)"     # What does this target depend on?
bazel query "rdeps(//..., //packages/shared:utils)"  # What depends on this?
```

### Development Workflow
```bash
# Create new component
mkdir -p apps/my-service
# Write implementation code
# Create BUILD.bazel with appropriate targets

# Build and test incrementally
bazel build //apps/my-service:server
bazel test //apps/my-service:test

# Run the service locally
bazel run //apps/my-service:server
```

### Validation & Debugging
```bash
# Test everything (full validation)
bazel test //...

# Build specific targets with detailed output
bazel build //apps/my-service:server --verbose_failures

# Analyze build performance
bazel build //... --profile=profile.json

# Check for unused dependencies
bazel query "allpaths(//apps/my-service:server, @some_external_dep//...)"
```

### Cross-Language Integration
```bash
# Generate language bindings from proto
bazel build //packages/api-contracts:python_grpc
bazel build //packages/api-contracts:typescript_grpc

# Test cross-service communication
bazel test //tests/integration:service_to_service_test

# Build container images
bazel build //apps/my-service:image
```

## Implementation Success Checklist

For any new feature or service, ensure:

### ✅ Code Quality
- [ ] Follows language-specific guide patterns
- [ ] Includes comprehensive error handling
- [ ] Has proper logging and observability
- [ ] Validates all external inputs

### ✅ Bazel Integration  
- [ ] BUILD.bazel file with appropriate targets
- [ ] All dependencies explicitly declared
- [ ] Proper visibility declarations
- [ ] Builds successfully with `bazel build //...`

### ✅ Testing Coverage
- [ ] Unit tests for core logic
- [ ] Integration tests for service interactions
- [ ] Tests pass with `bazel test //...`
- [ ] Performance tests for critical paths

### ✅ Documentation
- [ ] README with setup and usage instructions
- [ ] API documentation for public interfaces
- [ ] Troubleshooting section for common issues
- [ ] Integration examples for other services

These guides enable AI agents to rapidly implement robust, production-ready features that seamlessly integrate with the existing monorepo architecture while maintaining high standards for code quality, security, and maintainability.