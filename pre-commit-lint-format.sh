#!/bin/bash

# Multi-language pre-commit lint and format script
# Handles Python (ruff) and Node.js (eslint) projects

set -e

echo "🔍 Running pre-commit lint and format checks..."

# Get list of staged files
STAGED_FILES=$(git diff --cached --name-only --diff-filter=ACM)

if [ -z "$STAGED_FILES" ]; then
  echo "ℹ️  No staged files to check"
  exit 0
fi

# Initialize flags
HAS_PYTHON_FILES=false
HAS_JS_TS_FILES=false
HAS_ERRORS=false

# Check for Python files in packages/foo or packages/bar
PYTHON_FILES=$(echo "$STAGED_FILES" | grep -E '^packages/(foo|bar)/.*\.py$' || true)
if [ -n "$PYTHON_FILES" ]; then
  HAS_PYTHON_FILES=true
fi

# Check for JS/TS files in packages/baz
JS_TS_FILES=$(echo "$STAGED_FILES" | grep -E '^packages/baz/.*\.(js|ts|jsx|tsx)$' || true)
if [ -n "$JS_TS_FILES" ]; then
  HAS_JS_TS_FILES=true
fi

# Function to run Python linting and formatting
run_python_checks() {
  echo "🐍 Running Python checks..."
  
  # Get affected Python packages
  AFFECTED_PYTHON_PACKAGES=""
  if echo "$PYTHON_FILES" | grep -q "packages/foo/"; then
    AFFECTED_PYTHON_PACKAGES="$AFFECTED_PYTHON_PACKAGES foo"
  fi
  if echo "$PYTHON_FILES" | grep -q "packages/bar/"; then
    AFFECTED_PYTHON_PACKAGES="$AFFECTED_PYTHON_PACKAGES bar"
  fi
  
  for package in $AFFECTED_PYTHON_PACKAGES; do
    echo "  📦 Checking package: $package"
    
    # Format first (ruff format)
    echo "    🎨 Formatting with ruff..."
    if ! npx nx run $package:format; then
      echo "    ❌ Formatting failed for $package"
      HAS_ERRORS=true
    fi
    
    # Then lint (ruff check)
    echo "    🔍 Linting with ruff..."
    if ! npx nx run $package:lint; then
      echo "    ❌ Linting failed for $package"
      HAS_ERRORS=true
    fi
  done
}

# Function to run Node.js linting and formatting
run_nodejs_checks() {
  echo "🟨 Running Node.js checks..."
  
  # Format and lint baz package
  echo "  📦 Checking package: baz"
  
  # Format with eslint --fix
  echo "    🎨 Formatting with eslint..."
  if ! npx nx run baz:format; then
    echo "    ❌ Formatting failed for baz"
    HAS_ERRORS=true
  fi
  
  # Lint with eslint
  echo "    🔍 Linting with eslint..."
  if ! npx nx run baz:lint; then
    echo "    ❌ Linting failed for baz"
    HAS_ERRORS=true
  fi
}

# Run checks based on file types
if [ "$HAS_PYTHON_FILES" = true ]; then
  run_python_checks
fi

if [ "$HAS_JS_TS_FILES" = true ]; then
  run_nodejs_checks
fi

# Re-add formatted files to staging
if [ "$HAS_PYTHON_FILES" = true ] || [ "$HAS_JS_TS_FILES" = true ]; then
  echo "📝 Re-adding formatted files to staging..."
  echo "$STAGED_FILES" | xargs git add
fi

# Exit with error if any checks failed
if [ "$HAS_ERRORS" = true ]; then
  echo "❌ Pre-commit checks failed! Please fix the issues above."
  exit 1
fi

echo "✅ All pre-commit checks passed!"
exit 0
