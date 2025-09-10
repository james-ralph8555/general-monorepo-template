# Rust Development Guide for AI Agents

This guide provides comprehensive instructions for AI agents to implement Rust applications and tools in this monorepo.

## Overview

Rust development in this monorepo uses:
- **Bazel with rules_rust**: For builds, testing, and dependency management
- **Cargo integration**: For crate management and compatibility
- **Hermetic builds**: Nix-provided Rust toolchain for consistency
- **Performance focus**: CLI tools, services, and system utilities
- **Modern patterns**: Async/await, error handling, and zero-cost abstractions

## Setup and Configuration

### Prerequisites

Ensure you're in the development environment:
```bash
nix develop
rustc --version  # Should show Rust 1.70+
cargo --version
```

### Bazel Configuration

Add to MODULE.bazel:
```python
bazel_dep(name = "rules_rust", version = "0.48.0")

# Rust toolchain configuration
rust = use_extension("@rules_rust//rust:extensions.bzl", "rust")
rust.toolchain(
    edition = "2021",
    versions = ["1.70.0"],
)
use_repo(rust, "rust_toolchains")

# Crate repository for external dependencies
crate = use_extension("@rules_rust//crate_universe:extension.bzl", "crate")
crate.from_cargo(
    name = "crates",
    cargo_lockfile = "//:Cargo.lock",
    manifests = [
        "//:Cargo.toml",
        "//apps/rust-cli:Cargo.toml",
        "//packages/rust-utils:Cargo.toml",
    ],
)
use_repo(crate, "crates")

register_toolchains("@rust_toolchains//:all")
```

### Workspace Cargo.toml

Create a workspace-level Cargo.toml:
```toml
[workspace]
members = [
    "apps/rust-cli",
    "packages/rust-utils",
    "tools/rust-tools/*",
]

resolver = "2"

[workspace.dependencies]
tokio = { version = "1.0", features = ["full"] }
serde = { version = "1.0", features = ["derive"] }
clap = { version = "4.0", features = ["derive"] }
anyhow = "1.0"
thiserror = "1.0"
tracing = "0.1"
tracing-subscriber = "0.3"
```

## Project Structure

### CLI Tool
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
│       ├── mod.rs
│       └── settings.rs
├── tests/
│   ├── integration_test.rs
│   └── fixtures/
└── benches/
    └── performance.rs
```

### Library Package
```
packages/rust-utils/
├── BUILD.bazel
├── Cargo.toml
├── src/
│   ├── lib.rs
│   ├── crypto/
│   │   ├── mod.rs
│   │   └── hashing.rs
│   ├── network/
│   │   ├── mod.rs
│   │   └── client.rs
│   └── errors.rs
├── tests/
│   └── lib_test.rs
└── examples/
    └── usage.rs
```

### Async Service
```
apps/rust-service/
├── BUILD.bazel
├── Cargo.toml
├── src/
│   ├── main.rs
│   ├── handlers/
│   │   ├── mod.rs
│   │   └── api.rs
│   ├── middleware/
│   │   ├── mod.rs
│   │   └── auth.rs
│   ├── models/
│   │   ├── mod.rs
│   │   └── user.rs
│   └── database/
│       ├── mod.rs
│       └── connection.rs
└── config/
    └── service.toml
```

## BUILD.bazel Patterns

### CLI Binary
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
        "@crates//:serde_json",
        "@crates//:tokio",
        "//packages/rust-utils:utils",
    ],
    data = ["//config:cli.toml"],
)

# Development binary with debug symbols
rust_binary(
    name = "cli_debug",
    srcs = glob(["src/**/*.rs"]),
    edition = "2021",
    compile_data = ["//config:cli.toml"],
    rustc_flags = ["-g"],
    deps = [
        "@crates//:clap",
        "@crates//:anyhow",
        "//packages/rust-utils:utils",
    ],
)
```

### Library Crate
```python
load("@rules_rust//rust:defs.bzl", "rust_library", "rust_test", "rust_doc")

rust_library(
    name = "utils",
    srcs = glob(["src/**/*.rs"]),
    edition = "2021",
    visibility = ["//visibility:public"],
    deps = [
        "@crates//:serde",
        "@crates//:thiserror",
        "@crates//:tracing",
    ],
)

rust_test(
    name = "unit_tests",
    crate = ":utils",
    edition = "2021",
)

rust_doc(
    name = "docs",
    crate = ":utils",
)
```

