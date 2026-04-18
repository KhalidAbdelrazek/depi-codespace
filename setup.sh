#!/bin/bash

# ============================================================
#  Apache Airflow 3.1.0 — Setup for GitHub Codespaces
#  - No unsupported CLI flags
#  - Fixes "Invalid or unsafe next URL" login error
#  - Binds to 0.0.0.0 via environment variable (correct way)
# ============================================================

set -euo pipefail

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

print_step()    { echo ""; echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"; echo -e "${BLUE}  STEP $1: $2${NC}"; echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"; }
print_success() { echo -e "${GREEN}  ✔  $1${NC}"; }
print_info()    { echo -e "${YELLOW}  ➜  $1${NC}"; }
print_error()   { echo -e "${RED}  ✘  FAILED: $1${NC}"; exit 1; }
print_check()   { echo -e "${GREEN}  ✔  CHECK OK: $1${NC}"; }

AIRFLOW_VERSION="3.1.0"
VENV_DIR="$HOME/airflow-venv"
export AIRFLOW_HOME="$HOME/airflow"
AIRFLOW_PORT="8080"

clear
echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║    Apache Airflow 3.1.0 — GitHub Codespaces Setup   ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════╝${NC}"
echo ""
print_info "Airflow $AIRFLOW_VERSION | Python 3.12 | Standalone Mode"
print_info "Estimated time: 5-10 minutes"
echo ""

# ══════════════════════════════════════════════════════════
# STEP 1 — Kill old processes
# ══════════════════════════════════════════════════════════
print_step "1" "Stopping any old Airflow processes"

pkill -9 -f "airflow" 2>/dev/null && print_info "Killed old processes" || print_info "Nothing was running"
rm -f "$AIRFLOW_HOME"/airflow-*.pid 2>/dev/null || true
fuser -k ${AIRFLOW_PORT}/tcp 2>/dev/null || true
sleep 2
print_success "Clean"

# ══════════════════════════════════════════════════════════
# STEP 2 — Detect Codespace public URL
# ══════════════════════════════════════════════════════════
print_step "2" "Detecting Codespace public URL"

if [ -n "${CODESPACE_NAME:-}" ] && [ -n "${GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN:-}" ]; then
    CODESPACE_URL="https://${CODESPACE_NAME}-${AIRFLOW_PORT}.${GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN}"
    print_success "URL: $CODESPACE_URL"
else
    CODESPACE_URL="http://localhost:${AIRFLOW_PORT}"
    print_info "Not in Codespaces — using localhost"
fi

# ══════════════════════════════════════════════════════════
# STEP 3 — Check / install Python 3.12
# ══════════════════════════════════════════════════════════
print_step "3" "Checking Python"

if command -v python3.12 &>/dev/null; then
    PYTHON_BIN="python3.12"
