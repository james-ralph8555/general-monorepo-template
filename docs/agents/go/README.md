# Go Development Guide for AI Agents

This guide provides comprehensive instructions for AI agents to work with Go projects in this monorepo.

## Overview

Go development in this monorepo uses:
- **Bazel with rules_go**: For builds, testing, and dependency management
- **Go modules**: For package management and versioning
- **Hermetic builds**: Nix-provided Go toolchain for consistency
- **Modern patterns**: HTTP services, CLI tools, and microservices
- **Performance focus**: Concurrent programming and efficient resource usage

## Setup and Configuration

### Prerequisites

Ensure you're in the development environment:
```bash
nix develop
go version  # Should show Go 1.21+
```

### Bazel Configuration

Add to MODULE.bazel:
```python
bazel_dep(name = "rules_go", version = "0.46.0")
bazel_dep(name = "gazelle", version = "0.36.0")

# Go toolchain configuration
go_sdk = use_extension("@rules_go//go:extensions.bzl", "go_sdk")
go_sdk.download(version = "1.21.5")

# Gazelle for BUILD file generation
go_deps = use_extension("@gazelle//:extensions.bzl", "go_deps")
go_deps.from_file(go_mod = "//:go.mod")
use_repo(go_deps, "com_github_gin_gonic_gin", "com_github_spf13_cobra")
```

### Workspace Configuration

Create a workspace-level go.mod:
```go
module github.com/yourorg/monorepo

go 1.21

require (
    github.com/gin-gonic/gin v1.9.1
    github.com/spf13/cobra v1.8.0
    github.com/spf13/viper v1.18.2
    github.com/stretchr/testify v1.8.4
    go.uber.org/zap v1.26.0
    golang.org/x/sync v0.6.0
)
```

## Project Structure

### CLI Application
```
tools/go-cli/
├── BUILD.bazel
├── go.mod
├── main.go
├── cmd/
│   ├── root.go
│   ├── build.go
│   └── deploy.go
├── internal/
│   ├── config/
│   │   └── config.go
│   └── utils/
│       └── helpers.go
├── pkg/
│   └── client/
│       └── api.go
└── test/
    └── integration_test.go
```

### HTTP Service
```
apps/go-service/
├── BUILD.bazel
├── go.mod
├── main.go
├── internal/
│   ├── handlers/
│   │   ├── health.go
│   │   └── users.go
│   ├── middleware/
│   │   ├── auth.go
│   │   └── logging.go
│   ├── models/
│   │   └── user.go
│   └── database/
│       └── connection.go
├── pkg/
│   └── api/
│       └── types.go
└── configs/
    └── config.yaml
```

### Shared Library
```
packages/go-utils/
├── BUILD.bazel
├── go.mod
├── crypto/
│   ├── hash.go
│   └── hash_test.go
├── http/
│   ├── client.go
│   └── client_test.go
└── errors/
    ├── errors.go
    └── errors_test.go
```

## BUILD.bazel Patterns

### CLI Binary
```python
load("@rules_go//go:def.bzl", "go_binary", "go_library", "go_test")

go_library(
    name = "cli_lib",
    srcs = glob(["**/*.go"], exclude = ["main.go", "*_test.go"]),
    importpath = "github.com/yourorg/monorepo/tools/go-cli",
    visibility = ["//visibility:private"],
    deps = [
        "@com_github_spf13_cobra//:cobra",
        "@com_github_spf13_viper//:viper",
        "@org_uber_go_zap//:zap",
        "//packages/go-utils:utils",
    ],
)

go_binary(
    name = "cli",
    embed = [":cli_lib"],
    src = "main.go",
    visibility = ["//visibility:public"],
)

go_test(
    name = "cli_test",
    srcs = glob(["*_test.go"]),
    embed = [":cli_lib"],
    deps = [
        "@com_github_stretchr_testify//assert",
        "@com_github_stretchr_testify//require",
    ],
)
```

### HTTP Service
```python
go_library(
    name = "service_lib",
    srcs = glob(["**/*.go"], exclude = ["main.go", "*_test.go"]),
    importpath = "github.com/yourorg/monorepo/apps/go-service",
    visibility = ["//visibility:private"],
    deps = [
        "@com_github_gin_gonic_gin//:gin",
        "@org_uber_go_zap//:zap",
        "//packages/go-utils:utils",
    ],
)

go_binary(
    name = "service",
    embed = [":service_lib"],
    src = "main.go",
    visibility = ["//visibility:public"],
)

go_test(
    name = "service_test",
    srcs = glob(["**/*_test.go"]),
    embed = [":service_lib"],
    deps = [
        "@com_github_stretchr_testify//assert",
        "@com_github_stretchr_testify//require",
    ],
)
```

