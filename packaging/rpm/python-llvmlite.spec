%global pypi_name llvmlite

Name:           python-%{pypi_name}
Version:        0.49.0
Release:        1%{?dist}
Summary:        Lightweight LLVM Python binding for Numba

License:        BSD-2-Clause
URL:            https://llvmlite.readthedocs.io/
Source0:        %{pypi_source %{pypi_name} %{version}}

%bcond_without tests

BuildRequires:  cmake
BuildRequires:  gcc-c++
BuildRequires:  llvm-devel >= 22
BuildRequires:  llvm-devel < 23
BuildRequires:  pyproject-rpm-macros
BuildRequires:  python3-devel
BuildRequires:  python3dist(packaging)
BuildRequires:  python3dist(setuptools)
BuildRequires:  python3dist(versioneer)
BuildRequires:  python3dist(wheel)

%global _description %{expand:
llvmlite is a project originally tailored for Numba's needs, using LLVM to
provide a Python binding to selected compiler APIs.}

%description %_description

%package -n python3-%{pypi_name}
Summary:        %{summary}
Requires:       llvm-libs%{?_isa} >= 22
Requires:       llvm-libs%{?_isa} < 23

%description -n python3-%{pypi_name} %_description

%prep
%autosetup -n %{pypi_name}-%{version}

%generate_buildrequires
%if %{with tests}
%pyproject_buildrequires -r
%else
%pyproject_buildrequires -R
%endif

%build
export LLVMLITE_SHARED=ON
export LLVMLITE_LTO=OFF
%pyproject_wheel

%install
export LLVMLITE_SHARED=ON
export LLVMLITE_LTO=OFF
%pyproject_install
%pyproject_save_files %{pypi_name}

%if %{with tests}
%check
PYTHONPATH=%{buildroot}%{python3_sitearch} \
  %{python3} -c "import llvmlite.binding as llvm; llvm.initialize(); print(llvm.llvm_version_info)"
%endif

%files -n python3-%{pypi_name} -f %{pyproject_files}
%license LICENSE LICENSE.thirdparty
%doc README.rst

%changelog
* Wed Sep 02 2026 GCross <176783842+404-GCross@users.noreply.github.com> - 0.49.0-1
- Initial Fedora-style package for PianoTrans dependency closure.
