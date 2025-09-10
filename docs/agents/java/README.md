# Java Development Guide for AI Agents

This guide provides comprehensive instructions for AI agents to work with Java projects in this monorepo.

## Overview

Java development in this monorepo uses:
- **Bazel with rules_java**: For builds, testing, and dependency management
- **Maven integration**: For external dependency management
- **Hermetic builds**: Nix-provided JDK for consistency
- **Modern frameworks**: Spring Boot, Micronaut, and enterprise patterns
- **Testing**: JUnit 5, TestContainers, and integration testing

## Setup and Configuration

### Prerequisites

Ensure you're in the development environment:
```bash
nix develop
java --version  # Should show Java 17+ or 21+
mvn --version
```

### Bazel Configuration

Add to MODULE.bazel:
```python
bazel_dep(name = "rules_java", version = "7.5.0")
bazel_dep(name = "rules_jvm_external", version = "6.0")

# Maven dependencies
maven = use_extension("@rules_jvm_external//:extensions.bzl", "maven")
maven.install(
    artifacts = [
        "org.springframework.boot:spring-boot-starter-web:3.2.0",
        "org.springframework.boot:spring-boot-starter-test:3.2.0", 
        "org.junit.jupiter:junit-jupiter:5.10.0",
        "org.assertj:assertj-core:3.24.2",
        "com.fasterxml.jackson.core:jackson-databind:2.16.0",
        "org.slf4j:slf4j-api:2.0.9",
        "ch.qos.logback:logback-classic:1.4.14",
    ],
    repositories = [
        "https://repo1.maven.org/maven2",
    ],
)
use_repo(maven, "maven")
```

### Java Toolchain Configuration

In WORKSPACE (if needed):
```python
load("@io_tweag_rules_nixpkgs//nixpkgs:nixpkgs.bzl", "nixpkgs_java_configure")

nixpkgs_java_configure(
    attribute_path = "jdk21.home",
    repository = "@nixpkgs",
    toolchain = True,
    toolchain_name = "nixpkgs_java",
    toolchain_version = "21",
)
```

## Project Structure

### Spring Boot Application
```
apps/java-service/
├── BUILD.bazel
├── pom.xml
├── src/
│   ├── main/
│   │   ├── java/
│   │   │   └── com/yourorg/service/
│   │   │       ├── ServiceApplication.java
│   │   │       ├── config/
│   │   │       │   └── ApplicationConfig.java
│   │   │       ├── controller/
│   │   │       │   ├── HealthController.java
│   │   │       │   └── UserController.java
│   │   │       ├── service/
│   │   │       │   └── UserService.java
│   │   │       ├── repository/
│   │   │       │   └── UserRepository.java
│   │   │       └── model/
│   │   │           └── User.java
│   │   └── resources/
│   │       ├── application.yml
│   │       └── logback-spring.xml
│   └── test/
│       └── java/
│           └── com/yourorg/service/
│               ├── ServiceApplicationTest.java
│               ├── controller/
│               │   └── UserControllerTest.java
│               └── service/
│                   └── UserServiceTest.java
└── docker/
    └── Dockerfile
```

### Library Package
```
packages/java-utils/
├── BUILD.bazel
├── pom.xml
├── src/
│   ├── main/
│   │   └── java/
│   │       └── com/yourorg/utils/
│   │           ├── crypto/
│   │           │   └── HashUtils.java
│   │           ├── http/
│   │           │   └── HttpClientUtils.java
│   │           └── validation/
│   │               └── Validators.java
│   └── test/
│       └── java/
│           └── com/yourorg/utils/
│               ├── crypto/
│               │   └── HashUtilsTest.java
│               └── http/
│                   └── HttpClientUtilsTest.java
└── README.md
```

### CLI Tool
```
tools/java-cli/
├── BUILD.bazel
├── pom.xml
├── src/
│   ├── main/
│   │   └── java/
│   │       └── com/yourorg/cli/
│   │           ├── CliApplication.java
│   │           ├── command/
│   │           │   ├── BuildCommand.java
│   │           │   └── DeployCommand.java
│   │           └── config/
│   │               └── CliConfig.java
│   └── test/
│       └── java/
│           └── com/yourorg/cli/
│               └── command/
│                   └── BuildCommandTest.java
└── scripts/
    └── run.sh
```

