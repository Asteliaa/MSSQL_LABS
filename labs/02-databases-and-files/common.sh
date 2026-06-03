#!/usr/bin/env bash
_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMPOSE_DIR="${_SCRIPT_DIR}/../../docker"
SQLCMD="/opt/mssql-tools18/bin/sqlcmd"
SA_PASS="Strong_Passw0rd!"
compose_up()    { (cd "$COMPOSE_DIR" && docker compose up -d); }
compose_ps()    { (cd "$COMPOSE_DIR" && docker compose ps); }
compose_stop()  { (cd "$COMPOSE_DIR" && docker compose stop "$1"); }
compose_start() { (cd "$COMPOSE_DIR" && docker compose start "$1"); }
run_container_bash() {
    local container="$1"
    local cmd="$2"
    docker exec -i "$container" bash -c "$cmd"
}
run_sql_file() {
    local container="$1"
    local script_path="$2"
    docker exec -i "$container" "$SQLCMD" \
        -S localhost -U SA -P "$SA_PASS" -C \
        -W -w 300 \
        -i "$script_path"
}
run_sql_query() {
    local container="$1"
    local query="$2"
    docker exec -i "$container" "$SQLCMD" \
        -S localhost -U SA -P "$SA_PASS" -C \
        -W -w 300 \
        -Q "$query"
}
expect_sql_failure() {
    local container="$1"
    local query="$2"
    shift 2
    local output
    output=$(docker exec -i "$container" "$SQLCMD" \
        -S localhost -C -W -w 300 \
        "$@" \
        -Q "$query" 2>&1)
    if echo "$output" | grep -q "Msg [0-9]"; then
        echo "OK (access denied as expected)"
        return 0
    else
        echo "UNEXPECTED SUCCESS: $query"
        echo "$output"
        return 1
    fi
}