### Async Service
```python
rust_binary(
    name = "service",
    srcs = glob(["src/**/*.rs"]),
    edition = "2021",
    deps = [
        "@crates//:tokio",
        "@crates//:axum",
        "@crates//:tower",
        "@crates//:serde",
        "@crates//:tracing",
        "@crates//:tracing-subscriber",
        "//packages/rust-utils:utils",
    ],
    env = {
        "RUST_LOG": "info",
        "SERVICE_PORT": "8080",
    },
)
```

### Integration Tests
```python
rust_test(
    name = "integration_test",
    srcs = ["tests/integration_test.rs"],
    edition = "2021",
    deps = [
        ":service_lib",
        "@crates//:tokio-test",
        "@crates//:reqwest",
    ],
    data = [
        "//testdata:sample_config.toml",
    ],
)
```

## Cargo Configuration

### CLI Tool Cargo.toml
```toml
[package]
name = "rust-cli"
version = "0.1.0"
edition = "2021"

[[bin]]
name = "cli"
path = "src/main.rs"

[dependencies]
clap = { workspace = true }
anyhow = { workspace = true }
serde = { workspace = true }
serde_json = "1.0"
tokio = { workspace = true }
tracing = { workspace = true }
tracing-subscriber = { workspace = true }

# Local dependencies
rust-utils = { path = "../packages/rust-utils" }

[dev-dependencies]
tempfile = "3.0"
assert_cmd = "2.0"
predicates = "3.0"
```

### Library Cargo.toml
```toml
[package]
name = "rust-utils"
version = "0.1.0"
edition = "2021"

[lib]
name = "rust_utils"
path = "src/lib.rs"

[dependencies]
serde = { workspace = true }
thiserror = { workspace = true }
tracing = { workspace = true }
uuid = { version = "1.0", features = ["v4"] }
base64 = "0.21"

[dev-dependencies]
tokio-test = "0.4"
```

## Implementation Patterns

### CLI Application with Clap
```rust
// src/main.rs
use clap::{Parser, Subcommand};
use anyhow::Result;

#[derive(Parser)]
#[command(name = "mycli")]
#[command(about = "A CLI tool for managing deployments")]
struct Cli {
    #[command(subcommand)]
    command: Commands,

    #[arg(short, long)]
    verbose: bool,

    #[arg(short, long, default_value = "config.toml")]
    config: String,
}

#[derive(Subcommand)]
enum Commands {
    /// Build the application
    Build {
        #[arg(short, long)]
        target: Option<String>,
        
        #[arg(long)]
        release: bool,
    },
    /// Deploy to environment
    Deploy {
        #[arg(short, long)]
        environment: String,
        
        #[arg(long)]
        dry_run: bool,
    },
}

#[tokio::main]
async fn main() -> Result<()> {
    let cli = Cli::parse();
    
    // Initialize tracing
    tracing_subscriber::fmt::init();
    
    match cli.command {
        Commands::Build { target, release } => {
            commands::build::execute(target, release).await
        }
        Commands::Deploy { environment, dry_run } => {
            commands::deploy::execute(&environment, dry_run).await
        }
    }
}
```

### Error Handling with thiserror
```rust
// src/errors.rs
use thiserror::Error;

#[derive(Error, Debug)]
pub enum CliError {
    #[error("Configuration file not found: {path}")]
    ConfigNotFound { path: String },

    #[error("Invalid environment: {env}")]
    InvalidEnvironment { env: String },

    #[error("Network error: {0}")]
    Network(#[from] reqwest::Error),

    #[error("IO error: {0}")]
    Io(#[from] std::io::Error),

    #[error("Serialization error: {0}")]
    Serde(#[from] serde_json::Error),
}

pub type Result<T> = std::result::Result<T, CliError>;
```

### Async HTTP Client
```rust
// src/network/client.rs
use anyhow::Result;
use serde::{Deserialize, Serialize};
use std::time::Duration;

#[derive(Clone)]
pub struct ApiClient {
    client: reqwest::Client,
    base_url: String,
}

impl ApiClient {
    pub fn new(base_url: String) -> Self {
        let client = reqwest::Client::builder()
            .timeout(Duration::from_secs(30))
            .build()
            .expect("Failed to create HTTP client");

        Self { client, base_url }
    }

    pub async fn get<T>(&self, path: &str) -> Result<T>
    where
        T: for<'de> Deserialize<'de>,
    {
        let url = format!("{}{}", self.base_url, path);
        let response = self.client.get(&url).send().await?;
        
        if !response.status().is_success() {
            anyhow::bail!("HTTP {}: {}", response.status(), response.text().await?);
        }
        
        let data = response.json().await?;
        Ok(data)
    }

    pub async fn post<T, R>(&self, path: &str, data: &T) -> Result<R>
    where
        T: Serialize,
        R: for<'de> Deserialize<'de>,
    {
        let url = format!("{}{}", self.base_url, path);
        let response = self.client
            .post(&url)
            .json(data)
            .send()
            .await?;
            
        if !response.status().is_success() {
            anyhow::bail!("HTTP {}: {}", response.status(), response.text().await?);
        }
        
        let result = response.json().await?;
        Ok(result)
    }
}
```

