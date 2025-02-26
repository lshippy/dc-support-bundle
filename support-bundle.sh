#!/bin/bash

# Get the hostname and timestamp (formatted as YYYY_MM_DD)
HOSTNAME=$(hostname)
TIMESTAMP=$(date +"%Y_%m_%d")
SUPPORT_BUNDLE="support_bundle_${HOSTNAME}_${TIMESTAMP}"

# Default log time range (2 hours) unless specified via CLI argument
LOG_DURATION=${1:-2h}

# Create a directory for storing the support bundle
mkdir -p "$SUPPORT_BUNDLE"

# Collect system information into a single report file
SYSTEM_REPORT="$SUPPORT_BUNDLE/system_report.txt"
echo "Collecting system information..."

{
    echo "========== SYSTEM INFO =========="
    printf "%-15s %s\n" "Hostname:" "$HOSTNAME"
    printf "%-15s %s\n" "IP address" "$(hostname -I)"
    printf "%-15s %s\n" "OS:" "$(grep 'PRETTY_NAME' /etc/os-release | cut -d= -f2 | tr -d '\"')"
    printf "%-15s %s\n" "Kernel:" "$(uname -r)"
    printf "%-15s %s\n" "Architecture:" "$(uname -m)"
    printf "%-15s %s\n" "Uptime:" "$(uptime -p)"

    echo -e "\n========== MEMORY INFO =========="
    free -h

    echo -e "\n========== DISK USAGE =========="
    df -h

    echo -e "\n========== TOP CPU USAGE =========="
    printf "%-8s %-10s %-6s %-6s %s\n" "PID" "USER" "%CPU" "%MEM" "COMMAND"
    ps -eo pid,user,%cpu,%mem,command --sort=-%cpu --no-headers | head -n 5 | awk '{printf "%-8s %-10s %-6s %-6s %s\n", $1, $2, $3, $4, $5}'

    echo -e "\n========== TOP MEMORY USAGE =========="
    printf "%-8s %-10s %-6s %-6s %s\n" "PID" "USER" "%CPU" "%MEM" "COMMAND"
    ps -eo pid,user,%cpu,%mem,command --sort=-%mem --no-headers | head -n 5 | awk '{printf "%-8s %-10s %-6s %-6s %s\n", $1, $2, $3, $4, $5}'

    echo -e "\n========== DOCKER VERSION =========="
    docker version
    echo -e "\n========== DOCKER COMPOSE VERSION =========="
    docker compose version
    echo -e "\n========== DOCKER SYSTEM STORAGE =========="
    docker system df

} > "$SYSTEM_REPORT"

# Detect running Docker Compose projects
echo "Detecting active Docker Compose projects..."
mkdir -p "$SUPPORT_BUNDLE/compose_configs"
mkdir -p "$SUPPORT_BUNDLE/compose_logs"

# Ensure jq is installed
if ! command -v jq &> /dev/null; then
    echo "Error: 'jq' is required but not installed. Install it first."
    exit 1
fi

# Get Docker Compose projects (handling both string & array cases in ConfigFiles)
docker compose ls --format json | jq -r '.[] | "\(.Name) \(.ConfigFiles | (if type == "array" then .[0] else . end))"' | while read -r COMPOSE_PROJECT COMPOSE_CONFIG_FILE; do
    # Print project and config file
    echo "Found project '$COMPOSE_PROJECT' with config file '$COMPOSE_CONFIG_FILE'"

    # Extract the working directory from the config file
    COMPOSE_DIR=$(dirname "$COMPOSE_CONFIG_FILE")

    # Validate that directory exists
    if [ -d "$COMPOSE_DIR" ]; then
        echo "Processing Compose project: $COMPOSE_PROJECT at $COMPOSE_DIR"

        # Create directories for each project
        mkdir -p "$SUPPORT_BUNDLE/compose_configs/$COMPOSE_PROJECT"

        # Copy docker compose files
        cp "$COMPOSE_CONFIG_FILE" "$SUPPORT_BUNDLE/compose_configs/$COMPOSE_PROJECT/"

        # Copy and redact .env file if it exists
        if [ -f "$COMPOSE_DIR/.env" ]; then
            echo "Redacting sensitive info in .env file for $COMPOSE_PROJECT"
            sed -E 's/^(.*(PASS|PASSWORD|SECRET)[^=]*)=.*/\1=<REDACTED>/I' "$COMPOSE_DIR/.env" > "$SUPPORT_BUNDLE/compose_configs/$COMPOSE_PROJECT/${COMPOSE_PROJECT}.env"
        fi

        # Collect Docker Compose status (including stopped containers) & suppress warnings
        echo "Collecting Docker Compose status for $COMPOSE_PROJECT"
        (cd "$COMPOSE_DIR" && docker compose ps -a 2>/dev/null) > "$SUPPORT_BUNDLE/compose_configs/$COMPOSE_PROJECT/${COMPOSE_PROJECT}_status.txt"

        # Collect logs & suppress warnings
        echo "Collecting logs for $COMPOSE_PROJECT"
	(cd "$COMPOSE_DIR" && docker compose --profile "*" logs --since "$LOG_DURATION" --timestamps 2>/dev/null) > "$SUPPORT_BUNDLE/compose_logs/${COMPOSE_PROJECT}_logs.txt"

    else
        echo "WARNING: Directory '$COMPOSE_DIR' does not exist for project '$COMPOSE_PROJECT'"
    fi
done

# Zip the support bundle
echo "Zipping all collected information..."
ZIP_FILENAME="${SUPPORT_BUNDLE}.zip"
zip -r "$ZIP_FILENAME" "$SUPPORT_BUNDLE"

# Cleanup raw files
rm -r "$SUPPORT_BUNDLE"

echo "Done! Support bundle saved as $ZIP_FILENAME"