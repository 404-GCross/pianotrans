# Fedora/RPM packaging

This directory contains a Fedora-style dependency closure for PianoTrans.

The goal is a clean RPM packaging path: packages are built from source archives,
dependencies are expressed as RPM requirements, the SoXR Python module links to
the system `libsoxr`, and the piano transcription checkpoint is packaged as RPM
data instead of being downloaded at runtime.

## Packages

Build order:

1. `python-llvmlite`
2. `python-numba`
3. `python-mido`
4. `python-resampy`
5. `python-soxr`
6. `python-librosa`
7. `python-torchlibrosa`
8. `python-piano-transcription-inference`
9. `pianotrans`

`pianotrans` is packaged from the upstream `v1.1` GitHub tag. Upstream
`setup.py` and Nix metadata still report `1.0.1`, so this spec installs the
single-module application directly and uses the release tag as the RPM version.

Fedora 44 already provides several large dependencies, including `ffmpeg-free`,
`python3-tkinter`, `python3-torch`, `python3-numpy`, `python3-scipy`,
`python3-scikit-learn`, `python3-joblib`, `python3-decorator`,
`python3-soundfile`, `python3-pooch`, `python3-lazy-loader`,
`python3-msgpack`, and `python3-matplotlib`.

## Host setup

Install the RPM build toolchain and Fedora-provided dependencies:

```sh
sudo dnf install \
  rpm-build pyproject-rpm-macros python3-devel python3-setuptools python3-wheel \
  python3-build python3-installer python3-setuptools_scm \
  gcc gcc-c++ cmake llvm-devel soxr-devel python3-scikit-build-core \
  python3-nanobind python3-packaging python3-numpy python3-scipy \
  python3-scikit-learn python3-joblib python3-decorator python3-soundfile \
  python3-pooch python3-lazy-loader python3-msgpack python3-matplotlib \
  python3-torch python3-tkinter ffmpeg-free
```

## GitHub Actions

RPM builds can run in GitHub Actions with `.github/workflows/build-rpm.yml`.

Use **Actions -> Build RPM -> Run workflow** to build in a Fedora 44 container.
Tag pushes matching `v*` also trigger the workflow. Successful runs upload a
`pianotrans-rpms-fedora-44-x86_64` artifact containing
`pianotrans-fedora-44-rpm-repo.tar.zst` and `SHA256SUMS`. Successful pushes to
`master` also refresh the `rpm-pre-release` GitHub pre-release with those two
files.

The archive contains binary RPMs, SRPMs, and repository metadata.

The workflow installs build dependencies, downloads source archives and the
checkpoint, builds packages in dependency order, registers each local RPM layer
before building the next layer, and validates the resulting RPM metadata. It
uses `--without tests` to keep hosted-runner disk usage reasonable.

## Local Build

Fetch source archives and patches:

```sh
packaging/rpm/scripts/fetch-rpm-sources.sh dist/rpmbuild/SOURCES
```

For quick spec validation without downloading the 165MB checkpoint:

```sh
FETCH_CHECKPOINT=0 packaging/rpm/scripts/fetch-rpm-sources.sh dist/rpmbuild/SOURCES
```

Build all packages in order:

```sh
packaging/rpm/scripts/build-rpms.sh
```

The script uses `RPM_TOPDIR` when set; otherwise it writes build output under
`dist/rpmbuild`.

To mirror the GitHub Actions build locally:

```sh
INSTALL_AFTER_BUILD=rpm CREATE_REPO=1 RPMBUILD_OPTS="--without tests" \
  packaging/rpm/scripts/build-rpms.sh
```

For a fully isolated Fedora build, use `mock` or COPR and feed the locally built
dependency RPMs into a temporary repository as each layer is completed.

On a normal host build, install the RPMs produced by each dependency layer
before building packages that require them. In particular, `python-numba`
requires the locally built `python3-llvmlite >= 0.49`, because Fedora 44
currently provides `python3-llvmlite 0.46`.

## Install test

After the dependency packages are built and available to DNF:

```sh
sudo dnf install ./dist/rpmbuild/RPMS/*/*.rpm
pianotrans --cli test/cut_liszt.opus
```

The expected smoke-test result is `test/cut_liszt.opus.mid`.