### Shared Library
```python
go_library(
    name = "utils",
    srcs = glob(["**/*.go"], exclude = ["*_test.go"]),
    importpath = "github.com/yourorg/monorepo/packages/go-utils",
    visibility = ["//visibility:public"],
    deps = [
        "@org_golang_x_crypto//bcrypt",
        "@org_golang_x_sync//errgroup",
    ],
)

go_test(
    name = "utils_test",
    srcs = glob(["**/*_test.go"]),
    embed = [":utils"],
    deps = [
        "@com_github_stretchr_testify//assert",
        "@com_github_stretchr_testify//require",
    ],
)
```

### Integration Tests
```python
go_test(
    name = "integration_test",
    srcs = ["test/integration_test.go"],
    deps = [
        ":service_lib",
        "@com_github_stretchr_testify//assert",
    ],
    data = [
        "//testdata:config.yaml",
    ],
    tags = ["integration"],
)
```

## Implementation Patterns

### CLI Application with Cobra
```go
// cmd/root.go
package cmd

import (
    "fmt"
    "os"
    "github.com/spf13/cobra"
    "github.com/spf13/viper"
    "go.uber.org/zap"
)

var (
    cfgFile string
    logger  *zap.Logger
    verbose bool
)

var rootCmd = &cobra.Command{
    Use:   "mycli",
    Short: "A CLI tool for managing deployments",
    Long:  `A comprehensive CLI tool for building and deploying applications.`,
}

func Execute() {
    if err := rootCmd.Execute(); err != nil {
        fmt.Println(err)
        os.Exit(1)
    }
}

func init() {
    cobra.OnInitialize(initConfig)
    
    rootCmd.PersistentFlags().StringVar(&cfgFile, "config", "", "config file (default is $HOME/.mycli.yaml)")
    rootCmd.PersistentFlags().BoolVarP(&verbose, "verbose", "v", false, "verbose output")
    
    viper.BindPFlag("verbose", rootCmd.PersistentFlags().Lookup("verbose"))
}

func initConfig() {
    if cfgFile != "" {
        viper.SetConfigFile(cfgFile)
    } else {
        home, err := os.UserHomeDir()
        if err != nil {
            fmt.Println(err)
            os.Exit(1)
        }
        
        viper.AddConfigPath(home)
        viper.SetConfigName(".mycli")
    }
    
    viper.AutomaticEnv()
    
    if err := viper.ReadInConfig(); err == nil {
        fmt.Println("Using config file:", viper.ConfigFileUsed())
    }
    
    // Initialize logger
    var err error
    if viper.GetBool("verbose") {
        logger, err = zap.NewDevelopment()
    } else {
        logger, err = zap.NewProduction()
    }
    if err != nil {
        panic(err)
    }
}
```

### HTTP Service with Gin
```go
// main.go
package main

import (
    "context"
    "fmt"
    "net/http"
    "os"
    "os/signal"
    "syscall"
    "time"

    "github.com/gin-gonic/gin"
    "go.uber.org/zap"
    
    "github.com/yourorg/monorepo/apps/go-service/internal/config"
    "github.com/yourorg/monorepo/apps/go-service/internal/handlers"
    "github.com/yourorg/monorepo/apps/go-service/internal/middleware"
)

func main() {
    // Load configuration
    cfg, err := config.Load()
    if err != nil {
        panic(fmt.Sprintf("Failed to load config: %v", err))
    }
    
    // Initialize logger
    logger, err := zap.NewProduction()
    if err != nil {
        panic(fmt.Sprintf("Failed to initialize logger: %v", err))
    }
    defer logger.Sync()
    
    // Set Gin mode
    if cfg.Environment == "production" {
        gin.SetMode(gin.ReleaseMode)
    }
    
    // Initialize router
    router := gin.New()
    router.Use(middleware.Logger(logger))
    router.Use(middleware.Recovery(logger))
    router.Use(middleware.CORS())
    
    // Health check endpoint
    router.GET("/health", handlers.HealthCheck)
    
    // API routes
    api := router.Group("/api/v1")
    {
        api.GET("/users", handlers.GetUsers)
        api.POST("/users", handlers.CreateUser)
        api.GET("/users/:id", handlers.GetUser)
        api.PUT("/users/:id", handlers.UpdateUser)
        api.DELETE("/users/:id", handlers.DeleteUser)
    }
    
    // Start server
    srv := &http.Server{
        Addr:    fmt.Sprintf(":%d", cfg.Server.Port),
        Handler: router,
    }
    
    // Graceful shutdown
    go func() {
        if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
            logger.Fatal("Failed to start server", zap.Error(err))
        }
    }()
    
    logger.Info("Server started", zap.Int("port", cfg.Server.Port))
    
    // Wait for interrupt signal
    quit := make(chan os.Signal, 1)
    signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
    <-quit
    
    logger.Info("Shutting down server...")
    
    ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
    defer cancel()
    
    if err := srv.Shutdown(ctx); err != nil {
        logger.Fatal("Server forced to shutdown", zap.Error(err))
    }
    
    logger.Info("Server exited")
}
```

