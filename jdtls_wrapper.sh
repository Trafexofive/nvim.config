#!/usr/bin/env bash

# JDTLS Launcher Wrapper (The "Nuclear" Option)
# This script completely bypasses the Mason Python wrapper and launches JDTLS manually.
# It guarantees the correct Java version (21) is used for the server process.

# 1. Configuration
# ----------------------------------------------------------------------------
JAVA_BIN="/usr/lib/jvm/java-21-openjdk/bin/java"
JDTLS_HOME="$HOME/.local/share/nvim/mason/packages/jdtls"
CONFIG_DIR="$JDTLS_HOME/config_linux"
WORKSPACE_ROOT="$HOME/.local/share/nvim/jdtls-workspace"
PLUGIN_DIR="$JDTLS_HOME/plugins"

# Find the Equinox Launcher JAR dynamically
LAUNCHER_JAR=$(find "$PLUGIN_DIR" -name "org.eclipse.equinox.launcher_*.jar" | head -n 1)

# Generate a unique workspace for the current project
# We hash the current working directory to create a unique workspace ID
PROJECT_NAME=$(basename "$PWD")
PROJECT_HASH=$(echo -n "$PWD" | sha1sum | awk '{print $1}')
DATA_DIR="$WORKSPACE_ROOT/$PROJECT_NAME-$PROJECT_HASH"

# 2. Logging
# ----------------------------------------------------------------------------
LOG_FILE="/tmp/jdtls_wrapper_nuclear.log"
echo "--- [$(date)] Starting JDTLS Wrapper ---" >> "$LOG_FILE"
echo "CWD: $PWD" >> "$LOG_FILE"
echo "Java: $JAVA_BIN" >> "$LOG_FILE"
echo "Launcher: $LAUNCHER_JAR" >> "$LOG_FILE"
echo "Data Dir: $DATA_DIR" >> "$LOG_FILE"

if [ ! -f "$JAVA_BIN" ]; then
    echo "CRITICAL ERROR: Java 21 not found at $JAVA_BIN" >> "$LOG_FILE"
    exit 1
fi

if [ -z "$LAUNCHER_JAR" ]; then
    echo "CRITICAL ERROR: Equinox Launcher JAR not found in $PLUGIN_DIR" >> "$LOG_FILE"
    exit 1
fi

mkdir -p "$DATA_DIR"

# 3. Launch
# ----------------------------------------------------------------------------
# These arguments mimic what the Python script constructs, but we control the Java executable.
CMD=(
    "$JAVA_BIN"
    "-Declipse.application=org.eclipse.jdt.ls.core.id1"
    "-Dosgi.bundles.defaultStartLevel=4"
    "-Declipse.product=org.eclipse.jdt.ls.core.product"
    "-Dlog.protocol=true"
    "-Dlog.level=ALL"
    "-Xms1g"
    "-Xmx2G"
    "--add-modules=ALL-SYSTEM"
    "--add-opens" "java.base/java.util=ALL-UNNAMED"
    "--add-opens" "java.base/java.lang=ALL-UNNAMED"
    "-jar" "$LAUNCHER_JAR"
    "-configuration" "$CONFIG_DIR"
    "-data" "$DATA_DIR"
    "$@"
)

echo "Executing: ${CMD[*]}" >> "$LOG_FILE"

# Execute and replace the shell
exec "${CMD[@]}"