### Configuration Management
```rust
// src/config/settings.rs
use serde::{Deserialize, Serialize};
use std::path::Path;
use anyhow::Result;

#[derive(Debug, Deserialize, Serialize)]
pub struct Config {
    pub service: ServiceConfig,
    pub database: DatabaseConfig,
    pub logging: LoggingConfig,
}

#[derive(Debug, Deserialize, Serialize)]
pub struct ServiceConfig {
    pub host: String,
    pub port: u16,
    pub workers: usize,
}

#[derive(Debug, Deserialize, Serialize)]
pub struct DatabaseConfig {
    pub url: String,
    pub pool_size: u32,
    pub timeout_seconds: u64,
}

#[derive(Debug, Deserialize, Serialize)]
pub struct LoggingConfig {
    pub level: String,
    pub format: String,
}

impl Config {
    pub fn from_file<P: AsRef<Path>>(path: P) -> Result<Self> {
        let content = std::fs::read_to_string(path)?;
        let config: Config = toml::from_str(&content)?;
        Ok(config)
    }

    pub fn from_env() -> Result<Self> {
        let config = Config {
            service: ServiceConfig {
                host: std::env::var("HOST").unwrap_or_else(|_| "0.0.0.0".to_string()),
                port: std::env::var("PORT")
                    .unwrap_or_else(|_| "8080".to_string())
                    .parse()?,
                workers: std::env::var("WORKERS")
                    .unwrap_or_else(|_| "4".to_string())
                    .parse()?,
            },
            database: DatabaseConfig {
                url: std::env::var("DATABASE_URL")?,
                pool_size: std::env::var("DB_POOL_SIZE")
                    .unwrap_or_else(|_| "10".to_string())
                    .parse()?,
                timeout_seconds: 30,
            },
            logging: LoggingConfig {
                level: std::env::var("LOG_LEVEL").unwrap_or_else(|_| "info".to_string()),
                format: std::env::var("LOG_FORMAT").unwrap_or_else(|_| "json".to_string()),
            },
        };
        Ok(config)
    }
}
```

### Async Web Service with Axum
```rust
// src/main.rs
use axum::{
    extract::State,
    http::StatusCode,
    response::Json,
    routing::{get, post},
    Router,
};
use serde::{Deserialize, Serialize};
use std::sync::Arc;
use tokio::net::TcpListener;
use tracing::info;

#[derive(Clone)]
struct AppState {
    config: Arc<Config>,
    // Add database pool, etc.
}

#[derive(Serialize)]
struct HealthResponse {
    status: String,
    version: String,
}

#[derive(Deserialize)]
struct CreateUserRequest {
    name: String,
    email: String,
}

#[derive(Serialize)]
struct User {
    id: String,
    name: String,
    email: String,
}

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    tracing_subscriber::fmt::init();

    let config = Config::from_env()?;
    let state = AppState {
        config: Arc::new(config),
    };

    let app = Router::new()
        .route("/health", get(health_check))
        .route("/users", post(create_user))
        .with_state(state.clone());

    let addr = format!("{}:{}", state.config.service.host, state.config.service.port);
    info!("Starting server on {}", addr);
    
    let listener = TcpListener::bind(&addr).await?;
    axum::serve(listener, app).await?;

    Ok(())
}

async fn health_check() -> Json<HealthResponse> {
    Json(HealthResponse {
        status: "ok".to_string(),
        version: env!("CARGO_PKG_VERSION").to_string(),
    })
}

async fn create_user(
    State(_state): State<AppState>,
    Json(payload): Json<CreateUserRequest>,
) -> Result<Json<User>, StatusCode> {
    // In real implementation, save to database
    let user = User {
        id: uuid::Uuid::new_v4().to_string(),
        name: payload.name,
        email: payload.email,
    };

    Ok(Json(user))
}
```