## BUILD.bazel Patterns

### Spring Boot Application
```python
load("@rules_java//java:defs.bzl", "java_binary", "java_library", "java_test")

java_library(
    name = "service_lib",
    srcs = glob(["src/main/java/**/*.java"]),
    resources = glob(["src/main/resources/**/*"]),
    deps = [
        "@maven//:org_springframework_boot_spring_boot_starter_web",
        "@maven//:org_springframework_boot_spring_boot_starter_actuator",
        "@maven//:com_fasterxml_jackson_core_jackson_databind",
        "@maven//:org_slf4j_slf4j_api",
        "@maven//:ch_qos_logback_logback_classic",
        "//packages/java-utils:utils",
    ],
    visibility = ["//visibility:private"],
)

java_binary(
    name = "service",
    main_class = "com.yourorg.service.ServiceApplication",
    runtime_deps = [":service_lib"],
    visibility = ["//visibility:public"],
)

java_test(
    name = "service_test",
    srcs = glob(["src/test/java/**/*.java"]),
    test_class = "com.yourorg.service.ServiceApplicationTest",
    deps = [
        ":service_lib",
        "@maven//:org_springframework_boot_spring_boot_starter_test",
        "@maven//:org_junit_jupiter_junit_jupiter",
        "@maven//:org_assertj_assertj_core",
    ],
    resources = glob(["src/test/resources/**/*"]),
)

# Unit tests
java_test(
    name = "unit_tests",
    srcs = glob(["src/test/java/**/*Test.java"], exclude = ["**/*IntegrationTest.java"]),
    deps = [
        ":service_lib",
        "@maven//:org_junit_jupiter_junit_jupiter",
        "@maven//:org_mockito_mockito_core",
        "@maven//:org_assertj_assertj_core",
    ],
    size = "small",
)

# Integration tests
java_test(
    name = "integration_tests",
    srcs = glob(["src/test/java/**/*IntegrationTest.java"]),
    deps = [
        ":service_lib",
        "@maven//:org_springframework_boot_spring_boot_starter_test",
        "@maven//:org_testcontainers_testcontainers",
        "@maven//:org_testcontainers_junit_jupiter",
    ],
    size = "large",
    tags = ["integration"],
)
```

### Library Package
```python
java_library(
    name = "utils",
    srcs = glob(["src/main/java/**/*.java"]),
    deps = [
        "@maven//:org_apache_commons_commons_lang3",
        "@maven//:com_google_guava_guava",
        "@maven//:org_slf4j_slf4j_api",
    ],
    visibility = ["//visibility:public"],
)

java_test(
    name = "utils_test",
    srcs = glob(["src/test/java/**/*.java"]),
    deps = [
        ":utils",
        "@maven//:org_junit_jupiter_junit_jupiter",
        "@maven//:org_assertj_assertj_core",
    ],
)
```

### CLI Tool
```python
java_binary(
    name = "cli",
    main_class = "com.yourorg.cli.CliApplication",
    srcs = glob(["src/main/java/**/*.java"]),
    deps = [
        "@maven//:info_picocli_picocli",
        "@maven//:org_slf4j_slf4j_api",
        "@maven//:ch_qos_logback_logback_classic",
        "//packages/java-utils:utils",
    ],
    visibility = ["//visibility:public"],
)
```

## Implementation Patterns

### Spring Boot Application
```java
// ServiceApplication.java
package com.yourorg.service;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public class ServiceApplication {
    public static void main(String[] args) {
        SpringApplication.run(ServiceApplication.class, args);
    }
}
```

