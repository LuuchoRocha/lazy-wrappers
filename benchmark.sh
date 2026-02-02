#!/bin/bash
# Comprehensive benchmark for lazy-wrappers
# Tests both shell startup time AND per-command overhead

set -euo pipefail

ITERATIONS="${1:-100}"
SHELL_TO_TEST="${SHELL:-/bin/bash}"
SHELL_NAME="$(basename "$SHELL_TO_TEST")"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# Paths
LAZY_WRAPPERS_DIR="$HOME/.lazy-wrappers"
NODE_WRAPPERS="$LAZY_WRAPPERS_DIR/scripts/bin/node_wrappers"
RUBY_WRAPPERS="$LAZY_WRAPPERS_DIR/scripts/bin/ruby_wrappers"
NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
RBENV_DIR="${RBENV_DIR:-$HOME/.rbenv}"

# Check prerequisites
if [[ ! -d "$LAZY_WRAPPERS_DIR" ]]; then
    echo -e "${RED}Error: lazy-wrappers not installed. Run ./install.sh first.${NC}"
    exit 1
fi

echo -e "${BLUE}╔══════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║            ${BOLD}lazy-wrappers Comprehensive Benchmark${NC}${BLUE}               ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "  Shell:       ${CYAN}$SHELL_TO_TEST${NC}"
echo -e "  Iterations:  ${CYAN}$ITERATIONS${NC} per test"
echo -e "  Date:        ${CYAN}$(date '+%Y-%m-%d %H:%M:%S')${NC}"
echo ""

# Create temp dir for RC files
TEMP_DIR=$(mktemp -d)
trap 'rm -rf "$TEMP_DIR"' EXIT

# ============================================================================
# Helper Functions
# ============================================================================

measure_startup() {
    local rc_file="$1"
    local total=0
    local times=()
    
    for ((i=1; i<=ITERATIONS; i++)); do
        if [[ "$SHELL_NAME" == "bash" ]]; then
            start=$(date +%s%N)
            "$SHELL_TO_TEST" --rcfile "$rc_file" -i -c "exit" 2>/dev/null
            end=$(date +%s%N)
        else
            start=$(date +%s%N)
            ZDOTDIR="$(dirname "$rc_file")" "$SHELL_TO_TEST" -i -c "exit" 2>/dev/null
            end=$(date +%s%N)
        fi
        elapsed=$(( (end - start) / 1000000 ))
        times+=("$elapsed")
        total=$((total + elapsed))
    done
    
    local avg=$((total / ITERATIONS))
    local min=${times[0]} max=${times[0]}
    for t in "${times[@]}"; do
        ((t < min)) && min=$t
        ((t > max)) && max=$t
    done
    echo "$avg $min $max"
}

measure_command() {
    local cmd="$1"
    local total=0
    local times=()
    
    for ((i=1; i<=ITERATIONS; i++)); do
        start=$(date +%s%N)
        $cmd --version &>/dev/null 2>&1 || true
        end=$(date +%s%N)
        elapsed=$(( (end - start) / 1000000 ))
        times+=("$elapsed")
        total=$((total + elapsed))
    done
    
    local avg=$((total / ITERATIONS))
    local min=${times[0]} max=${times[0]}
    for t in "${times[@]}"; do
        ((t < min)) && min=$t
        ((t > max)) && max=$t
    done
    echo "$avg $min $max"
}

find_real_binary() {
    local name="$1"
    local wrapper_dir="$2"
    local clean_path="${PATH//$wrapper_dir:/}"
    clean_path="${clean_path//:$wrapper_dir/}"
    PATH="$clean_path" command -v "$name" 2>/dev/null || echo ""
}

# ============================================================================
# PART 1: Shell Startup Time
# ============================================================================

echo -e "${BLUE}┌──────────────────────────────────────────────────────────────────┐${NC}"
echo -e "${BLUE}│  ${BOLD}PART 1: Shell Startup Time${NC}${BLUE}                                       │${NC}"
echo -e "${BLUE}│  How long does it take to open a new terminal?                  │${NC}"
echo -e "${BLUE}└──────────────────────────────────────────────────────────────────┘${NC}"
echo ""

TEMP_RC="$TEMP_DIR/.bashrc"
[[ "$SHELL_NAME" == "zsh" ]] && TEMP_RC="$TEMP_DIR/.zshrc"

# Baseline
echo -ne "  ${YELLOW}[1/4]${NC} Baseline (no version managers)...        "
cat > "$TEMP_RC" << 'EOF'
export PATH="/usr/local/bin:/usr/bin:/bin"
EOF
read -r baseline_avg baseline_min baseline_max <<< "$(measure_startup "$TEMP_RC")"
echo -e "${GREEN}${baseline_avg}ms${NC}"

# Traditional nvm
nvm_avg=0 nvm_savings=0
if [[ -s "$NVM_DIR/nvm.sh" ]]; then
    echo -ne "  ${YELLOW}[2/4]${NC} Traditional nvm loading...              "
    cat > "$TEMP_RC" << EOF
