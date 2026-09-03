%global pypi_name piano_transcription_inference
%global dist_name piano-transcription-inference
%global checkpoint_name note_F1=0.9677_pedal_F1=0.9186.pth

Name:           python-%{dist_name}
Version:        0.0.6
Release:        1%{?dist}
Summary:        Piano transcription inference toolbox

License:        MIT
URL:            https://github.com/qiuqiangkong/piano_transcription_inference
Source0:        %{pypi_source %{pypi_name} %{version}}
# Downloaded by scripts/fetch-rpm-sources.sh from:
# https://zenodo.org/record/4034264/files/CRNN_note_F1%3D0.9677_pedal_F1%3D0.9186.pth?download=1
Source1:        %{dist_name}.pth
Patch0:         piano-transcription-inference-librosa-0.10.patch
Patch1:         piano-transcription-inference-librosa-compat-2.patch
Patch2:         piano-transcription-inference-system-checkpoint.patch

%bcond_without tests

BuildArch:      noarch
%if %{with tests}
BuildRequires:  /usr/bin/ffmpeg
%endif
BuildRequires:  python3-devel
%if %{with tests}
BuildRequires:  python3dist(audioread)
%endif
BuildRequires:  pyproject-rpm-macros
%if %{with tests}
BuildRequires:  python3dist(resampy)
BuildRequires:  python3dist(torch)
%endif

%global _description %{expand:
Piano transcription inference package from the ByteDance piano transcription
system.}

%description %_description

%package -n python3-%{dist_name}
Summary:        %{summary}
Requires:       %{dist_name}-data = %{version}-%{release}
Requires:       /usr/bin/ffmpeg
Requires:       python3dist(audioread)
Requires:       python3dist(resampy)
Requires:       python3dist(torch)

%description -n python3-%{dist_name} %_description

%package -n %{dist_name}-data
Summary:        Model checkpoint data for piano transcription inference

%description -n %{dist_name}-data
Model checkpoint data used by piano-transcription-inference for local
inference without runtime network downloads.

%prep
%autosetup -n %{pypi_name}-%{version} -p1

%generate_buildrequires
%if %{with tests}
%pyproject_buildrequires -r
%else
%pyproject_buildrequires
%endif

%build
%pyproject_wheel

%install
%pyproject_install
%pyproject_save_files piano_transcription_inference

install -Dpm 0644 %{SOURCE1} \
  %{buildroot}%{_datadir}/%{dist_name}/%{checkpoint_name}

%if %{with tests}
%check
%pyproject_check_import
%endif

%files -n python3-%{dist_name} -f %{pyproject_files}
%doc README.md

%files -n %{dist_name}-data
%dir %{_datadir}/%{dist_name}
%{_datadir}/%{dist_name}/%{checkpoint_name}

%changelog
* Wed Sep 02 2026 Codex <codex@localhost> - 0.0.6-1
- Initial Fedora-style package with packaged checkpoint data.