### REST Controller
```java
// controller/UserController.java
package com.yourorg.service.controller;

import com.yourorg.service.model.User;
import com.yourorg.service.service.UserService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import javax.validation.Valid;
import java.util.List;
import java.util.Optional;

@RestController
@RequestMapping("/api/v1/users")
public class UserController {

    private final UserService userService;

    @Autowired
    public UserController(UserService userService) {
        this.userService = userService;
    }

    @GetMapping
    public ResponseEntity<List<User>> getAllUsers() {
        List<User> users = userService.findAll();
        return ResponseEntity.ok(users);
    }

    @GetMapping("/{id}")
    public ResponseEntity<User> getUserById(@PathVariable Long id) {
        Optional<User> user = userService.findById(id);
        return user.map(ResponseEntity::ok)
                  .orElse(ResponseEntity.notFound().build());
    }

    @PostMapping
    public ResponseEntity<User> createUser(@Valid @RequestBody User user) {
        User createdUser = userService.save(user);
        return ResponseEntity.status(HttpStatus.CREATED).body(createdUser);
    }

    @PutMapping("/{id}")
    public ResponseEntity<User> updateUser(@PathVariable Long id, @Valid @RequestBody User user) {
        if (!userService.existsById(id)) {
            return ResponseEntity.notFound().build();
        }
        user.setId(id);
        User updatedUser = userService.save(user);
        return ResponseEntity.ok(updatedUser);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteUser(@PathVariable Long id) {
        if (!userService.existsById(id)) {
            return ResponseEntity.notFound().build();
        }
        userService.deleteById(id);
        return ResponseEntity.noContent().build();
    }
}
```

### Service Layer
```java
// service/UserService.java
package com.yourorg.service.service;

import com.yourorg.service.model.User;
import com.yourorg.service.repository.UserRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Optional;

@Service
@Transactional
public class UserService {

    private static final Logger logger = LoggerFactory.getLogger(UserService.class);
    private final UserRepository userRepository;

    @Autowired
    public UserService(UserRepository userRepository) {
        this.userRepository = userRepository;
    }

    @Transactional(readOnly = true)
    public List<User> findAll() {
        logger.debug("Finding all users");
        return userRepository.findAll();
    }

    @Transactional(readOnly = true)
    public Optional<User> findById(Long id) {
        logger.debug("Finding user by id: {}", id);
        return userRepository.findById(id);
    }

    @Transactional(readOnly = true)
    public Optional<User> findByEmail(String email) {
        logger.debug("Finding user by email: {}", email);
        return userRepository.findByEmail(email);
    }

    public User save(User user) {
        logger.debug("Saving user: {}", user.getEmail());
        return userRepository.save(user);
    }

    public boolean existsById(Long id) {
        return userRepository.existsById(id);
    }

    public void deleteById(Long id) {
        logger.debug("Deleting user by id: {}", id);
        userRepository.deleteById(id);
    }
}
```

### Data Model
```java
// model/User.java
package com.yourorg.service.model;

import com.fasterxml.jackson.annotation.JsonIgnore;
import javax.persistence.*;
import javax.validation.constraints.Email;
import javax.validation.constraints.NotBlank;
import javax.validation.constraints.Size;
import java.time.LocalDateTime;
import java.util.Objects;

@Entity
@Table(name = "users")
public class User {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @NotBlank(message = "Name is required")
    @Size(min = 2, max = 100, message = "Name must be between 2 and 100 characters")
    @Column(nullable = false)
    private String name;

    @Email(message = "Email should be valid")
    @NotBlank(message = "Email is required")
    @Column(nullable = false, unique = true)
    private String email;

    @JsonIgnore
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @JsonIgnore
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

    public User() {}

    public User(String name, String email) {
        this.name = name;
        this.email = email;
    }

    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
        updatedAt = LocalDateTime.now();
    }

    @PreUpdate
    protected void onUpdate() {
        updatedAt = LocalDateTime.now();
    }

    // Getters and setters
    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public String getEmail() {
        return email;
    }

    public void setEmail(String email) {
        this.email = email;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    public LocalDateTime getUpdatedAt() {
        return updatedAt;
    }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || getClass() != o.getClass()) return false;
        User user = (User) o;
        return Objects.equals(id, user.id) && Objects.equals(email, user.email);
    }

    @Override
    public int hashCode() {
        return Objects.hash(id, email);
    }

    @Override
    public String toString() {
        return "User{" +
                "id=" + id +
                ", name='" + name + '\'' +
                ", email='" + email + '\'' +
                '}';
    }
}
```

