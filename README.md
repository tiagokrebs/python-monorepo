# Python Monorepo with NX

A Python monorepo with centralized dependency management, powered by NX and @nxlv/python. Contains two packages (`foo` and `bar`) with automatic validation of approved dependencies and intelligent task orchestration.

## What This Is

- **Monorepo structure**: Multiple Python packages in a single repository
- **Path dependencies**: Packages can depend on each other using local paths
- **Centralized control**: All external dependencies must be pre-approved
- **Automatic validation**: JavaScript tool validates all packages comply with approved dependencies
- **NX integration**: Intelligent task orchestration, caching, and dependency management
- **Dual workflow**: Both NX commands and direct uv commands work seamlessly

## How Centralized Dependencies Work

### 1. Approved Dependencies

All external packages must be listed in the root `pyproject.toml`:

```toml
[tool.monorepo.dependencies]
approved = [
    "requests==2.31.0",
    "pytest==7.4.0",
    "black==23.7.0",
    # ... other approved packages
]
```

### 2. Internal Packages

Packages within this monorepo (`foo`, `bar`) are automatically allowed and don't need approval.

### 3. Validation

```bash
# Validate all packages
./validate-deps.sh

# Validate specific package
./validate-deps.sh foo

# List approved dependencies
./validate-deps.sh --list
```

### 4. Adding New Dependencies

1. Add to approved list in root `pyproject.toml` (requires security approval)
2. Add to your package's `pyproject.toml`
3. Run validation to confirm compliance

## Package Management with uv

### Adding Dependencies

You can add dependencies to a package in two ways:

#### Method 1: From the monorepo root (recommended)
```bash
# Add a dependency to a specific package from root directory
uv add --directory packages/bar pytest==7.4.0
uv add --directory packages/foo black==23.7.0

# Add development dependencies
uv add --directory packages/bar --dev pytest-cov==4.1.0
```

#### Method 2: From inside the package directory
```bash
# Navigate to the package first
cd packages/bar

# Add dependency
uv add pytest==7.4.0
uv add black==23.7.0

# Add development dependencies  
uv add --dev pytest-cov==4.1.0
```

### Removing Dependencies

#### From root directory:
```bash
uv remove --directory packages/bar pytest
```

#### From package directory:
```bash
cd packages/bar
uv remove pytest
```

## NX Integration

This monorepo uses NX for intelligent task orchestration and caching. You can use both NX commands and direct uv commands.

### NX Commands

```bash
# Install dependencies using pnpm
pnpm install

# Run sync for all packages (respects dependencies)
pnpm run sync

# Run sync for specific package
pnpm run sync:foo
pnpm run sync:bar

# Run code (serves the packages)
pnpm run serve:foo  # Outputs: foo
pnpm run serve:bar  # Outputs: foobar (depends on foo)

# Build all packages
pnpm run build

# Test all packages
pnpm run test

# Lint all packages
pnpm run lint

# Format all packages
pnpm run format

# Run affected tasks only (great for CI)
pnpm run affected:build
pnpm run affected:test
pnpm run affected:lint

# View dependency graph
pnpm run graph
```

### Direct uv Commands (still work!)

```bash
# Sync specific package directly
cd packages/foo && uv sync

# Run Python code directly
cd packages/foo && uv run python -c "from foo import get_foo; print(get_foo())"

# Add dependencies directly
cd packages/bar && uv add requests==2.31.0
```

### NX Benefits

- **Intelligent caching**: NX caches task results, making subsequent runs faster
- **Dependency orchestration**: Automatically runs `foo:install` before `bar:serve`
- **Affected analysis**: Only run tasks for packages that have changed
- **Parallel execution**: Run multiple tasks in parallel when possible
- **Visual graphs**: See your project dependencies visually

### Important Notes

- **Always use exact versions** (e.g., `==7.4.0`) to match the approved list
- **Check validation** after adding dependencies: `./validate-deps.sh`
- **Internal packages** (foo, bar) don't need to be in the approved list
- **New external packages** must be added to the approved list in root `pyproject.toml`

### Example Workflow

```bash
# 1. Try to add a new dependency
cd packages/bar
uv add numpy==1.24.0

# 2. Validate (this will fail if not approved)
cd ../..
./validate-deps.sh
# Output: UNAPPROVED package 'numpy==1.24.0' found in bar

# 3. Add to approved list (security team approval required)
# Edit pyproject.toml and add "numpy==1.24.0" to approved list

# 4. Validate again
./validate-deps.sh
# Output: All packages have approved dependencies
```

## How to Run Packages

You now have two ways to run your packages:

### Method 1: Using NX (Recommended)
```bash
# Run foo package
pnpm run serve:foo

# Run bar package (automatically installs foo first)
pnpm run serve:bar

# Sync all packages
pnpm run sync

# Run any specific task
pnpm exec nx run foo:serve
pnpm exec nx run bar:uv-sync
```

### Method 2: Direct uv commands (still works!)
```bash
# From the python-monorepo root directory:
cd packages/foo
uv sync
uv run python -c "from foo import get_foo; print(get_foo())"

# OR, staying in root directory:
uv sync --directory packages/foo
uv run --directory packages/foo python -c "from foo import get_foo; print(get_foo())"
```

## Git Hooks (Husky)

The repository uses [Husky](https://typicode.github.io/husky/) to automatically validate dependencies before commits:

### Setup
```bash
# Install dependencies (includes Husky setup)
pnpm install
```

### How it Works
- **Pre-commit hook**: Automatically runs `./validate-deps.sh` before every commit
- **Validation passes**: Commit proceeds normally
- **Validation fails**: Commit is blocked with error details

### Example
```bash
# This will be blocked if you have unapproved dependencies
git commit -m "Add new feature"
# Output: husky - pre-commit script failed (code 1)

# Fix dependencies, then commit will succeed
./validate-deps.sh  # Check what's wrong
# Fix the issues...
git commit -m "Add new feature"  # Now works
```

## Structure

```
python-monorepo/
├── .gitignore              # Ignores node_modules, __pycache__, uv.lock, etc.
├── .husky/                 # Git hooks (Husky)
│   └── pre-commit         # Runs dependency validation
├── nx.json                 # NX workspace configuration
├── pyproject.toml          # Centralized dependency control
├── package.json            # Node.js dependencies (pnpm) + NX scripts
├── validate-deps.js        # Validation tool
├── validate-deps.sh        # Shell wrapper
└── packages/
    ├── foo/                # Package: foo
    │   └── project.json   # NX project configuration
    └── bar/                # Package: bar (depends on foo)
        └── project.json   # NX project configuration
```

## Troubleshooting

- **"no such file or directory: packages/foo"**: Make sure you're in the `python-monorepo` directory (the one containing `pyproject.toml`), not the parent directory
- **Path errors**: Check that you're running commands from the correct working directory as shown above
- **"husky - pre-commit script failed"**: Your dependencies don't pass validation. Run `./validate-deps.sh` to see what's wrong
- **Git hooks not working**: Run `pnpm install` to set up Husky properly
- **NX commands not working**: Make sure you have pnpm installed and run `pnpm install` first
- **Python virtual environment issues**: Use `uv sync` in the package directory to recreate the environment
