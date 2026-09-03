%global pypi_name torchlibrosa

Name:           python-%{pypi_name}
Version:        0.1.0
Release:        1%{?dist}
Summary:        PyTorch implementation of selected librosa functions

License:        MIT
URL:            https://github.com/qiuqiangkong/torchlibrosa
Source0:        %{pypi_source %{pypi_name} %{version}}

%bcond_without tests

BuildArch:      noarch
BuildRequires:  python3-devel
BuildRequires:  pyproject-rpm-macros

%global _description %{expand:
torchlibrosa implements selected librosa signal processing functions using
PyTorch tensors.}

%description %_description

%package -n python3-%{pypi_name}
Summary:        %{summary}
Requires:       python3dist(torch)

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
* Wed Sep 02 2026 Codex <codex@localhost> - 0.1.0-1
- Initial Fedora-style package for PianoTrans dependency closure.