### Configuration Management
```go
// internal/config/config.go
package config

import (
    "fmt"
    "os"
    "strconv"
    
    "github.com/spf13/viper"
)

type Config struct {
    Environment string         `mapstructure:"environment"`
    Server      ServerConfig   `mapstructure:"server"`
    Database    DatabaseConfig `mapstructure:"database"`
    Logging     LoggingConfig  `mapstructure:"logging"`
}

type ServerConfig struct {
    Port         int    `mapstructure:"port"`
    Host         string `mapstructure:"host"`
    ReadTimeout  int    `mapstructure:"read_timeout"`
    WriteTimeout int    `mapstructure:"write_timeout"`
}

type DatabaseConfig struct {
    Host     string `mapstructure:"host"`
    Port     int    `mapstructure:"port"`
    Name     string `mapstructure:"name"`
    User     string `mapstructure:"user"`
    Password string `mapstructure:"password"`
    SSLMode  string `mapstructure:"ssl_mode"`
}

type LoggingConfig struct {
    Level  string `mapstructure:"level"`
    Format string `mapstructure:"format"`
}

func Load() (*Config, error) {
    cfg := &Config{}
    
    // Set defaults
    viper.SetDefault("environment", "development")
    viper.SetDefault("server.port", 8080)
    viper.SetDefault("server.host", "localhost")
    viper.SetDefault("server.read_timeout", 30)
    viper.SetDefault("server.write_timeout", 30)
    viper.SetDefault("logging.level", "info")
    viper.SetDefault("logging.format", "json")
    
    // Environment variables
    viper.AutomaticEnv()
    viper.SetEnvPrefix("APP")
    
    // Config file
    viper.SetConfigName("config")
    viper.SetConfigType("yaml")
    viper.AddConfigPath("./configs")
    viper.AddConfigPath(".")
    
    if err := viper.ReadInConfig(); err != nil {
        if _, ok := err.(viper.ConfigFileNotFoundError); !ok {
            return nil, fmt.Errorf("failed to read config file: %w", err)
        }
    }
    
    // Override with environment variables
    if port := os.Getenv("PORT"); port != "" {
        if p, err := strconv.Atoi(port); err == nil {
            viper.Set("server.port", p)
        }
    }
    
    if err := viper.Unmarshal(cfg); err != nil {
        return nil, fmt.Errorf("failed to unmarshal config: %w", err)
    }
    
    return cfg, nil
}
```