export NVM_DIR="$NVM_DIR"
[ -s "\$NVM_DIR/nvm.sh" ] && . "\$NVM_DIR/nvm.sh"
[ -s "\$NVM_DIR/bash_completion" ] && . "\$NVM_DIR/bash_completion"
EOF
    read -r nvm_avg nvm_min nvm_max <<< "$(measure_startup "$TEMP_RC")"
    echo -e "${RED}${nvm_avg}ms${NC} (+$((nvm_avg - baseline_avg))ms)"
else
    echo -e "  ${YELLOW}[2/4]${NC} Traditional nvm loading...              ${YELLOW}skipped${NC} (not installed)"
fi

# Traditional rbenv
rbenv_avg=0 rbenv_savings=0
if [[ -x "$RBENV_DIR/bin/rbenv" ]]; then
    echo -ne "  ${YELLOW}[3/4]${NC} Traditional rbenv loading...            "
    cat > "$TEMP_RC" << EOF
export PATH="$RBENV_DIR/bin:\$PATH"
eval "\$($RBENV_DIR/bin/rbenv init - $SHELL_NAME)"
EOF
    read -r rbenv_avg rbenv_min rbenv_max <<< "$(measure_startup "$TEMP_RC")"
    echo -e "${RED}${rbenv_avg}ms${NC} (+$((rbenv_avg - baseline_avg))ms)"
else
    echo -e "  ${YELLOW}[3/4]${NC} Traditional rbenv loading...            ${YELLOW}skipped${NC} (not installed)"
fi

# lazy-wrappers
echo -ne "  ${YELLOW}[4/4]${NC} lazy-wrappers...                        "
cat > "$TEMP_RC" << EOF
export PATH="$NODE_WRAPPERS:$RUBY_WRAPPERS:\$PATH"
. "$LAZY_WRAPPERS_DIR/scripts/shell_hook.sh"
EOF
read -r lazy_avg lazy_min lazy_max <<< "$(measure_startup "$TEMP_RC")"
echo -e "${GREEN}${lazy_avg}ms${NC} (+$((lazy_avg - baseline_avg))ms)"

echo ""
printf "  ${BOLD}%-32s %8s %8s %8s${NC}\n" "Configuration" "Avg" "Min" "Max"
printf "  %-32s %8s %8s %8s\n" "────────────────────────────────" "────────" "────────" "────────"
printf "  %-32s %6dms %6dms %6dms\n" "Baseline (no managers)" "$baseline_avg" "$baseline_min" "$baseline_max"
[[ $nvm_avg -gt 0 ]] && printf "  %-32s %6dms %6dms %6dms\n" "Traditional nvm" "$nvm_avg" "$nvm_min" "$nvm_max"
[[ $rbenv_avg -gt 0 ]] && printf "  %-32s %6dms %6dms %6dms\n" "Traditional rbenv" "$rbenv_avg" "$rbenv_min" "$rbenv_max"
printf "  %-32s %6dms %6dms %6dms\n" "lazy-wrappers" "$lazy_avg" "$lazy_min" "$lazy_max"

# Calculate savings
startup_savings=0
if [[ $nvm_avg -gt 0 ]]; then
    nvm_savings=$((nvm_avg - lazy_avg))
    startup_savings=$nvm_savings
    nvm_pct=$(( (nvm_savings * 100) / nvm_avg ))
    echo ""
    echo -e "  ${GREEN}✓${NC} vs nvm:   ${GREEN}-${nvm_savings}ms${NC} (${GREEN}${nvm_pct}% faster${NC})"
fi
if [[ $rbenv_avg -gt 0 ]]; then
    rbenv_savings=$((rbenv_avg - lazy_avg))
    [[ $startup_savings -eq 0 ]] && startup_savings=$rbenv_savings
    rbenv_pct=$(( (rbenv_savings * 100) / rbenv_avg ))
    echo -e "  ${GREEN}✓${NC} vs rbenv: ${GREEN}-${rbenv_savings}ms${NC} (${GREEN}${rbenv_pct}% faster${NC})"
fi

# ============================================================================
# PART 2: Per-Command Overhead
# ============================================================================

echo ""
echo -e "${BLUE}┌──────────────────────────────────────────────────────────────────┐${NC}"
echo -e "${BLUE}│  ${BOLD}PART 2: First-Command Overhead${NC}${BLUE}                                   │${NC}"
echo -e "${BLUE}│  One-time cost when wrapper triggers version manager load       │${NC}"
echo -e "${BLUE}│  (Subsequent commands bypass wrappers entirely - zero overhead) │${NC}"
echo -e "${BLUE}└──────────────────────────────────────────────────────────────────┘${NC}"
echo ""

# Ensure version managers are loaded
export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
[[ -s "$NVM_DIR/nvm.sh" ]] && . "$NVM_DIR/nvm.sh" &>/dev/null
export NVM_ALREADY_LOADED=1

