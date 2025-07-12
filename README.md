# Python Monorepo Commands

## Dependency Validation

```bash
# Validate all packages
./validate-deps.sh

# Validate specific package
./validate-deps.sh foo

# List approved dependencies
./validate-deps.sh --list
```

## Package Management with uv

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

## NX Commands

```bash
# Install dependencies
pnpm install

# Sync packages
npx nx run-many --target=sync
npx nx run foo:sync
npx nx run bar:sync

# Serve packages
npx nx run foo:serve
npx nx run bar:serve

# Build packages
npx nx run-many --target=build
npx nx run foo:build
npx nx run bar:build

# Test packages
npx nx run-many --target=test
npx nx run foo:test
npx nx run bar:test

# Lint packages
npx nx run-many --target=lint
npx nx run foo:lint
npx nx run bar:lint

# Format packages
npx nx run-many --target=format
npx nx run foo:format
npx nx run bar:format

# Affected tasks (CI)
npx nx affected --target=build
npx nx affected --target=test
npx nx affected --target=lint

# Dependency graph
npx nx graph
npx nx graph --file=dependency-graph.json
```

## Direct uv Commands

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