### HTTP Client
```go
// pkg/client/api.go
package client

import (
    "bytes"
    "context"
    "encoding/json"
    "fmt"
    "net/http"
    "time"
)

type Client struct {
    baseURL    string
    httpClient *http.Client
    apiKey     string
}

func New(baseURL, apiKey string, timeout time.Duration) *Client {
    return &Client{
        baseURL: baseURL,
        apiKey:  apiKey,
        httpClient: &http.Client{
            Timeout: timeout,
        },
    }
}

func (c *Client) Get(ctx context.Context, path string, result interface{}) error {
    req, err := http.NewRequestWithContext(ctx, "GET", c.baseURL+path, nil)
    if err != nil {
        return fmt.Errorf("failed to create request: %w", err)
    }
    
    req.Header.Set("Authorization", "Bearer "+c.apiKey)
    req.Header.Set("Content-Type", "application/json")
    
    resp, err := c.httpClient.Do(req)
    if err != nil {
        return fmt.Errorf("failed to execute request: %w", err)
    }
    defer resp.Body.Close()
    
    if resp.StatusCode >= 400 {
        return fmt.Errorf("HTTP %d: %s", resp.StatusCode, resp.Status)
    }
    
    if result != nil {
        if err := json.NewDecoder(resp.Body).Decode(result); err != nil {
            return fmt.Errorf("failed to decode response: %w", err)
        }
    }
    
    return nil
}

func (c *Client) Post(ctx context.Context, path string, data, result interface{}) error {
    var body bytes.Buffer
    if data != nil {
        if err := json.NewEncoder(&body).Encode(data); err != nil {
            return fmt.Errorf("failed to encode request body: %w", err)
        }
    }
    
    req, err := http.NewRequestWithContext(ctx, "POST", c.baseURL+path, &body)
    if err != nil {
        return fmt.Errorf("failed to create request: %w", err)
    }
    
    req.Header.Set("Authorization", "Bearer "+c.apiKey)
    req.Header.Set("Content-Type", "application/json")
    
    resp, err := c.httpClient.Do(req)
    if err != nil {
        return fmt.Errorf("failed to execute request: %w", err)
    }
    defer resp.Body.Close()
    
    if resp.StatusCode >= 400 {
        return fmt.Errorf("HTTP %d: %s", resp.StatusCode, resp.Status)
    }
    
    if result != nil {
        if err := json.NewDecoder(resp.Body).Decode(result); err != nil {
            return fmt.Errorf("failed to decode response: %w", err)
        }
    }
    
    return nil
}
```

### Error Handling
```go
// pkg/errors/errors.go
package errors

import (
    "errors"
    "fmt"
)

// Custom error types
var (
    ErrNotFound      = errors.New("resource not found")
    ErrUnauthorized  = errors.New("unauthorized")
    ErrBadRequest    = errors.New("bad request")
    ErrInternalError = errors.New("internal server error")
)

// APIError represents an API error with code and message
type APIError struct {
    Code    int    `json:"code"`
    Message string `json:"message"`
    Err     error  `json:"-"`
}

func (e *APIError) Error() string {
    if e.Err != nil {
        return fmt.Sprintf("API error %d: %s (%v)", e.Code, e.Message, e.Err)
    }
    return fmt.Sprintf("API error %d: %s", e.Code, e.Message)
}

func (e *APIError) Unwrap() error {
    return e.Err
}

// NewAPIError creates a new API error
func NewAPIError(code int, message string, err error) *APIError {
    return &APIError{
        Code:    code,
        Message: message,
        Err:     err,
    }
}

// Validation error
type ValidationError struct {
    Field   string `json:"field"`
    Message string `json:"message"`
}

func (e *ValidationError) Error() string {
    return fmt.Sprintf("validation error on field '%s': %s", e.Field, e.Message)
}

// Multi-error for collecting multiple errors
type MultiError struct {
    Errors []error
}

func (m *MultiError) Error() string {
    if len(m.Errors) == 0 {
        return "no errors"
    }
    if len(m.Errors) == 1 {
        return m.Errors[0].Error()
    }
    return fmt.Sprintf("%s (and %d more errors)", m.Errors[0].Error(), len(m.Errors)-1)
}

func (m *MultiError) Add(err error) {
    if err != nil {
        m.Errors = append(m.Errors, err)
    }
}

func (m *MultiError) HasErrors() bool {
    return len(m.Errors) > 0
}
```

## Testing

### Unit Tests
```go
// crypto/hash_test.go
package crypto

import (
    "testing"
    
    "github.com/stretchr/testify/assert"
    "github.com/stretchr/testify/require"
)

func TestHashString(t *testing.T) {
    tests := []struct {
        name     string
        input    string
        expected string
    }{
        {
            name:     "simple string",
            input:    "hello world",
            expected: "b94d27b9934d3e08a52e52d7da7dabfac484efe37a5380ee9088f7ace2efcde9",
        },
        {
            name:     "empty string",
            input:    "",
            expected: "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855",
        },
    }
    
    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            result := HashString(tt.input)
            assert.Equal(t, tt.expected, result)
        })
    }
}

func TestHashStringLength(t *testing.T) {
    result := HashString("test")
    assert.Len(t, result, 64, "SHA256 hash should be 64 characters")
}

func BenchmarkHashString(b *testing.B) {
    input := "hello world"
    
    b.ResetTimer()
    for i := 0; i < b.N; i++ {
        HashString(input)
    }
}

func BenchmarkHashStringLarge(b *testing.B) {
    input := strings.Repeat("a", 10000)
    
    b.ResetTimer()
    for i := 0; i < b.N; i++ {
        HashString(input)
    }
}
```

