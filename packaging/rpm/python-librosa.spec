%global pypi_name librosa

Name:           python-%{pypi_name}
Version:        1.0.0
Release:        1%{?dist}
Summary:        Python module for audio and music processing

License:        ISC
URL:            https://librosa.org/
Source0:        %{pypi_source %{pypi_name} %{version}}

%bcond_without tests

BuildArch:      noarch
BuildRequires:  python3-devel
BuildRequires:  pyproject-rpm-macros

%global _description %{expand:
librosa is a Python package for music and audio analysis.}

%description %_description

%package -n python3-%{pypi_name}
Summary:        %{summary}

%description -n python3-%{pypi_name} %_description

%prep
%autosetup -n %{pypi_name}-%{version}

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
%pyproject_save_files %{pypi_name}

%if %{with tests}
%check
%pyproject_check_import
%endif

%files -n python3-%{pypi_name} -f %{pyproject_files}
%license LICENSE.md
%doc AUTHORS.md README.md

%changelog
* Wed Sep 02 2026 Codex <codex@localhost> - 1.0.0-1
- Initial Fedora-style package for PianoTrans dependency closure.
