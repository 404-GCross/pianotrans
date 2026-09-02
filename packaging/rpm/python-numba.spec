%global pypi_name numba

Name:           python-%{pypi_name}
Version:        0.67.0
Release:        1%{?dist}
Summary:        Compiling Python code using LLVM

License:        BSD-2-Clause
URL:            https://numba.pydata.org/
Source0:        %{pypi_source %{pypi_name} %{version}}

%bcond_without tests

BuildRequires:  gcc
BuildRequires:  gcc-c++
BuildRequires:  pyproject-rpm-macros
BuildRequires:  python3-devel
BuildRequires:  python3dist(numpy) >= 2.0.0
BuildRequires:  python3dist(numpy) < 2.6
BuildRequires:  python3dist(packaging)
BuildRequires:  python3dist(setuptools)
BuildRequires:  python3dist(wheel)
BuildRequires:  python3dist(llvmlite) >= 0.49
BuildRequires:  python3dist(llvmlite) < 0.50

%global _description %{expand:
Numba is an LLVM-based compiler for Python code, especially NumPy-heavy
numeric functions.}

%description %_description

%package -n python3-%{pypi_name}
Summary:        %{summary}
Requires:       python3dist(llvmlite) >= 0.49
Requires:       python3dist(llvmlite) < 0.50
Requires:       python3dist(numpy) >= 1.22
Requires:       python3dist(numpy) < 2.6

%description -n python3-%{pypi_name} %_description

%prep
%autosetup -n %{pypi_name}-%{version}
cat > pyproject.toml <<'EOF'
[build-system]
requires = ["setuptools", "wheel"]
build-backend = "setuptools.build_meta"
EOF

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
NUMBA_CACHE_DIR=%{_tmppath}/numba-cache \
PYTHONPATH=%{buildroot}%{python3_sitearch} \
  %{python3} -c "import numba; print(numba.__version__)"
%endif

%files -n python3-%{pypi_name} -f %{pyproject_files}
%license LICENSE LICENSES.third-party
%doc README.rst
%{_bindir}/numba

%changelog
* Wed Sep 02 2026 Codex <codex@localhost> - 0.67.0-1
- Initial Fedora-style package for PianoTrans dependency closure.
