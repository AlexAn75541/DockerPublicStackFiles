#!/usr/bin/env sh

set -eu

MODE="${1:---watch}"
WORK_DIR="${ASU_WORK_DIR:-/srv/asu/build}"
OUTPUT_DIR="${ASU_OUTPUT_DIR:-/srv/asu/output}"
DELAY_SECONDS="${CLEANUP_DELAY_SECONDS:-20}"
LOCK_DIR="/tmp/asu-cleanup.lock"

log() {
	printf '%s %s\n' "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" "$*"
}

cleanup_build_files() {
	if [ ! -d "$WORK_DIR" ]; then
		log "Skip cleanup: work dir not found: $WORK_DIR"
		return 0
	fi

	if ! mkdir "$LOCK_DIR" 2>/dev/null; then
		log "Cleanup already running, skip this trigger"
		return 0
	fi

	# shellcheck disable=SC2064
	trap "rmdir '$LOCK_DIR'" EXIT INT TERM

	log "Cleaning generated build files in: $WORK_DIR"

	find "$WORK_DIR" -mindepth 1 -maxdepth 1 -exec rm -rf {} +

	log "Cleanup complete"

	rmdir "$LOCK_DIR"
	trap - EXIT INT TERM
}

watch_for_build_outputs() {
	if [ ! -d "$OUTPUT_DIR" ]; then
		log "Output dir not found, creating: $OUTPUT_DIR"
		mkdir -p "$OUTPUT_DIR"
	fi

	log "Watching $OUTPUT_DIR for completed firmware outputs"

	# Trigger cleanup when common firmware artifacts are created or moved in.
	while inotifywait -q -r -e create -e moved_to -e close_write "$OUTPUT_DIR"; do
		if find "$OUTPUT_DIR" -type f \( -name "*.bin" -o -name "*.img.gz" -o -name "*.manifest" -o -name "*.json" \) | grep -q .; then
			log "Firmware output detected, waiting ${DELAY_SECONDS}s before cleanup"
			sleep "$DELAY_SECONDS"
			cleanup_build_files
		fi
	done
}

case "$MODE" in
	--once)
		cleanup_build_files
		;;
	--watch)
		watch_for_build_outputs
		;;
	*)
		printf 'Usage: %s [--watch|--once]\n' "$0" >&2
		exit 1
		;;
esac