## Testing

### Unit Tests
```rust
// src/crypto/hashing.rs
use sha2::{Sha256, Digest};

pub fn hash_string(input: &str) -> String {
    let mut hasher = Sha256::new();
    hasher.update(input);
    format!("{:x}", hasher.finalize())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_hash_string() {
        let input = "hello world";
        let hash = hash_string(input);
        
        assert_eq!(hash.len(), 64); // SHA256 produces 64 hex chars
        assert_eq!(
            hash,
            "b94d27b9934d3e08a52e52d7da7dabfac484efe37a5380ee9088f7ace2efcde9"
        );
    }

    #[test]
    fn test_hash_empty_string() {
        let hash = hash_string("");
        assert_eq!(
            hash,
            "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"
        );
    }
}
```

### Integration Tests
```rust
// tests/integration_test.rs
use assert_cmd::Command;
use predicates::prelude::*;
use tempfile::TempDir;
use std::fs;

#[test]
fn test_cli_build_command() {
    let mut cmd = Command::cargo_bin("cli").unwrap();
    
    cmd.arg("build")
       .arg("--target")
       .arg("x86_64-unknown-linux-gnu")
       .assert()
       .success()
       .stdout(predicate::str::contains("Build completed"));
}

#[test]
fn test_cli_with_config_file() {
    let temp_dir = TempDir::new().unwrap();
    let config_path = temp_dir.path().join("config.toml");
    
    fs::write(&config_path, r#"
        [service]
        host = "127.0.0.1"
        port = 3000
    "#).unwrap();

    let mut cmd = Command::cargo_bin("cli").unwrap();
    cmd.arg("--config")
       .arg(config_path)
       .arg("build")
       .assert()
       .success();
}

#[tokio::test]
async fn test_api_health_endpoint() {
    let client = reqwest::Client::new();
    let response = client
        .get("http://localhost:8080/health")
        .send()
        .await
        .unwrap();
        
    assert!(response.status().is_success());
    
    let health: serde_json::Value = response.json().await.unwrap();
    assert_eq!(health["status"], "ok");
}
```

### Benchmarks
```rust
// benches/performance.rs
use criterion::{black_box, criterion_group, criterion_main, Criterion};
use rust_utils::crypto::hashing::hash_string;

fn bench_hash_string(c: &mut Criterion) {
    c.bench_function("hash_string", |b| {
        b.iter(|| hash_string(black_box("hello world")))
    });
}

fn bench_hash_large_string(c: &mut Criterion) {
    let large_string = "a".repeat(10000);
    c.bench_function("hash_large_string", |b| {
        b.iter(|| hash_string(black_box(&large_string)))
    });
}

criterion_group!(benches, bench_hash_string, bench_hash_large_string);
criterion_main!(benches);
```

## Performance Optimization

### Profile-Guided Optimization
```python
# Add to BUILD.bazel
rust_binary(
    name = "optimized_service",
    srcs = glob(["src/**/*.rs"]),
    edition = "2021",
    rustc_flags = [
        "-Ccodegen-units=1",
        "-Clto=fat",
        "-Copt-level=3",
        "-Ctarget-cpu=native",
    ],
    deps = [":service_deps"],
)
```

### Memory Profiling
```bash
# Profile memory usage
bazel run //tools/rust-cli:cli_debug --features=profiling

# Profile with valgrind
valgrind --tool=massif bazel-bin/tools/rust-cli/cli_debug
```

### Async Performance
```rust
// Use appropriate runtime configuration
#[tokio::main(flavor = "multi_thread", worker_threads = 4)]
async fn main() -> Result<()> {
    // Application code
}

// Or for single-threaded workloads
#[tokio::main(flavor = "current_thread")]
async fn main() -> Result<()> {
    // Application code
}
```

## Deployment

### Static Binary
```python
rust_binary(
    name = "static_cli",
    srcs = glob(["src/**/*.rs"]),
    edition = "2021",
    rustc_flags = [
        "-Ctarget-feature=+crt-static",
    ],
    deps = [":cli_deps"],
)
```

### Container Image
```python
load("@rules_oci//oci:defs.bzl", "oci_image")

oci_image(
    name = "service_image",
    base = "@distroless_cc",
    entrypoint = ["/service"],
    tars = [":service_tar"],
    env = {
        "RUST_LOG": "info",
        "PORT": "8080",
    },
)
```

