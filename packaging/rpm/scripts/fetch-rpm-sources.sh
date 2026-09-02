#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
rpm_dir="$(cd "$script_dir/.." && pwd)"
dest="${1:-"$rpm_dir/SOURCES"}"
checkpoint_name="piano-transcription-inference.pth"
checkpoint_sha256="c3fa9730725bf4a762f1c14bc80cd5986eacda01b026f5a4a2525cd607876141"

mkdir -p "$dest"

download() {
  local name="$1"
  local url="$2"
  local sha256="$3"
  local target="$dest/$name"

  if [[ -f "$target" ]]; then
    if printf '%s  %s\n' "$sha256" "$target" | sha256sum --check --status; then
      return
    fi
    mv "$target" "$target.bad.$(date +%s)"
  fi

  curl -L --fail --retry 3 --output "$target" "$url"
  printf '%s  %s\n' "$sha256" "$target" | sha256sum --check --status
}

download "mido-1.3.3.tar.gz" \
  "https://files.pythonhosted.org/packages/source/m/mido/mido-1.3.3.tar.gz" \
  "1aecb30b7f282404f17e43768cbf74a6a31bf22b3b783bdd117a1ce9d22cb74c"
download "resampy-0.4.3.tar.gz" \
  "https://files.pythonhosted.org/packages/source/r/resampy/resampy-0.4.3.tar.gz" \
  "a0d1c28398f0e55994b739650afef4e3974115edbe96cd4bb81968425e916e47"
download "llvmlite-0.49.0.tar.gz" \
  "https://files.pythonhosted.org/packages/source/l/llvmlite/llvmlite-0.49.0.tar.gz" \
  "00f16db782f4a13c78c5804aedc434e46794a77e89999a168f9401106270e50a"
download "numba-0.67.0.tar.gz" \
  "https://files.pythonhosted.org/packages/source/n/numba/numba-0.67.0.tar.gz" \
  "cd75aa535b33fa05d9d930b1ae8af9f97a2881e96d72dfb38ec9b78284d9f851"
download "soxr-1.1.0.tar.gz" \
  "https://files.pythonhosted.org/packages/source/s/soxr/soxr-1.1.0.tar.gz" \
  "9f228ae21c78fa9359ca98d8a5e8e91f30639e438e574133dace62c5b5309e44"
download "librosa-1.0.0.tar.gz" \
  "https://files.pythonhosted.org/packages/source/l/librosa/librosa-1.0.0.tar.gz" \
  "73ed480d4022e436e85dfa6f6b06ff38a259b9210039ac99939cd64854b61a57"
download "torchlibrosa-0.1.0.tar.gz" \
  "https://files.pythonhosted.org/packages/source/t/torchlibrosa/torchlibrosa-0.1.0.tar.gz" \
  "62a8beedf9c9b4141a06234df3f10229f7ba86e67678ccee02489ec4ef044028"
download "piano_transcription_inference-0.0.6.tar.gz" \
  "https://files.pythonhosted.org/packages/source/p/piano-transcription-inference/piano_transcription_inference-0.0.6.tar.gz" \
  "b6dd00f9b4bcacb6140725f03b4139a5e0f4acd35a69e492a5d1f734ecfbd231"
download "pianotrans-1.1.tar.gz" \
  "https://github.com/404-GCross/pianotrans/archive/refs/tags/v1.1/pianotrans-1.1.tar.gz" \
  "af2ae6fd33b1b8411cf282ebfc8e1c22a0c08d5bf7e4194baaf962fdec4a95fa"
if [[ "${FETCH_CHECKPOINT:-1}" != "0" ]]; then
  download "$checkpoint_name" \
    "https://zenodo.org/record/4034264/files/CRNN_note_F1%3D0.9677_pedal_F1%3D0.9186.pth?download=1" \
    "$checkpoint_sha256"
else
  checkpoint_target="$dest/$checkpoint_name"
  if [[ -f "$checkpoint_target" ]] &&
     ! printf '%s  %s\n' "$checkpoint_sha256" "$checkpoint_target" | sha256sum --check --status; then
    mv "$checkpoint_target" "$checkpoint_target.bad.$(date +%s)"
  fi
  echo "Skipping checkpoint download because FETCH_CHECKPOINT=0"
fi

cp "$rpm_dir"/patches/*.patch "$dest"/

echo "RPM sources are ready in $dest"