### Configuration
```java
// config/ApplicationConfig.java
package com.yourorg.service.config;

import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.client.RestTemplate;

@Configuration
public class ApplicationConfig {

    @Bean
    public RestTemplate restTemplate() {
        return new RestTemplate();
    }

    @Bean
    @ConfigurationProperties(prefix = "app")
    public AppProperties appProperties() {
        return new AppProperties();
    }

    public static class AppProperties {
        private String name;
        private String version;
        private Api api = new Api();

        public static class Api {
            private String baseUrl;
            private int timeout = 30000;

            // Getters and setters
            public String getBaseUrl() {
                return baseUrl;
            }

            public void setBaseUrl(String baseUrl) {
                this.baseUrl = baseUrl;
            }

            public int getTimeout() {
                return timeout;
            }

            public void setTimeout(int timeout) {
                this.timeout = timeout;
            }
        }

        // Getters and setters
        public String getName() {
            return name;
        }

        public void setName(String name) {
            this.name = name;
        }

        public String getVersion() {
            return version;
        }

        public void setVersion(String version) {
            this.version = version;
        }

        public Api getApi() {
            return api;
        }

        public void setApi(Api api) {
            this.api = api;
        }
    }
}
```

### CLI Application with Picocli
```java
// CliApplication.java
package com.yourorg.cli;

import picocli.CommandLine;
import picocli.CommandLine.Command;
import picocli.CommandLine.Option;
import picocli.CommandLine.Parameters;

import java.util.concurrent.Callable;

@Command(
    name = "mycli",
    description = "A CLI tool for managing deployments",
    mixinStandardHelpOptions = true,
    version = "1.0.0",
    subcommands = {
        BuildCommand.class,
        DeployCommand.class,
        CommandLine.HelpCommand.class
    }
)
public class CliApplication implements Callable<Integer> {

    @Option(names = {"-v", "--verbose"}, description = "Enable verbose output")
    private boolean verbose = false;

    @Option(names = {"-c", "--config"}, description = "Configuration file path")
    private String configPath = "config.yml";

    public static void main(String[] args) {
        int exitCode = new CommandLine(new CliApplication()).execute(args);
        System.exit(exitCode);
    }

    @Override
    public Integer call() throws Exception {
        System.out.println("Use --help to see available commands");
        return 0;
    }

    // Getters for subcommands to access parent options
    public boolean isVerbose() {
        return verbose;
    }

    public String getConfigPath() {
        return configPath;
    }
}
```

### Utility Library
```java
// crypto/HashUtils.java
package com.yourorg.utils.crypto;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;

public class HashUtils {

    private HashUtils() {
        // Utility class
    }

    public static String sha256(String input) {
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            byte[] hash = digest.digest(input.getBytes(StandardCharsets.UTF_8));
            return bytesToHex(hash);
        } catch (NoSuchAlgorithmException e) {
            throw new RuntimeException("SHA-256 algorithm not available", e);
        }
    }

    public static String md5(String input) {
        try {
            MessageDigest digest = MessageDigest.getInstance("MD5");
            byte[] hash = digest.digest(input.getBytes(StandardCharsets.UTF_8));
            return bytesToHex(hash);
        } catch (NoSuchAlgorithmException e) {
            throw new RuntimeException("MD5 algorithm not available", e);
        }
    }

    private static String bytesToHex(byte[] bytes) {
        StringBuilder result = new StringBuilder();
        for (byte b : bytes) {
            result.append(String.format("%02x", b));
        }
        return result.toString();
    }
}
```

## Testing

