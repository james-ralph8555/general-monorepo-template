# JavaScript/TypeScript Development Guide for AI Agents

This guide provides comprehensive instructions for AI agents to implement JavaScript and TypeScript applications in this monorepo.

## Overview

JavaScript/TypeScript development in this monorepo uses:
- **Bazel with rules_js**: For builds, bundling, and dependency management
- **npm/pnpm**: For JavaScript package management
- **TypeScript**: For type safety and better development experience
- **Modern frameworks**: React, Node.js, Next.js support
- **Testing**: Jest, Vitest, and React Testing Library integration

## Setup and Configuration

### Prerequisites

Ensure you're in the development environment:
```bash
nix develop
node --version  # Should show Node.js 18+
npm --version
```

### Bazel Configuration

Add to MODULE.bazel:
```python
bazel_dep(name = "rules_js", version = "1.40.0")
bazel_dep(name = "rules_ts", version = "2.2.0")
bazel_dep(name = "aspect_rules_webpack", version = "0.14.0")

# For Node.js-specific rules
npm = use_extension("@aspect_rules_js//npm:extensions.bzl", "npm")
npm.npm_translate_lock(
    name = "npm",
    pnpm_lock = "//:pnpm-lock.yaml",
    verify_node_modules_ignored = "//:.bazelignore",
)
use_repo(npm, "npm")
```

### Package Management

#### package.json Example
```json
{
  "name": "monorepo-frontend",
  "version": "1.0.0",
  "type": "module",
  "scripts": {
    "dev": "bazel run //apps/frontend:dev_server",
    "build": "bazel build //apps/frontend:bundle",
    "test": "bazel test //apps/frontend:test"
  },
  "dependencies": {
    "react": "^18.2.0",
    "react-dom": "^18.2.0",
    "typescript": "^5.0.0"
  },
  "devDependencies": {
    "@types/react": "^18.2.0",
    "@types/react-dom": "^18.2.0",
    "jest": "^29.0.0",
    "@testing-library/react": "^13.0.0"
  }
}
```

## Project Structure

### React Frontend Application
```
apps/frontend/
├── BUILD.bazel
├── package.json
├── tsconfig.json
├── src/
│   ├── index.tsx
│   ├── App.tsx
│   ├── components/
│   │   └── Button.tsx
│   └── __tests__/
│       └── App.test.tsx
├── public/
│   └── index.html
└── webpack.config.js
```

### Node.js Backend Service
```
apps/api/
├── BUILD.bazel
├── package.json
├── tsconfig.json
├── src/
│   ├── server.ts
│   ├── routes/
│   │   └── users.ts
│   └── __tests__/
│       └── server.test.ts
└── nodemon.json
```

## BUILD.bazel Patterns

### React Frontend Build
```python
load("@aspect_rules_js//js:defs.bzl", "js_library", "js_binary")
load("@aspect_rules_ts//ts:defs.bzl", "ts_config", "ts_project")
load("@aspect_rules_webpack//webpack:defs.bzl", "webpack_bundle")

# TypeScript configuration
ts_config(
    name = "tsconfig",
    src = "tsconfig.json",
)

# TypeScript compilation
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

# Webpack bundling
webpack_bundle(
    name = "bundle",
    entry_point = "src/index.tsx",
    config = "webpack.config.js",
    deps = [
        ":src",
        "@npm//webpack",
        "@npm//webpack-cli",
    ],
    data = glob(["public/**/*"]),
)

# Development server
js_binary(
    name = "dev_server",
    data = [":src"],
    entry_point = "dev-server.js",
    env = {"NODE_ENV": "development"},
)
```

### Node.js Backend Build
```python
load("@aspect_rules_js//js:defs.bzl", "js_library", "js_binary")
load("@aspect_rules_ts//ts:defs.bzl", "ts_config", "ts_project")

ts_config(
    name = "tsconfig",
    src = "tsconfig.json",
)

ts_project(
    name = "src",
    srcs = glob(["src/**/*.ts"]),
    tsconfig = ":tsconfig",
    deps = [
        "@npm//express",
        "@npm//@types/express",
        "@npm//cors",
        "@npm//@types/cors",
    ],
)

js_binary(
    name = "server",
    data = [":src"],
    entry_point = "src/server.js",
    env = {
        "NODE_ENV": "production",
        "PORT": "3000",
    },
)

# Development server with hot reload
js_binary(
    name = "dev",
    data = [":src"],
    entry_point = "src/server.js",
    env = {"NODE_ENV": "development"},
)
```

