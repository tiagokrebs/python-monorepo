# Multi-Language Monorepo Commands

## Dependency Validation (Python packages only)

```bash
# Validate all Python packages
./validate-deps.sh

# Validate specific Python package
./validate-deps.sh foo

# List approved dependencies
./validate-deps.sh --list
```

## Package Management with uv (Python packages)

### Adding Dependencies

```bash
# From monorepo root (recommended)
uv add --directory packages/bar pytest==7.4.0
uv add --directory packages/foo black==23.7.0
uv add --directory packages/bar --dev pytest-cov==4.1.0

# From inside package directory
cd packages/bar
uv add pytest==7.4.0
uv add --dev pytest-cov==4.1.0
```

### Removing Dependencies

```bash
# From root directory
uv remove --directory packages/bar pytest

# From package directory
cd packages/bar
uv remove pytest
```

## NX Commands (All packages: foo, bar, baz)

```bash
# Install dependencies
pnpm install

# Sync packages
npx nx run-many --target=sync
npx nx run foo:sync    # Python package
npx nx run bar:sync    # Python package
npx nx run baz:sync    # Node.js package

# Serve packages
npx nx run foo:serve   # Python: outputs "foo"
npx nx run bar:serve   # Python: outputs "foobar" 
npx nx run baz:serve   # Node.js: starts server on port 3000

# Build packages
npx nx run-many --target=build
npx nx run foo:build   # Python: builds wheel/sdist
npx nx run bar:build   # Python: builds wheel/sdist
npx nx run baz:build   # Node.js: simple build message

# Test packages
npx nx run-many --target=test
npx nx run foo:test    # Python: pytest
npx nx run bar:test    # Python: pytest
npx nx run baz:test    # Node.js: npm test

# Lint packages
npx nx run-many --target=lint
npx nx run foo:lint    # Python: ruff check
npx nx run bar:lint    # Python: ruff check
npx nx run baz:lint    # Node.js: eslint

# Format packages
npx nx run-many --target=format
npx nx run foo:format  # Python: ruff format
npx nx run bar:format  # Python: ruff format
npx nx run baz:format  # Node.js: eslint --fix

# Affected tasks (CI)
npx nx affected --target=build
npx nx affected --target=test
npx nx affected --target=lint

# Dependency graph
npx nx graph
npx nx graph --file=dependency-graph.json
```

## Direct uv Commands (Python packages only)

```bash
# Sync packages
cd packages/foo && uv sync
uv sync --directory packages/foo

# Run Python code
cd packages/foo && uv run python -c "from foo import get_foo; print(get_foo())"
uv run --directory packages/foo python -c "from foo import get_foo; print(get_foo())"

# Add dependencies directly
cd packages/bar && uv add requests==2.31.0
```

## Direct Node.js Commands (baz package only)

```bash
# Install dependencies
cd packages/baz && pnpm install

# Start server
cd packages/baz && node src/index.js
cd packages/baz && npm start

# Lint code
cd packages/baz && npx eslint src/**/*.js

# Test endpoints
curl http://localhost:3000          # {"message":"hello"}
curl http://localhost:3000/health   # {"status":"ok","service":"baz"}
```