### Unit Tests with JUnit 5
```java
// service/UserServiceTest.java
package com.yourorg.service.service;

import com.yourorg.service.model.User;
import com.yourorg.service.repository.UserRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.Arrays;
import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class UserServiceTest {

    @Mock
    private UserRepository userRepository;

    @InjectMocks
    private UserService userService;

    private User testUser;

    @BeforeEach
    void setUp() {
        testUser = new User("John Doe", "john@example.com");
        testUser.setId(1L);
    }

    @Test
    void findAll_ShouldReturnAllUsers() {
        // Given
        List<User> users = Arrays.asList(testUser, new User("Jane Doe", "jane@example.com"));
        when(userRepository.findAll()).thenReturn(users);

        // When
        List<User> result = userService.findAll();

        // Then
        assertThat(result).hasSize(2);
        assertThat(result).containsExactlyElementsOf(users);
        verify(userRepository).findAll();
    }

    @Test
    void findById_WhenUserExists_ShouldReturnUser() {
        // Given
        when(userRepository.findById(1L)).thenReturn(Optional.of(testUser));

        // When
        Optional<User> result = userService.findById(1L);

        // Then
        assertThat(result).isPresent();
        assertThat(result.get()).isEqualTo(testUser);
        verify(userRepository).findById(1L);
    }

    @Test
    void findById_WhenUserDoesNotExist_ShouldReturnEmpty() {
        // Given
        when(userRepository.findById(999L)).thenReturn(Optional.empty());

        // When
        Optional<User> result = userService.findById(999L);

        // Then
        assertThat(result).isEmpty();
        verify(userRepository).findById(999L);
    }

    @Test
    void save_ShouldReturnSavedUser() {
        // Given
        when(userRepository.save(any(User.class))).thenReturn(testUser);

        // When
        User result = userService.save(testUser);

        // Then
        assertThat(result).isEqualTo(testUser);
        verify(userRepository).save(testUser);
    }

    @Test
    void deleteById_ShouldCallRepository() {
        // When
        userService.deleteById(1L);

        // Then
        verify(userRepository).deleteById(1L);
    }
}
```

### Integration Tests
```java
// controller/UserControllerIntegrationTest.java
package com.yourorg.service.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.yourorg.service.model.User;
import com.yourorg.service.repository.UserRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureWebMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.transaction.annotation.Transactional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@AutoConfigureWebMvc
@ActiveProfiles("test")
@Transactional
class UserControllerIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private ObjectMapper objectMapper;

    private User testUser;

    @BeforeEach
    void setUp() {
        userRepository.deleteAll();
        testUser = new User("John Doe", "john@example.com");
        testUser = userRepository.save(testUser);
    }

    @Test
    void getAllUsers_ShouldReturnUsersList() throws Exception {
        mockMvc.perform(get("/api/v1/users"))
                .andExpect(status().isOk())
                .andExpect(content().contentType(MediaType.APPLICATION_JSON))
                .andExpect(jsonPath("$").isArray())
                .andExpect(jsonPath("$[0].name").value("John Doe"))
                .andExpected(jsonPath("$[0].email").value("john@example.com"));
    }

    @Test
    void getUserById_WhenExists_ShouldReturnUser() throws Exception {
        mockMvc.perform(get("/api/v1/users/{id}", testUser.getId()))
                .andExpect(status().isOk())
                .andExpect(content().contentType(MediaType.APPLICATION_JSON))
                .andExpect(jsonPath("$.name").value("John Doe"))
                .andExpect(jsonPath("$.email").value("john@example.com"));
    }

    @Test
    void getUserById_WhenNotExists_ShouldReturn404() throws Exception {
        mockMvc.perform(get("/api/v1/users/{id}", 999L))
                .andExpect(status().isNotFound());
    }

    @Test
    void createUser_WithValidData_ShouldReturn201() throws Exception {
        User newUser = new User("Jane Doe", "jane@example.com");
        String userJson = objectMapper.writeValueAsString(newUser);

        mockMvc.perform(post("/api/v1/users")
                .contentType(MediaType.APPLICATION_JSON)
                .content(userJson))
                .andExpect(status().isCreated())
                .andExpect(content().contentType(MediaType.APPLICATION_JSON))
                .andExpect(jsonPath("$.name").value("Jane Doe"))
                .andExpect(jsonPath("$.email").value("jane@example.com"));

        assertThat(userRepository.findByEmail("jane@example.com")).isPresent();
    }

    @Test
    void createUser_WithInvalidData_ShouldReturn400() throws Exception {
        User invalidUser = new User("", "invalid-email");
        String userJson = objectMapper.writeValueAsString(invalidUser);

        mockMvc.perform(post("/api/v1/users")
                .contentType(MediaType.APPLICATION_JSON)
                .content(userJson))
                .andExpect(status().isBadRequest());
    }

    @Test
    void updateUser_WhenExists_ShouldReturn200() throws Exception {
        User updatedUser = new User("John Updated", "john.updated@example.com");
        String userJson = objectMapper.writeValueAsString(updatedUser);

        mockMvc.perform(put("/api/v1/users/{id}", testUser.getId())
                .contentType(MediaType.APPLICATION_JSON)
                .content(userJson))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.name").value("John Updated"))
                .andExpect(jsonPath("$.email").value("john.updated@example.com"));
    }

    @Test
    void deleteUser_WhenExists_ShouldReturn204() throws Exception {
        mockMvc.perform(delete("/api/v1/users/{id}", testUser.getId()))
                .andExpect(status().isNoContent());

        assertThat(userRepository.findById(testUser.getId())).isEmpty();
    }
}
```

