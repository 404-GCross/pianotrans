%global pypi_name mido

Name:           python-%{pypi_name}
Version:        1.3.3
Release:        1%{?dist}
Summary:        MIDI Objects for Python

License:        MIT
URL:            https://github.com/mido/mido
Source0:        %{pypi_source %{pypi_name} %{version}}

%bcond_without tests

BuildArch:      noarch
BuildRequires:  python3-devel
BuildRequires:  pyproject-rpm-macros

%global _description %{expand:
Mido is a Python library for working with MIDI messages and files.}

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
%license LICENSE
%doc README.rst
%{_bindir}/mido-connect
%{_bindir}/mido-play
%{_bindir}/mido-ports
%{_bindir}/mido-serve

%changelog
* Wed Sep 02 2026 Codex <codex@localhost> - 1.3.3-1
- Initial Fedora-style package for PianoTrans dependency closure.
