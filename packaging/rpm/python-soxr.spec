%global pypi_name soxr
%global debug_package %{nil}

Name:           python-%{pypi_name}
Version:        1.1.0
Release:        1%{?dist}
Summary:        Python wrapper of libsoxr

License:        LGPL-2.1-or-later
URL:            https://github.com/dofuuz/python-soxr
Source0:        %{pypi_source %{pypi_name} %{version}}

%bcond_without tests

BuildRequires:  cmake
BuildRequires:  gcc-c++
BuildRequires:  pyproject-rpm-macros
BuildRequires:  python3-devel
BuildRequires:  python3dist(nanobind) >= 2
BuildRequires:  python3dist(numpy)
BuildRequires:  python3dist(scikit-build-core) >= 0.11
BuildRequires:  python3dist(setuptools)
BuildRequires:  python3dist(setuptools-scm[toml]) >= 6.2
BuildRequires:  soxr-devel

%global _description %{expand:
Python-SoXR provides NumPy bindings for high-quality sample-rate conversion
through the system libsoxr library.}

%description %_description

%package -n python3-%{pypi_name}
Summary:        %{summary}
Requires:       python3dist(numpy)

%description -n python3-%{pypi_name} %_description

%prep
%autosetup -n %{pypi_name}-%{version}

%generate_buildrequires
%if %{with tests}
%pyproject_buildrequires -r -C cmake.define.USE_SYSTEM_LIBSOXR=ON
%else
%pyproject_buildrequires -R -C cmake.define.USE_SYSTEM_LIBSOXR=ON
%endif

%build
%pyproject_wheel -C cmake.define.USE_SYSTEM_LIBSOXR=ON

%install
%pyproject_install
%pyproject_save_files %{pypi_name}

%if %{with tests}
%check
%pyproject_check_import
%endif

%files -n python3-%{pypi_name} -f %{pyproject_files}
%license LICENSE.txt COPYING.LGPL
%doc README.md

%changelog
* Wed Sep 02 2026 GCross <176783842+404-GCross@users.noreply.github.com> - 1.1.0-1
- Initial Fedora-style package using system libsoxr.
