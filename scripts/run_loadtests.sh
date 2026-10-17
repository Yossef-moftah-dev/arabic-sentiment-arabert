#!/usr/bin/env bash
# ==============================================================================
# ProdML Automated Locust Load Testing & Concurrency Benchmark Harness
#
# Benchmarks:
#   1. Baseline FastAPI REST Serving
#   2. BentoML Dynamic Micro-batching Service
#   3. Accelerated ONNX Runtime / Triton Execution Engine
#
# Outputs:
#   - reports/locust_fastapi.html
#   - reports/locust_bentoml.html
#   - reports/locust_trt.html
# ==============================================================================

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

REPORTS_DIR="$PROJECT_ROOT/reports"
mkdir -p "$REPORTS_DIR"

echo "========================================================================"
echo "PRODML MILESTONE 03 — CONCURRENCY & SATURATION BENCHMARKING"
echo "========================================================================"

# Check if target hosts are running or start them locally for benchmark run
FASTAPI_PORT="${FASTAPI_PORT:-8000}"
BENTO_PORT="${BENTO_PORT:-8000}"
TRT_PORT="${TRT_PORT:-8002}"

DURATION="${LOADTEST_DURATION:-15s}"
USERS="${LOADTEST_USERS:-50}"
SPAWN_RATE="${LOADTEST_SPAWN_RATE:-10}"

echo "Benchmark Parameters:"
echo "  • Concurrency Target: $USERS users"
echo "  • Spawn Rate:         $SPAWN_RATE users/sec"
echo "  • Run Duration:       $DURATION"
echo "  • Results Directory:  $REPORTS_DIR"
echo "------------------------------------------------------------------------"

# Function to run locust against a specific endpoint
run_locust_benchmark() {
    local target_name="$1"
    local host_url="$2"
    local html_report="$3"
    local csv_prefix="$REPORTS_DIR/locust_${target_name}"

    echo ""
    echo ">>> Benchmarking $target_name on $host_url ($USERS users, $DURATION)..."
    
    # Check host connectivity
    if ! curl -s -f -m 3 "$host_url/health" > /dev/null 2>&1; then
        echo "  [ERROR] Target $host_url is not reachable or healthy."
        echo "          Cannot execute Locust load test against an unavailable target."
        exit 1
    fi

    uv run locust \
        -f loadtest/locustfile.py \
        --headless \
        -u "$USERS" \
        -r "$SPAWN_RATE" \
        --run-time "$DURATION" \
        --host "$host_url" \
        --html "$html_report" \
        --csv "$csv_prefix" \
        --only-summary

    echo "  ✓ Completed benchmark! Report saved: $html_report"
}

# 1. Benchmark FastAPI Baseline
run_locust_benchmark "fastapi" "http://localhost:${FASTAPI_PORT}" "$REPORTS_DIR/locust_fastapi.html"

# 2. Benchmark BentoML Micro-batching Service
run_locust_benchmark "bentoml" "http://localhost:${BENTO_PORT}" "$REPORTS_DIR/locust_bentoml.html"

# 3. Benchmark Accelerated Runtime (ONNX Runtime / Triton)
run_locust_benchmark "trt" "http://localhost:${TRT_PORT}" "$REPORTS_DIR/locust_trt.html"

echo ""
echo "========================================================================"
echo "✅ All Locust load test benchmarks generated successfully!"
echo "Reports available in: $REPORTS_DIR"
echo "  • $REPORTS_DIR/locust_fastapi.html"
echo "  • $REPORTS_DIR/locust_bentoml.html"
echo "  • $REPORTS_DIR/locust_trt.html"
echo "========================================================================"