elif command -v python3 &>/dev/null; then
    VER=$(python3 -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')")
    if [[ "$VER" == "3.12" || "$VER" == "3.11" || "$VER" == "3.10" ]]; then
        PYTHON_BIN="python3"
    else
        print_info "Python $VER found — installing 3.12..."
        sudo apt-get update -qq
        sudo apt-get install -y python3.12 python3.12-venv python3.12-dev -qq
        PYTHON_BIN="python3.12"
    fi
else
    print_info "No Python found — installing 3.12..."
    sudo apt-get update -qq
    sudo apt-get install -y python3.12 python3.12-venv python3.12-dev -qq
    PYTHON_BIN="python3.12"
fi

PY_VER=$($PYTHON_BIN -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')")
print_check "Python $PY_VER"

# ══════════════════════════════════════════════════════════
# STEP 4 — Always create a clean venv
# ══════════════════════════════════════════════════════════
print_step "4" "Creating a clean virtual environment"

# Always delete old venv to avoid package conflicts
[ -d "$VENV_DIR" ] && { print_info "Removing old venv..."; rm -rf "$VENV_DIR"; }

$PYTHON_BIN -m venv "$VENV_DIR"
[ -f "$VENV_DIR/bin/pip"    ] || print_error "pip missing from venv"
[ -f "$VENV_DIR/bin/python" ] || print_error "python missing from venv"
print_check "Clean venv at $VENV_DIR"

PIP="$VENV_DIR/bin/pip"
PYTHON="$VENV_DIR/bin/python"
AIRFLOW_BIN="$VENV_DIR/bin/airflow"

# ══════════════════════════════════════════════════════════
# STEP 5 — Upgrade pip inside the venv
# ══════════════════════════════════════════════════════════
print_step "5" "Upgrading pip"

$PIP install --upgrade pip setuptools wheel --quiet
print_check "pip $($PIP --version | cut -d' ' -f2)"

# ══════════════════════════════════════════════════════════
# STEP 6 — Install Airflow 3.1.0 with correct constraints
# ══════════════════════════════════════════════════════════
print_step "6" "Installing Apache Airflow $AIRFLOW_VERSION (5-10 mins...)"

CONSTRAINT_URL="https://raw.githubusercontent.com/apache/airflow/constraints-${AIRFLOW_VERSION}/constraints-${PY_VER}.txt"
print_info "Constraints: $CONSTRAINT_URL"

HTTP_STATUS=$(curl -o /dev/null -s -w "%{http_code}" "$CONSTRAINT_URL")
[ "$HTTP_STATUS" = "200" ] || print_error "Constraints file not found (HTTP $HTTP_STATUS)"
print_check "Constraints file reachable"

$PIP install "apache-airflow==${AIRFLOW_VERSION}" \
    --constraint "$CONSTRAINT_URL" \
    --no-cache-dir \
    --quiet

[ -f "$AIRFLOW_BIN" ] || print_error "Airflow binary missing after install"
print_check "Airflow $($AIRFLOW_BIN version) installed"

# ══════════════════════════════════════════════════════════
# STEP 7 — Create folders + set environment variables
# ══════════════════════════════════════════════════════════
print_step "7" "Configuring Airflow environment"

mkdir -p "$AIRFLOW_HOME/dags" "$AIRFLOW_HOME/logs" "$AIRFLOW_HOME/plugins"

# ── These env vars are the CORRECT way to configure Airflow 3.x ──
#
# AIRFLOW__API__HOST        → binds the api-server to 0.0.0.0
#                             so Codespaces can forward the port
#                             (replaces broken sed patches on airflow.cfg)
#
# AIRFLOW__API__BASE_URL    → tells Airflow its public HTTPS address
#                             fixes "Invalid or unsafe next URL" login error
#
export AIRFLOW__API__HOST="0.0.0.0"
export AIRFLOW__API__BASE_URL="$CODESPACE_URL"

# Save all env vars to .bashrc so they work after a restart
grep -v "AIRFLOW" "$HOME/.bashrc" > /tmp/.bashrc_clean 2>/dev/null || true
mv /tmp/.bashrc_clean "$HOME/.bashrc"
cat >> "$HOME/.bashrc" << BASHRC

# ── Apache Airflow 3.1.0 ─────────────────────────────────
export AIRFLOW_HOME="\$HOME/airflow"
export AIRFLOW__API__HOST="0.0.0.0"
export AIRFLOW__API__BASE_URL="${CODESPACE_URL}"
source "\$HOME/airflow-venv/bin/activate"
# ─────────────────────────────────────────────────────────
BASHRC

print_check "AIRFLOW_HOME         = $AIRFLOW_HOME"
print_check "AIRFLOW__API__HOST   = $AIRFLOW__API__HOST"
print_check "AIRFLOW__API__BASE_URL = $AIRFLOW__API__BASE_URL"

# ══════════════════════════════════════════════════════════
# STEP 8 — Create a sample DAG
# ══════════════════════════════════════════════════════════
print_step "8" "Creating a Hello World DAG"

cat > "$AIRFLOW_HOME/dags/hello_world.py" << 'DAGEOF'
"""
Hello World DAG — a simple beginner example.
Two tasks that run in order: say_hello → say_goodbye
"""
from airflow import DAG
from airflow.operators.python import PythonOperator
from datetime import datetime

with DAG(
    dag_id="hello_world",
    description="My first Airflow workflow",
    start_date=datetime(2024, 1, 1),
    schedule="@daily",
    catchup=False,
    tags=["example", "beginner"],
) as dag:

    def say_hello():
        print("Hello from Apache Airflow 3.1!")

    def say_goodbye():
        print("Workflow complete!")

    t1 = PythonOperator(task_id="say_hello",   python_callable=say_hello)
    t2 = PythonOperator(task_id="say_goodbye", python_callable=say_goodbye)
    t1 >> t2
DAGEOF

[ -f "$AIRFLOW_HOME/dags/hello_world.py" ] || print_error "DAG file was not created"
print_check "hello_world.py created"

# ══════════════════════════════════════════════════════════
# STEP 9 — Final checks
# ══════════════════════════════════════════════════════════
print_step "9" "Final checks"

print_check "Python  : $($PYTHON --version)"
print_check "Airflow : $($AIRFLOW_BIN version)"
print_check "Home    : $AIRFLOW_HOME"
print_check "Host    : $AIRFLOW__API__HOST"
print_check "Base URL: $AIRFLOW__API__BASE_URL"
echo ""
print_success "All checks passed!"

# ══════════════════════════════════════════════════════════
# STEP 10 — Launch
# ══════════════════════════════════════════════════════════
print_step "10" "Launching Airflow Standalone"

echo ""
echo -e "${YELLOW}  ╔════════════════════════════════════════════════════╗${NC}"
echo -e "${YELLOW}  ║  1. Watch for this line in the output below:       ║${NC}"
echo -e "${YELLOW}  ║     Login with username: admin  password: XXXXX    ║${NC}"
echo -e "${YELLOW}  ║     Write that password down!                      ║${NC}"
echo -e "${YELLOW}  ╠════════════════════════════════════════════════════╣${NC}"
echo -e "${YELLOW}  ║  2. Open the UI:                                   ║${NC}"
echo -e "${YELLOW}  ║     PORTS tab → click the link for port 8080       ║${NC}"
echo -e "${YELLOW}  ╠════════════════════════════════════════════════════╣${NC}"
echo -e "${YELLOW}  ║  3. To stop Airflow: press Ctrl + C                ║${NC}"
echo -e "${YELLOW}  ╚════════════════════════════════════════════════════╝${NC}"
echo ""

# standalone takes no --host or --port flags in Airflow 3.x
# host binding is controlled by AIRFLOW__API__HOST set above
exec "$AIRFLOW_BIN" standalone