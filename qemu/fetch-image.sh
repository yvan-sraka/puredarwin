#!/usr/bin/env bash
# Download and prepare a PureDarwin disk image for QEMU.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROFILE="${1:-pd-17.4}"
IMAGE_DIR="${PD_IMAGE_DIR:-${SCRIPT_DIR}/images}"
PROFILE_ENV="${SCRIPT_DIR}/profiles/${PROFILE}.env"

die() {
    echo "error: $*" >&2
    exit 1
}

need_cmd() {
    command -v "$1" >/dev/null 2>&1 || die "missing required command: $1"
}

[[ -f "${PROFILE_ENV}" ]] || die "unknown profile '${PROFILE}' (no ${PROFILE_ENV})"

# shellcheck source=/dev/null
source "${PROFILE_ENV}"

mkdir -p "${IMAGE_DIR}"
ARCHIVE_PATH="${IMAGE_DIR}/${PD_ARCHIVE_NAME}"
IMAGE_PATH="${IMAGE_DIR}/${PD_IMAGE_NAME}"

echo "==> Profile: ${PD_PROFILE_NAME} (${PD_PROFILE_VERSION})"
echo "==> Image dir: ${IMAGE_DIR}"

if [[ -f "${IMAGE_PATH}" ]]; then
    echo "==> Image already present: ${IMAGE_PATH}"
else
    need_cmd curl
    echo "==> Downloading ${PD_DOWNLOAD_URL}"
    curl -fL --retry 3 --retry-delay 2 -o "${ARCHIVE_PATH}" "${PD_DOWNLOAD_URL}"

  case "${ARCHIVE_PATH}" in
    *.xz)
      need_cmd xz
      echo "==> Extracting ${ARCHIVE_PATH}"
      xz -dk "${ARCHIVE_PATH}"
      EXTRACTED="${ARCHIVE_PATH%.xz}"
      if [[ "${EXTRACTED}" != "${IMAGE_PATH}" ]]; then
        mv -f "${EXTRACTED}" "${IMAGE_PATH}"
      fi
      ;;
    *.7z)
      need_cmd 7z
      echo "==> Extracting ${ARCHIVE_PATH}"
      (cd "${IMAGE_DIR}" && 7z x -y "${ARCHIVE_PATH}")
      FOUND_VMDK="$(find "${IMAGE_DIR}" -maxdepth 2 -type f -name '*.vmdk' | head -n 1)"
      [[ -n "${FOUND_VMDK}" ]] || die "no .vmdk found inside ${ARCHIVE_PATH}"
      if [[ "${FOUND_VMDK}" != "${IMAGE_PATH}" ]]; then
        mv -f "${FOUND_VMDK}" "${IMAGE_PATH}"
      fi
      ;;
    *)
      die "unsupported archive type: ${ARCHIVE_PATH}"
      ;;
  esac
fi

need_cmd qemu-img
echo "==> Image info:"
qemu-img info "${IMAGE_PATH}"

RAW_PATH="${IMAGE_PATH%.*}.raw"
if [[ ! -f "${RAW_PATH}" ]]; then
  echo "==> Creating raw copy (optional, for --format raw): ${RAW_PATH}"
  qemu-img convert -p -f "${PD_IMAGE_FORMAT}" -O raw "${IMAGE_PATH}" "${RAW_PATH}"
fi

echo "==> Ready."
echo "    VMDK: ${IMAGE_PATH}"
echo "    RAW:  ${RAW_PATH}"
echo "Run: ${SCRIPT_DIR}/run.sh ${PROFILE}"
