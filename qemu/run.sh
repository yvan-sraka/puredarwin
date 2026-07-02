#!/usr/bin/env bash
# Launch PureDarwin in QEMU on Linux.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROFILE="pd-17.4"
DISK_FORMAT=""
EXTRA_QEMU_ARGS=()

usage() {
    cat <<'EOF'
Usage: run.sh [profile] [options]

Profiles:
  pd-17.4       PureDarwin 17.4 Beta (default)
  pd-xmas-bte   PureDarwin XMas Brain Transplant Edition

Options:
  --format FMT  Disk format: vmdk (default) or raw
  --help        Show this help

Environment:
  PD_IMAGE_DIR, PD_MEMORY_MB, PD_SMP, PD_ACCEL, PD_SERIAL_LOG
EOF
}

die() {
    echo "error: $*" >&2
    exit 1
}

need_cmd() {
    command -v "$1" >/dev/null 2>&1 || die "missing required command: $1"
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --help|-h)
            usage
            exit 0
            ;;
        --format)
            [[ $# -ge 2 ]] || die "--format requires an argument"
            DISK_FORMAT="$2"
            shift 2
            ;;
        --)
            shift
            EXTRA_QEMU_ARGS+=("$@")
            break
            ;;
        -*)
            die "unknown option: $1"
            ;;
        *)
            if [[ "${PROFILE}" == "pd-17.4" && "$1" != "pd-17.4" ]]; then
                PROFILE="$1"
            elif [[ "$1" == "pd-17.4" || "$1" == "pd-xmas-bte" ]]; then
                PROFILE="$1"
            else
                EXTRA_QEMU_ARGS+=("$1")
            fi
            shift
            ;;
    esac
done

PROFILE_ENV="${SCRIPT_DIR}/profiles/${PROFILE}.env"
PROFILE_INI="${SCRIPT_DIR}/profiles/${PROFILE}.ini"
IMAGE_DIR="${PD_IMAGE_DIR:-${SCRIPT_DIR}/images}"

[[ -f "${PROFILE_ENV}" ]] || die "unknown profile '${PROFILE}'"
[[ -f "${PROFILE_INI}" ]] || die "missing profile config ${PROFILE_INI}"

ENV_MEMORY="${PD_MEMORY_MB:-}"
ENV_SMP="${PD_SMP:-}"
ENV_ACCEL="${PD_ACCEL:-}"

# shellcheck source=/dev/null
source "${PROFILE_ENV}"

[[ -n "${ENV_MEMORY}" ]] && PD_MEMORY_MB="${ENV_MEMORY}"
[[ -n "${ENV_SMP}" ]] && PD_SMP="${ENV_SMP}"
[[ -n "${ENV_ACCEL}" ]] && PD_ACCEL="${ENV_ACCEL}"

IMAGE_PATH="${IMAGE_DIR}/${PD_IMAGE_NAME}"
DISK_FORMAT="${DISK_FORMAT:-${PD_IMAGE_FORMAT}}"

if [[ "${DISK_FORMAT}" == "raw" ]]; then
    IMAGE_PATH="${IMAGE_DIR}/${PD_IMAGE_NAME%.*}.raw"
fi

[[ -f "${IMAGE_PATH}" ]] || die "image not found: ${IMAGE_PATH} (run ${SCRIPT_DIR}/fetch-image.sh ${PROFILE} first)"

MEMORY_MB="${PD_MEMORY_MB}"
SMP="${PD_SMP}"
CPU_MODEL="${PD_CPU_MODEL:-Penryn}"

if [[ -n "${PD_ACCEL:-}" ]]; then
    ACCEL="${PD_ACCEL}"
elif [[ -r /dev/kvm ]]; then
    ACCEL="kvm"
else
    ACCEL="tcg"
fi

if [[ -n "${PD_SERIAL_LOG:-}" ]]; then
    SERIAL_BACKEND="file"
    SERIAL_PATH="${PD_SERIAL_LOG}"
else
    SERIAL_BACKEND="stdio"
    SERIAL_PATH=""
fi

need_cmd qemu-system-x86_64
need_cmd mktemp

RUNTIME_INI="$(mktemp "${TMPDIR:-/tmp}/puredarwin-qemu-XXXXXX.ini")"
cleanup() {
    rm -f "${RUNTIME_INI}"
}
trap cleanup EXIT

if [[ "${SERIAL_BACKEND}" == "file" ]]; then
    SERIAL_PATH_LINE="  path = \"${SERIAL_PATH}\""
else
    SERIAL_PATH_LINE=""
fi

sed \
    -e "s|@PD_DISK_IMAGE@|${IMAGE_PATH}|g" \
    -e "s|@PD_DISK_FORMAT@|${DISK_FORMAT}|g" \
    -e "s|@PD_ACCEL@|${ACCEL}|g" \
    -e "s|@PD_MEMORY_MB@|${MEMORY_MB}|g" \
    -e "s|@PD_SMP@|${SMP}|g" \
    -e "s|@PD_SERIAL_BACKEND@|${SERIAL_BACKEND}|g" \
    -e "s|@PD_SERIAL_PATH_LINE@|${SERIAL_PATH_LINE}|g" \
    "${PROFILE_INI}" > "${RUNTIME_INI}"

echo "==> ${PD_PROFILE_NAME}"
echo "==> Image: ${IMAGE_PATH} (${DISK_FORMAT})"
echo "==> CPU: ${CPU_MODEL}, RAM: ${MEMORY_MB} MB, SMP: ${SMP}, accel: ${ACCEL}"
echo "==> Serial on stdio (Ctrl-a x to quit)"
echo

QEMU_CMD=(
    qemu-system-x86_64
    -name "puredarwin-${PROFILE}"
    -cpu "${CPU_MODEL}"
    -no-reboot
    -readconfig "${RUNTIME_INI}"
)

if [[ ${#EXTRA_QEMU_ARGS[@]} -gt 0 ]]; then
    QEMU_CMD+=("${EXTRA_QEMU_ARGS[@]}")
fi

exec "${QEMU_CMD[@]}"