### TestContainers for Database Testing
```java
// BaseIntegrationTest.java
package com.yourorg.service;

import org.junit.jupiter.api.AfterAll;
import org.junit.jupiter.api.BeforeAll;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;

@SpringBootTest
@ActiveProfiles("test")
@Testcontainers
public abstract class BaseIntegrationTest {

    @Container
    static PostgreSQLContainer<?> postgres = new PostgreSQLContainer<>("postgres:15-alpine")
            .withDatabaseName("testdb")
            .withUsername("test")
            .withPassword("test")
            .withReuse(true);

    @DynamicPropertySource
    static void configureProperties(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", postgres::getJdbcUrl);
        registry.add("spring.datasource.username", postgres::getUsername);
        registry.add("spring.datasource.password", postgres::getPassword);
    }

    @BeforeAll
    static void setUp() {
        postgres.start();
    }

    @AfterAll
    static void tearDown() {
        postgres.stop();
    }
}
```

## Performance Optimization

### JVM Tuning
```bash
# Add to application.yml or as JVM args
server:
  undertow:
    threads:
      io: 4
      worker: 8
    buffer-size: 1024
    direct-buffers: true

# JVM options for production
-Xms2g
-Xmx4g
-XX:+UseG1GC
-XX:MaxGCPauseMillis=200
-XX:+HeapDumpOnOutOfMemoryError
-XX:HeapDumpPath=/tmp/heapdump.hprof
```

### Connection Pooling
```yaml
# application.yml
spring:
  datasource:
    hikari:
      maximum-pool-size: 20
      minimum-idle: 5
      idle-timeout: 300000
      connection-timeout: 20000
      max-lifetime: 1200000
```

### Caching
```java
// Enable caching
@Configuration
@EnableCaching
public class CacheConfig {

    @Bean
    public CacheManager cacheManager() {
        ConcurrentMapCacheManager cacheManager = new ConcurrentMapCacheManager();
        cacheManager.setCacheNames(Arrays.asList("users", "products"));
        return cacheManager;
    }
}

// Use caching in service
@Service
public class UserService {

    @Cacheable(value = "users", key = "#id")
    public Optional<User> findById(Long id) {
        return userRepository.findById(id);
    }

    @CacheEvict(value = "users", key = "#user.id")
    public User save(User user) {
        return userRepository.save(user);
    }
}
```

## Deployment

### Fat JAR
```python
# Add to BUILD.bazel
java_binary(
    name = "service_deploy",
    main_class = "com.yourorg.service.ServiceApplication",
    runtime_deps = [":service_lib"],
    create_executable = True,
)
```

### Container Image
```python
load("@rules_oci//oci:defs.bzl", "oci_image")

oci_image(
    name = "service_image",
    base = "@openjdk_base",
    entrypoint = ["java", "-jar", "/app/service.jar"],
    tars = [":service_jar"],
    env = {
        "JAVA_OPTS": "-Xms512m -Xmx1g",
        "SPRING_PROFILES_ACTIVE": "production",
    },
)
```