### Shared Libraries
```python
load("@aspect_rules_ts//ts:defs.bzl", "ts_project")

ts_project(
    name = "utils",
    srcs = glob(["src/**/*.ts"]),
    tsconfig = ":tsconfig",
    visibility = ["//visibility:public"],
    deps = [
        "@npm//lodash",
        "@npm//@types/lodash",
    ],
)
```

## TypeScript Configuration

### tsconfig.json Example
```json
{
  "compilerOptions": {
    "target": "ES2020",
    "module": "ESNext",
    "moduleResolution": "node",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    "jsx": "react-jsx",
    "declaration": true,
    "outDir": "dist",
    "baseUrl": ".",
    "paths": {
      "@/*": ["src/*"],
      "@/components/*": ["src/components/*"]
    }
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "dist", "**/*.test.ts", "**/*.test.tsx"]
}
```

## Testing

### Jest Configuration
```python
load("@aspect_rules_js//js:defs.bzl", "js_test")

js_test(
    name = "test",
    data = [
        ":src",
        "@npm//jest",
        "@npm//@testing-library/react",
        "@npm//@testing-library/jest-dom",
    ],
    entry_point = "jest.config.js",
    env = {"NODE_ENV": "test"},
)
```

### React Component Tests
```typescript
// src/__tests__/Button.test.tsx
import { render, screen, fireEvent } from '@testing-library/react';
import { Button } from '../components/Button';

describe('Button Component', () => {
  test('renders button with text', () => {
    render(<Button>Click me</Button>);
    expect(screen.getByRole('button')).toHaveTextContent('Click me');
  });

  test('calls onClick when clicked', () => {
    const handleClick = jest.fn();
    render(<Button onClick={handleClick}>Click me</Button>);
    fireEvent.click(screen.getByRole('button'));
    expect(handleClick).toHaveBeenCalledTimes(1);
  });
});
```

### API Tests
```typescript
// src/__tests__/server.test.ts
import request from 'supertest';
import { app } from '../server';

describe('API Server', () => {
  test('GET /health returns 200', async () => {
    const response = await request(app).get('/health');
    expect(response.status).toBe(200);
    expect(response.body).toEqual({ status: 'ok' });
  });

  test('GET /api/users returns users list', async () => {
    const response = await request(app).get('/api/users');
    expect(response.status).toBe(200);
    expect(Array.isArray(response.body)).toBe(true);
  });
});
```

## Implementation Patterns

### Component Library
```typescript
// packages/ui/src/Button.tsx
import React from 'react';

interface ButtonProps {
  variant?: 'primary' | 'secondary';
  size?: 'small' | 'medium' | 'large';
  children: React.ReactNode;
  onClick?: () => void;
}

export const Button: React.FC<ButtonProps> = ({
  variant = 'primary',
  size = 'medium',
  children,
  onClick,
}) => {
  return (
    <button
      className={`btn btn-${variant} btn-${size}`}
      onClick={onClick}
    >
      {children}
    </button>
  );
};
```

### API Client
```typescript
// packages/api-client/src/client.ts
export class ApiClient {
  private baseUrl: string;

  constructor(baseUrl: string) {
    this.baseUrl = baseUrl;
  }

  async get<T>(path: string): Promise<T> {
    const response = await fetch(`${this.baseUrl}${path}`);
    if (!response.ok) {
      throw new Error(`HTTP ${response.status}: ${response.statusText}`);
    }
    return response.json();
  }

  async post<T>(path: string, data: unknown): Promise<T> {
    const response = await fetch(`${this.baseUrl}${path}`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(data),
    });
    if (!response.ok) {
      throw new Error(`HTTP ${response.status}: ${response.statusText}`);
    }
    return response.json();
  }
}
```

### Express Server Setup
```typescript
// apps/api/src/server.ts
import express from 'express';
import cors from 'cors';
import { userRoutes } from './routes/users';

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());

// Routes
app.get('/health', (req, res) => {
  res.json({ status: 'ok' });
});

app.use('/api/users', userRoutes);

if (require.main === module) {
  app.listen(PORT, () => {
    console.log(`Server running on port ${PORT}`);
  });
}

export { app };
```