### WebAssembly Target
```python
rust_binary(
    name = "wasm_module",
    srcs = glob(["src/**/*.rs"]),
    edition = "2021",
    platform = "@rules_rust//rust/platform:wasm32-unknown-unknown",
    rustc_flags = ["--crate-type=cdylib"],
    deps = [":wasm_deps"],
)
```

## FFI Integration

### C Bindings
```rust
// src/ffi.rs
use std::ffi::{CStr, CString};
use std::os::raw::c_char;

#[no_mangle]
pub extern "C" fn hash_string_ffi(input: *const c_char) -> *mut c_char {
    if input.is_null() {
        return std::ptr::null_mut();
    }

    let c_str = unsafe { CStr::from_ptr(input) };
    let rust_str = match c_str.to_str() {
        Ok(s) => s,
        Err(_) => return std::ptr::null_mut(),
    };

    let hash = crate::crypto::hashing::hash_string(rust_str);
    match CString::new(hash) {
        Ok(c_string) => c_string.into_raw(),
        Err(_) => std::ptr::null_mut(),
    }
}

#[no_mangle]
pub extern "C" fn free_string(ptr: *mut c_char) {
    if !ptr.is_null() {
        unsafe {
            drop(CString::from_raw(ptr));
        }
    }
}
```

### Python Bindings with PyO3
```rust
// src/python.rs
use pyo3::prelude::*;

#[pyfunction]
fn hash_string_py(input: &str) -> PyResult<String> {
    Ok(crate::crypto::hashing::hash_string(input))
}

#[pymodule]
fn rust_utils(_py: Python, m: &PyModule) -> PyResult<()> {
    m.add_function(wrap_pyfunction!(hash_string_py, m)?)?;
    Ok(())
}
```

## Common Tasks

### Adding External Dependencies

1. Add to workspace Cargo.toml `[workspace.dependencies]`
2. Reference in local Cargo.toml with `{ workspace = true }`
3. Update Bazel DEPS file: `bazel run @crates//:repin`
4. Add to BUILD.bazel deps: `"@crates//:package_name"`

### Cross-Compilation

```python
# For different targets
rust_binary(
    name = "cli_arm64",
    srcs = glob(["src/**/*.rs"]),
    platform = "@rules_rust//rust/platform:aarch64-unknown-linux-gnu",
    deps = [":cli_deps"],
)
```

### Conditional Compilation
```rust
#[cfg(target_os = "linux")]
fn platform_specific_code() {
    // Linux-specific implementation
}

#[cfg(target_os = "macos")]
fn platform_specific_code() {
    // macOS-specific implementation
}

#[cfg(feature = "redis")]
use redis::Commands;
```

## Troubleshooting

### Compilation Errors
- Check Rust edition compatibility
- Verify all dependencies are compatible versions
- Use `cargo tree` to inspect dependency graph
- Check for feature flag conflicts

### Performance Issues
- Profile with `cargo flamegraph`
- Use `cargo bench` for benchmarking
- Check async runtime configuration
- Consider compilation flags for optimization

### Memory Issues
- Use `valgrind` for memory leak detection
- Profile with `heaptrack` or similar tools
- Check for unnecessary clones and allocations
- Consider using `Cow<T>` for borrowed/owned data

### Build Issues
- Clean Bazel cache: `bazel clean`
- Update crate pins: `bazel run @crates//:repin`
- Check for platform-specific dependencies
- Verify Rust toolchain version compatibility

## Security Best Practices

### Input Validation
```rust
use serde::{Deserialize, Serialize};
use validator::{Validate, ValidationError};

#[derive(Debug, Deserialize, Validate)]
struct UserInput {
    #[validate(length(min = 1, max = 100))]
    name: String,
    
    #[validate(email)]
    email: String,
    
    #[validate(range(min = 18, max = 120))]
    age: u8,
}
```

### Secrets Management
```rust
// Never hardcode secrets
let api_key = std::env::var("API_KEY")
    .expect("API_KEY environment variable must be set");

// Use secure random generation
use rand::Rng;
let mut rng = rand::thread_rng();
let session_id: [u8; 32] = rng.gen();
```

### Safe Unsafe Code
```rust
// When unsafe is necessary, document why
unsafe fn read_memory(ptr: *const u8, len: usize) -> &'static [u8] {
    // SAFETY: Caller guarantees ptr is valid for len bytes
    // and the data lives for 'static lifetime
    std::slice::from_raw_parts(ptr, len)
}
```

## Examples

See [language implementations](../../examples/language-implementations.md) for complete examples of Rust applications in this monorepo.