### Multi-stage Dockerfile
```dockerfile
# Build stage
FROM openjdk:21-jdk-slim as builder
WORKDIR /app
COPY . .
RUN ./mvnw clean package -DskipTests

# Runtime stage
FROM openjdk:21-jre-slim
COPY --from=builder /app/target/service.jar /app/service.jar
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "/app/service.jar"]
```

## Common Tasks

### Adding Dependencies

1. Add to MODULE.bazel maven artifacts list
2. Update BUILD.bazel deps array
3. Run `bazel sync` to fetch dependencies
4. Import in Java code

### Profiles and Environments

```yaml
# application.yml
spring:
  profiles:
    active: ${SPRING_PROFILES_ACTIVE:development}

---
spring:
  profiles: development
  datasource:
    url: jdbc:h2:mem:devdb

---
spring:
  profiles: production
  datasource:
    url: ${DATABASE_URL}
```

### Logging Configuration

```xml
<!-- logback-spring.xml -->
<configuration>
    <springProfile name="development">
        <appender name="CONSOLE" class="ch.qos.logback.core.ConsoleAppender">
            <encoder>
                <pattern>%d{HH:mm:ss.SSS} [%thread] %-5level %logger{36} - %msg%n</pattern>
            </encoder>
        </appender>
        <root level="DEBUG">
            <appender-ref ref="CONSOLE"/>
        </root>
    </springProfile>

    <springProfile name="production">
        <appender name="FILE" class="ch.qos.logback.core.rolling.RollingFileAppender">
            <file>logs/application.log</file>
            <encoder class="net.logstash.logback.encoder.LoggingEventCompositeJsonEncoder">
                <providers>
                    <timestamp/>
                    <logLevel/>
                    <loggerName/>
                    <message/>
                    <mdc/>
                    <stackTrace/>
                </providers>
            </encoder>
        </appender>
        <root level="INFO">
            <appender-ref ref="FILE"/>
        </root>
    </springProfile>
</configuration>
```

## Troubleshooting

### Build Issues
- Clean Bazel cache: `bazel clean`
- Check Java version compatibility
- Verify Maven artifact versions
- Check for duplicate dependencies

### Performance Issues
- Profile with JProfiler or async-profiler
- Monitor GC logs: `-Xloggc:gc.log -XX:+PrintGCDetails`
- Check database query performance
- Monitor connection pool metrics

### Memory Issues
- Enable heap dump on OOM
- Use memory profilers
- Check for memory leaks in caches
- Monitor off-heap memory usage

### Test Issues
- Check test database configuration
- Verify TestContainers setup
- Check test resource cleanup
- Use @DirtiesContext when needed

## Security Best Practices

### Input Validation
```java
@Valid
public class CreateUserRequest {
    @NotBlank(message = "Name is required")
    @Size(min = 2, max = 100)
    private String name;

    @Email(message = "Invalid email format")
    @NotBlank(message = "Email is required")
    private String email;

    // Getters and setters
}
```

### Security Configuration
```java
@Configuration
@EnableWebSecurity
public class SecurityConfig {

    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        http
            .authorizeHttpRequests(authz -> authz
                .requestMatchers("/actuator/health").permitAll()
                .requestMatchers("/api/**").authenticated()
                .anyRequest().denyAll()
            )
            .oauth2ResourceServer(oauth2 -> oauth2
                .jwt(jwt -> jwt.jwtAuthenticationConverter(jwtConverter()))
            )
            .csrf(csrf -> csrf.disable())
            .headers(headers -> headers
                .frameOptions().deny()
                .contentTypeOptions().and()
                .httpStrictTransportSecurity(hstsConfig -> hstsConfig
                    .maxAgeInSeconds(31536000)
                    .includeSubdomains(true)
                )
            );
        return http.build();
    }
}
```

### Secrets Management
```java
// Never hardcode secrets
@Value("${app.api.secret:#{environment.API_SECRET}}")
private String apiSecret;

// Use secure random generation
public String generateSessionId() {
    SecureRandom random = new SecureRandom();
    byte[] bytes = new byte[32];
    random.nextBytes(bytes);
    return Base64.getUrlEncoder().withoutPadding().encodeToString(bytes);
}
```

## Examples

See [language implementations](../../examples/language-implementations.md) for complete examples of Java applications in this monorepo.