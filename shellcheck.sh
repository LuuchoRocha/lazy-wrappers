#!/bin/bash
# Run ShellCheck locally with the same rules as CI
# This script mirrors the GitHub Actions CI workflow shellcheck job
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get script directory (works even if script is sourced)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Default settings (matching CI workflow)
SEVERITY="warning"
FORMAT="gcc"

# Files to check (explicit list for clarity)
FILES_TO_CHECK=(
    "install.sh"
    "simple_install.sh"
    "generate_wrappers.sh"
    "benchmark.sh"
    "shell_hook.sh"
    "uninstall.sh"
)

# Parse command-line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -s|--severity)
            SEVERITY="$2"
            shift 2
            ;;
        -f|--format)
            FORMAT="$2"
            shift 2
            ;;
        --fix)
            echo -e "${YELLOW}Note: ShellCheck doesn't auto-fix. Use 'shellcheck -f diff' to get a patch.${NC}"
            FORMAT="diff"
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Run ShellCheck on all shell scripts with CI-equivalent rules."
            echo ""
            echo "Options:"
            echo "  -s, --severity LEVEL   Set minimum severity: error, warning, info, style"
            echo "                         (default: warning, matching CI)"
            echo "  -f, --format FORMAT    Output format: gcc, tty, checkstyle, diff, json, json1, quiet"
            echo "                         (default: gcc, matching CI)"
            echo "  --fix                  Show diff format output (can be used with 'patch')"
            echo "  -h, --help             Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0                     # Run with CI defaults"
            echo "  $0 -s style            # Include style suggestions"
            echo "  $0 -f tty              # Pretty terminal output"
            echo "  $0 --fix | patch -p1   # Apply suggested fixes"
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Check if shellcheck is installed
if ! command -v shellcheck &> /dev/null; then
    echo -e "${RED}Error: shellcheck is not installed${NC}"
    echo ""
    echo "Install shellcheck:"
    echo "  macOS:        brew install shellcheck"
    echo "  Ubuntu/Debian: sudo apt-get install shellcheck"
    echo "  Fedora:       sudo dnf install ShellCheck"
    echo "  Arch Linux:   sudo pacman -S shellcheck"
    echo ""
    echo "Or download from: https://github.com/koalaman/shellcheck/releases"
    exit 1
fi

echo -e "${BLUE}Running ShellCheck (severity: ${SEVERITY}, format: ${FORMAT})${NC}"
echo -e "${BLUE}Using .shellcheckrc for additional configuration${NC}"
echo ""

cd "$SCRIPT_DIR"

# Build list of files to check
SHELL_FILES=()
for file in "${FILES_TO_CHECK[@]}"; do
    if [[ -f "$file" ]]; then
        SHELL_FILES+=("./$file")
    else
        echo -e "${YELLOW}Warning: $file not found${NC}"
    fi
done

if [[ ${#SHELL_FILES[@]} -eq 0 ]]; then
    echo -e "${YELLOW}No shell scripts found to check${NC}"
    exit 0
fi

echo -e "${BLUE}Checking ${#SHELL_FILES[@]} files:${NC}"
for f in "${SHELL_FILES[@]}"; do
    echo "  $f"
done
echo ""

# Run shellcheck
# Note: .shellcheckrc is automatically read from the current directory
FAILED=0
if ! shellcheck --severity="$SEVERITY" --format="$FORMAT" "${SHELL_FILES[@]}"; then
    FAILED=1
fi

echo ""
if [[ $FAILED -eq 0 ]]; then
    echo -e "${GREEN}✓ All checks passed!${NC}"
else
    echo -e "${RED}✗ ShellCheck found issues${NC}"
    echo ""
    echo -e "${YELLOW}How to fix ShellCheck warnings:${NC}"
    echo "  1. Run with pretty output:  $0 -f tty"
    echo "  2. See wiki for each code:  https://www.shellcheck.net/wiki/SCxxxx"
    echo "  3. Generate a patch:        $0 --fix"
    echo ""
    exit 1
fi
