#!/bin/bash

# Simple wrapper script for dependency validation
# Usage:
#   ./validate-deps.sh              # Validate all packages
#   ./validate-deps.sh bar          # Validate specific package
#   ./validate-deps.sh --list       # List approved dependencies

if [ "$1" = "--list" ]; then
    node validate-deps.js --list
elif [ -n "$1" ] && [ "$1" != "--help" ]; then
    node validate-deps.js --package "$1"
elif [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    echo "Dependency Validation for Python Monorepo"
    echo ""
    echo "Usage:"
    echo "  ./validate-deps.sh              # Validate all packages"
    echo "  ./validate-deps.sh <package>    # Validate specific package"
    echo "  ./validate-deps.sh --list       # List approved dependencies"
    echo "  ./validate-deps.sh --help       # Show this help"
    echo ""
    echo "Examples:"
    echo "  ./validate-deps.sh"
    echo "  ./validate-deps.sh bar"
    echo "  ./validate-deps.sh foo"
    echo "  ./validate-deps.sh --list"
else
    node validate-deps.js
fi
