%global pypi_name resampy

Name:           python-%{pypi_name}
Version:        0.4.3
Release:        1%{?dist}
Summary:        Efficient signal resampling

License:        ISC
URL:            https://github.com/bmcfee/resampy
Source0:        %{pypi_source %{pypi_name} %{version}}

%bcond_without tests

BuildArch:      noarch
BuildRequires:  python3-devel
BuildRequires:  pyproject-rpm-macros

%global _description %{expand:
Resampy implements efficient sample-rate conversion for Python signals.}

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
%doc README.md

%changelog
* Wed Sep 02 2026 Codex <codex@localhost> - 0.4.3-1
- Initial Fedora-style package for PianoTrans dependency closure.