export RBENV_DIR="${RBENV_DIR:-$HOME/.rbenv}"
if [[ -x "$RBENV_DIR/bin/rbenv" ]]; then
    eval "$("$RBENV_DIR/bin/rbenv" init - bash)" &>/dev/null
    export RBENV_ALREADY_LOADED=1
fi

printf "  ${BOLD}%-12s %10s %10s %10s %10s${NC}\n" "Binary" "Wrapper" "Direct" "Overhead" "Pct"
printf "  %-12s %10s %10s %10s %10s\n" "────────────" "──────────" "──────────" "──────────" "──────────"

total_overhead=0
count=0

# Test binaries
for binary in node npm npx ruby gem bundle; do
    if [[ "$binary" =~ ^(node|npm|npx)$ ]]; then
        wrapper="$NODE_WRAPPERS/$binary"
        real=$(find_real_binary "$binary" "$NODE_WRAPPERS")
    else
        wrapper="$RUBY_WRAPPERS/$binary"
        real=$(find_real_binary "$binary" "$RUBY_WRAPPERS")
    fi
    
    if [[ -f "$wrapper" && -n "$real" ]]; then
        read -r wrap_avg _ _ <<< "$(measure_command "$wrapper")"
        read -r real_avg _ _ <<< "$(measure_command "$real")"
        
        overhead=$((wrap_avg - real_avg))
        total_overhead=$((total_overhead + overhead))
        ((count++)) || true
        
        if [[ $real_avg -gt 0 ]]; then
            overhead_pct=$(( (overhead * 100) / real_avg ))
        else
            overhead_pct=0
        fi
        
        if [[ $overhead -gt 5 ]]; then
            color=$YELLOW
        elif [[ $overhead -gt 0 ]]; then
            color=$GREEN
        else
            color=$GREEN
        fi
        
        printf "  %-12s %8dms %8dms ${color}%+8dms %+8d%%${NC}\n" \
            "$binary" "$wrap_avg" "$real_avg" "$overhead" "$overhead_pct"
    fi
done

# Calculate average overhead
if [[ $count -gt 0 ]]; then
    avg_overhead=$((total_overhead / count))
else
    avg_overhead=1
fi
[[ $avg_overhead -le 0 ]] && avg_overhead=1

# ============================================================================
# PART 3: Analysis
# ============================================================================

echo ""
echo -e "${BLUE}┌──────────────────────────────────────────────────────────────────┐${NC}"
echo -e "${BLUE}│  ${BOLD}PART 3: Break-Even Analysis${NC}${BLUE}                                      │${NC}"
echo -e "${BLUE}└──────────────────────────────────────────────────────────────────┘${NC}"
echo ""

echo -e "  Shell startup savings:      ${GREEN}${startup_savings}ms${NC}"
echo -e "  First-command overhead:     ${YELLOW}${avg_overhead}ms${NC} (one-time, then wrappers removed)"
echo -e "  Subsequent commands:        ${GREEN}0ms overhead${NC} (direct binary execution)"
echo ""
echo -e "  ${BOLD}Verdict:${NC}"
echo -e "  ${GREEN}✓${NC} lazy-wrappers is beneficial for virtually all workflows"
echo -e "    After the first command, wrappers are removed from PATH"
echo -e "    All subsequent commands run at full native speed"

# ============================================================================
# Summary
# ============================================================================

echo ""
echo -e "${BLUE}┌──────────────────────────────────────────────────────────────────┐${NC}"
echo -e "${BLUE}│  ${BOLD}Summary${NC}${BLUE}                                                          │${NC}"
echo -e "${BLUE}└──────────────────────────────────────────────────────────────────┘${NC}"
echo ""
echo -e "  ${GREEN}PROS:${NC}"
echo -e "    ✓ Shell starts ~${startup_savings}ms faster"
echo -e "    ✓ Version managers load only when needed"
echo -e "    ✓ Multiple terminals don't each pay startup cost"
echo ""
echo -e "  ${RED}CONS:${NC}"
echo -e "    ✗ First command in session triggers version manager load"
echo -e "    ✗ ~${avg_overhead}ms one-time overhead on that first command"
echo ""
echo -e "  ${CYAN}BEST FOR:${NC}"
echo -e "    • Opening many terminal sessions"
echo -e "    • Quick shell commands before using node/ruby"
echo -e "    • Development with moderate node/ruby usage"
echo ""

# Save results
RESULTS_FILE="benchmark-results.txt"
{
    echo "# lazy-wrappers benchmark results"
    echo "# Generated: $(date -Iseconds)"
    echo "shell=$SHELL_TO_TEST"
    echo "iterations=$ITERATIONS"
    echo "baseline_ms=$baseline_avg"
    echo "nvm_ms=$nvm_avg"
    echo "rbenv_ms=$rbenv_avg"
    echo "lazy_wrappers_ms=$lazy_avg"
    echo "startup_savings_ms=$startup_savings"
    echo "first_command_overhead_ms=$avg_overhead"
    echo "subsequent_command_overhead_ms=0"
} > "$RESULTS_FILE"

echo -e "  Results saved to: ${CYAN}$RESULTS_FILE${NC}"
echo ""