## Deployment

### Production Build
```python
webpack_bundle(
    name = "prod_bundle",
    entry_point = "src/index.tsx",
    config = "webpack.prod.js",
    mode = "production",
    deps = [":src"],
    env = {"NODE_ENV": "production"},
)
```

### Container Images
```python
load("@rules_oci//oci:defs.bzl", "oci_image", "oci_tarball")

oci_image(
    name = "frontend_image",
    base = "@nginx_base",
    tars = [":prod_bundle"],
    entrypoint = ["nginx", "-g", "daemon off;"],
)

oci_image(
    name = "api_image",
    base = "@node_base",
    tars = [":server"],
    entrypoint = ["node", "server.js"],
    env = {"NODE_ENV": "production"},
)
```

### Static Site Generation
```python
js_binary(
    name = "build_static",
    data = [":src"],
    entry_point = "scripts/build-static.js",
    args = ["--output", "$(BINDIR)/static"],
)
```

## Common Tasks

### Adding a New React Component

1. Create component file in `src/components/`
2. Add TypeScript interfaces for props
3. Export from component index file
4. Add unit tests
5. Update BUILD.bazel if creating new library

### Setting Up API Route

1. Create route file in `src/routes/`
2. Define Express router with TypeScript types
3. Add validation middleware
4. Write integration tests
5. Update main server.ts to include route

### Adding External Dependencies

1. Add to package.json
2. Run `npm install` to update package-lock.json
3. Update BUILD.bazel deps to include `@npm//package-name`
4. Import in TypeScript files with proper types

### Code Splitting

```python
webpack_bundle(
    name = "app_bundle",
    entry_point = "src/index.tsx",
    config = "webpack.config.js",
    # Enable code splitting
    chunks = ["vendor", "main"],
    deps = [":src"],
)
```

## Performance Optimization

### Bundle Analysis
```bash
# Analyze bundle size
bazel run //apps/frontend:analyze_bundle

# Check for unused dependencies
bazel run //tools:depcheck
```

### Lazy Loading
```typescript
// Lazy load components
const LazyComponent = React.lazy(() => import('./LazyComponent'));

function App() {
  return (
    <Suspense fallback={<div>Loading...</div>}>
      <LazyComponent />
    </Suspense>
  );
}
```

### Caching Strategy
```python
# Enable persistent worker for TypeScript
build:ts --strategy=TsProject=worker
build:ts --worker_sandboxing=false
```

## Troubleshooting

### TypeScript Compilation Errors
- Check tsconfig.json configuration
- Verify all dependencies have type definitions
- Use `@types/` packages for libraries without built-in types

### Module Resolution Issues
- Ensure paths in tsconfig.json match project structure
- Check that imports use correct relative paths
- Verify Bazel deps include all required npm packages

### Build Performance
- Use persistent workers: `--strategy=TsProject=worker`
- Enable incremental compilation in tsconfig.json
- Split large bundles into smaller chunks

### Runtime Errors
- Check browser console for detailed error messages
- Use source maps for debugging: `devtool: 'source-map'`
- Verify all environment variables are set correctly

## Advanced Patterns

### Micro-frontends
```python
# Module federation setup
webpack_bundle(
    name = "shell_app",
    entry_point = "src/shell.tsx",
    config = "webpack.mf.js",
    deps = [":shell_src"],
)

webpack_bundle(
    name = "feature_app",
    entry_point = "src/feature.tsx",
    config = "webpack.mf.js", 
    deps = [":feature_src"],
)
```

### Server-Side Rendering
```python
js_binary(
    name = "ssr_server",
    data = [":src"],
    entry_point = "ssr/server.js",
    env = {"NODE_ENV": "production"},
)
```

### Progressive Web App
```javascript
// Service worker configuration
const workboxWebpackPlugin = require('workbox-webpack-plugin');

module.exports = {
  plugins: [
    new workboxWebpackPlugin.GenerateSW({
      clientsClaim: true,
      skipWaiting: true,
    }),
  ],
};
```

## Examples

See [language implementations](../../examples/language-implementations.md) for complete examples of JavaScript/TypeScript applications in this monorepo.