### Integration Tests
```go
// test/integration_test.go
package test

import (
    "context"
    "net/http"
    "net/http/httptest"
    "testing"
    "time"
    
    "github.com/gin-gonic/gin"
    "github.com/stretchr/testify/assert"
    "github.com/stretchr/testify/require"
    
    "github.com/yourorg/monorepo/apps/go-service/internal/handlers"
)

func TestHealthCheckEndpoint(t *testing.T) {
    gin.SetMode(gin.TestMode)
    
    router := gin.New()
    router.GET("/health", handlers.HealthCheck)
    
    req, err := http.NewRequest("GET", "/health", nil)
    require.NoError(t, err)
    
    rr := httptest.NewRecorder()
    router.ServeHTTP(rr, req)
    
    assert.Equal(t, http.StatusOK, rr.Code)
    assert.Contains(t, rr.Body.String(), "ok")
}

func TestAPIEndpoints(t *testing.T) {
    // Start test server
    gin.SetMode(gin.TestMode)
    router := setupTestRouter()
    
    server := httptest.NewServer(router)
    defer server.Close()
    
    client := &http.Client{Timeout: 5 * time.Second}
    
    t.Run("get users", func(t *testing.T) {
        resp, err := client.Get(server.URL + "/api/v1/users")
        require.NoError(t, err)
        defer resp.Body.Close()
        
        assert.Equal(t, http.StatusOK, resp.StatusCode)
    })
    
    t.Run("create user", func(t *testing.T) {
        payload := strings.NewReader(`{"name":"John Doe","email":"john@example.com"}`)
        resp, err := client.Post(server.URL+"/api/v1/users", "application/json", payload)
        require.NoError(t, err)
        defer resp.Body.Close()
        
        assert.Equal(t, http.StatusCreated, resp.StatusCode)
    })
}

func setupTestRouter() *gin.Engine {
    router := gin.New()
    
    api := router.Group("/api/v1")
    {
        api.GET("/users", handlers.GetUsers)
        api.POST("/users", handlers.CreateUser)
    }
    
    return router
}
```

### Table-Driven Tests
```go
func TestValidateEmail(t *testing.T) {
    tests := []struct {
        name    string
        email   string
        wantErr bool
    }{
        {"valid email", "user@example.com", false},
        {"valid email with subdomain", "user@mail.example.com", false},
        {"invalid email - no @", "userexample.com", true},
        {"invalid email - no domain", "user@", true},
        {"invalid email - no user", "@example.com", true},
        {"empty email", "", true},
    }
    
    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            err := ValidateEmail(tt.email)
            if tt.wantErr {
                assert.Error(t, err)
            } else {
                assert.NoError(t, err)
            }
        })
    }
}
```

## Performance Optimization

### Concurrency Patterns
```go
// Worker pool pattern
func ProcessItems(ctx context.Context, items []Item, workers int) error {
    jobs := make(chan Item, len(items))
    results := make(chan error, len(items))
    
    // Start workers
    for w := 0; w < workers; w++ {
        go func() {
            for item := range jobs {
                results <- processItem(ctx, item)
            }
        }()
    }
    
    // Send jobs
    for _, item := range items {
        jobs <- item
    }
    close(jobs)
    
    // Collect results
    var errs []error
    for i := 0; i < len(items); i++ {
        if err := <-results; err != nil {
            errs = append(errs, err)
        }
    }
    
    if len(errs) > 0 {
        return fmt.Errorf("failed to process %d items", len(errs))
    }
    
    return nil
}

// Pipeline pattern
func Pipeline(ctx context.Context, input <-chan Data) <-chan Result {
    output := make(chan Result)
    
    go func() {
        defer close(output)
        
        for data := range input {
            select {
            case <-ctx.Done():
                return
            case output <- process(data):
            }
        }
    }()
    
    return output
}
```

