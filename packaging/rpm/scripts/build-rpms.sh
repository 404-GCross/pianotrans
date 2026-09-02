#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/../../.." && pwd)"
topdir="${RPM_TOPDIR:-"$repo_root/dist/rpmbuild"}"
install_after_build="${INSTALL_AFTER_BUILD:-0}"
create_repo="${CREATE_REPO:-0}"
rpmbuild_opts=()

if [[ -n "${RPMBUILD_OPTS:-}" ]]; then
  # shellcheck disable=SC2206
  rpmbuild_opts=($RPMBUILD_OPTS)
fi

mkdir -p "$topdir"/{BUILD,RPMS,SOURCES,SPECS,SRPMS}
"$script_dir/fetch-rpm-sources.sh" "$topdir/SOURCES"
cp "$script_dir"/../*.spec "$topdir/SPECS"/

specs=(
  python-llvmlite
  python-numba
  python-mido
  python-resampy
  python-soxr
  python-librosa
  python-torchlibrosa
  python-piano-transcription-inference
  pianotrans
)

for spec in "${specs[@]}"; do
  stamp="$(mktemp)"
  rpmbuild "${rpmbuild_opts[@]}" --define "_topdir $topdir" -ba "$topdir/SPECS/$spec.spec"

  if [[ "$install_after_build" != "0" ]]; then
    if [[ "${EUID:-$(id -u)}" != "0" ]]; then
      echo "INSTALL_AFTER_BUILD requires root so local RPMs can be registered" >&2
      exit 1
    fi

    mapfile -t new_rpms < <(find "$topdir/RPMS" -type f -name '*.rpm' -newer "$stamp" | sort)
    if [[ "${#new_rpms[@]}" -gt 0 ]]; then
      case "$install_after_build" in
        1|dnf)
          dnf install -y --setopt=install_weak_deps=False "${new_rpms[@]}"
          ;;
        rpm|nodeps)
          rpm -Uvh --replacepkgs --nodeps "${new_rpms[@]}"
          ;;
        *)
          echo "Unsupported INSTALL_AFTER_BUILD mode: $install_after_build" >&2
          exit 1
          ;;
      esac
    fi
  fi

  rm -f "$stamp"
done

if [[ "$create_repo" == "1" ]]; then
  createrepo_c "$topdir/RPMS"
fi

find "$topdir/RPMS" "$topdir/SRPMS" -type f -name '*.rpm' -print
