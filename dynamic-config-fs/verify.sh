#!/bin/bash -e

export NAME=dynamic-config-fs

export PORT_PROXY="${DYNAMIC_FS_PORT_PROXY:-10420}"
export PORT_ADMIN="${DYNAMIC_FS_PORT_ADMIN:-10421}"

chmod go+r configs/*
chmod go+rx configs

# shellcheck source=examples/verify-common.sh
. "$(dirname "${BASH_SOURCE[0]}")/../verify-common.sh"

run_log "Check for response comes from service1 upstream"
responds_with \
    "Request served by service1" \
    "http://localhost:${PORT_PROXY}"

run_log "Check config for active clusters pointing to service1"
curl -s "http://localhost:${PORT_ADMIN}/config_dump" \
    | jq -r '.configs[1].dynamic_active_clusters' \
    | grep '"address": "service1"'

run_log "Set upstream to service2"
"${DOCKER_COMPOSE[@]}" exec -T proxy sed -i s/service1/service2/ /var/lib/envoy/cds.yaml
wait_for 10 bash -c "responds_with 'Request served by service2' http://localhost:${PORT_PROXY}"

run_log "Check for response comes from service2 upstream"
responds_with \
    "Request served by service2" \
    "http://localhost:${PORT_PROXY}"

run_log "Check config for active clusters pointing to service2"
curl -s "http://localhost:${PORT_ADMIN}/config_dump" \
    | jq -r '.configs[1].dynamic_active_clusters' \
    | grep '"address": "service2"'
