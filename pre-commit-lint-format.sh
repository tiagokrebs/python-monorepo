#!/bin/bash

# Multi-language pre-commit lint and format script
# Auto-detects Python vs Node.js packages based on project structure

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

# Function to detect package type based on project files
detect_package_type() {
  local package_dir="$1"
  
  # Check if it's a Python package (has pyproject.toml)
  if [ -f "$package_dir/pyproject.toml" ]; then
    echo "python"
    return
  fi
  
  # Check if it's a Node.js package (has package.json)
  if [ -f "$package_dir/package.json" ]; then
    echo "nodejs"
    return
  fi
  
  # Unknown type
  echo "unknown"
}

# Get unique package directories from staged files
PACKAGE_DIRS=$(echo "$STAGED_FILES" | grep -E '^packages/[^/]+/' | sed 's|^packages/\([^/]*\)/.*|\1|' | sort -u)

# Categorize packages and files
PYTHON_PACKAGES=""
NODEJS_PACKAGES=""

for package in $PACKAGE_DIRS; do
  package_type=$(detect_package_type "packages/$package")
  
  case $package_type in
    "python")
      # Check if this package has staged Python files
      PACKAGE_PYTHON_FILES=$(echo "$STAGED_FILES" | grep -E "^packages/$package/.*\.py$" || true)
      if [ -n "$PACKAGE_PYTHON_FILES" ]; then
        PYTHON_PACKAGES="$PYTHON_PACKAGES $package"
        HAS_PYTHON_FILES=true
      fi
      ;;
    "nodejs")
      # Check if this package has staged JS/TS files
      PACKAGE_JS_FILES=$(echo "$STAGED_FILES" | grep -E "^packages/$package/.*\.(js|ts|jsx|tsx)$" || true)
      if [ -n "$PACKAGE_JS_FILES" ]; then
        NODEJS_PACKAGES="$NODEJS_PACKAGES $package"
        HAS_JS_TS_FILES=true
      fi
      ;;
    "unknown")
      echo "⚠️  Unknown package type for packages/$package (no pyproject.toml or package.json found)"
      ;;
  esac
done

# Function to check if package has NX configuration
package_has_nx_config() {
  local package="$1"
  [ -f "packages/$package/project.json" ]
}

# Function to run Python linting and formatting
run_python_checks() {
  echo "🐍 Running Python checks..."
  
  for package in $PYTHON_PACKAGES; do
    echo "  📦 Checking Python package: $package"
    
    # Check if package has NX configuration
    if ! package_has_nx_config "$package"; then
      echo "    ⚠️  Skipping $package (no NX project.json found)"
      continue
    fi
    
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
  
  for package in $NODEJS_PACKAGES; do
    echo "  📦 Checking Node.js package: $package"
    
    # Check if package has NX configuration
    if ! package_has_nx_config "$package"; then
      echo "    ⚠️  Skipping $package (no NX project.json found)"
      continue
    fi
    
    # Format with eslint --fix
    echo "    🎨 Formatting with eslint..."
    if ! npx nx run $package:format; then
      echo "    ❌ Formatting failed for $package"
      HAS_ERRORS=true
    fi
    
    # Lint with eslint
    echo "    🔍 Linting with eslint..."
    if ! npx nx run $package:lint; then
      echo "    ❌ Linting failed for $package"
      HAS_ERRORS=true
    fi
  done
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