### Memory Optimization
```go
// Use sync.Pool for object reuse
var bufferPool = sync.Pool{
    New: func() interface{} {
        return make([]byte, 0, 1024)
    },
}

func ProcessData(data []byte) []byte {
    buf := bufferPool.Get().([]byte)
    defer bufferPool.Put(buf[:0])
    
    // Process data using buf
    return result
}

// Use context for cancellation
func LongRunningOperation(ctx context.Context) error {
    for i := 0; i < 1000000; i++ {
        select {
        case <-ctx.Done():
            return ctx.Err()
        default:
            // Do work
        }
    }
    return nil
}
```

## Deployment

### Static Binary
```python
# Build static binary
go_binary(
    name = "static_service",
    embed = [":service_lib"],
    static = "on",
    visibility = ["//visibility:public"],
)
```

### Container Image
```python
load("@rules_oci//oci:defs.bzl", "oci_image")

oci_image(
    name = "service_image",
    base = "@distroless_static",
    entrypoint = ["/service"],
    tars = [":service_tar"],
    env = {
        "GIN_MODE": "release",
        "PORT": "8080",
    },
)
```

### Multi-stage Build
```dockerfile
# Build stage
FROM golang:1.21-alpine AS builder
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -o service main.go

# Final stage
FROM scratch
COPY --from=builder /app/service /
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
EXPOSE 8080
ENTRYPOINT ["/service"]
```

## Common Tasks

### Adding Dependencies

1. Add to go.mod: `go get github.com/new/package`
2. Update Bazel deps: `bazel run //:gazelle -- update-repos -from_file=go.mod`
3. Update BUILD files: `bazel run //:gazelle`
4. Add to BUILD.bazel deps: `"@com_github_new_package//:package"`

### Cross Compilation

```python
# Build for different platforms
go_binary(
    name = "service_linux_amd64",
    embed = [":service_lib"],
    goarch = "amd64",
    goos = "linux",
)

go_binary(
    name = "service_darwin_arm64",
    embed = [":service_lib"],
    goarch = "arm64", 
    goos = "darwin",
)
```

### Build Tags
```go
//go:build integration
// +build integration

package test

// Integration test code
```

## Troubleshooting

### Build Issues
- Clean module cache: `go clean -modcache`
- Update Bazel files: `bazel run //:gazelle`
- Check go.mod for conflicts: `go mod tidy`
- Verify imports: `bazel run //:gazelle -- fix`

### Performance Issues
- Profile CPU: `go tool pprof http://localhost:6060/debug/pprof/profile`
- Profile memory: `go tool pprof http://localhost:6060/debug/pprof/heap`
- Check goroutine leaks: `go tool pprof http://localhost:6060/debug/pprof/goroutine`

### Race Conditions
- Run with race detector: `bazel test --race //...`
- Use proper synchronization primitives
- Avoid shared mutable state

### Memory Leaks
- Use context for cancellation
- Close channels when done
- Be careful with goroutine lifecycle

## Security Best Practices

### Input Validation
```go
func ValidateUser(user *User) error {
    if user.Email == "" {
        return errors.New("email is required")
    }
    if !isValidEmail(user.Email) {
        return errors.New("invalid email format")
    }
    if len(user.Name) < 2 || len(user.Name) > 100 {
        return errors.New("name must be 2-100 characters")
    }
    return nil
}
```

### Secrets Management
```go
// Never hardcode secrets
apiKey := os.Getenv("API_KEY")
if apiKey == "" {
    return errors.New("API_KEY environment variable is required")
}

// Use secure random generation
func GenerateSessionID() (string, error) {
    bytes := make([]byte, 32)
    if _, err := rand.Read(bytes); err != nil {
        return "", err
    }
    return base64.URLEncoding.EncodeToString(bytes), nil
}
```

### HTTP Security
```go
// Security middleware
func SecurityHeaders() gin.HandlerFunc {
    return func(c *gin.Context) {
        c.Header("X-Content-Type-Options", "nosniff")
        c.Header("X-Frame-Options", "DENY")
        c.Header("X-XSS-Protection", "1; mode=block")
        c.Header("Strict-Transport-Security", "max-age=31536000")
        c.Next()
    }
}
```

## Examples

See [language implementations](../../examples/language-implementations.md) for complete examples of Go applications in this monorepo.
