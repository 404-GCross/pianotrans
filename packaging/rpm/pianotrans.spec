Name:           pianotrans
Version:        1.1
Release:        1%{?dist}
Summary:        Simple GUI for ByteDance's Piano Transcription with Pedals

License:        MIT
URL:            https://github.com/404-GCross/pianotrans
Source0:        https://github.com/404-GCross/pianotrans/archive/refs/tags/v%{version}/%{name}-%{version}.tar.gz

BuildArch:      noarch
BuildRequires:  python3-devel

Requires:       python3
Requires:       /usr/bin/ffmpeg
Requires:       python3-tkinter
Requires:       python3dist(torch)
Requires:       python3dist(piano-transcription-inference)
Requires:       python3dist(resampy)

%description
PianoTrans is a small command-line and Tkinter GUI wrapper for ByteDance's
piano transcription inference package.

%prep
%autosetup

%build
# Pure Python single-module app; no build step is required.

%install
mkdir -p %{buildroot}%{python3_sitelib}
install -pm 0644 PianoTrans.py %{buildroot}%{python3_sitelib}/PianoTrans.py

mkdir -p %{buildroot}%{_bindir}
cat > %{buildroot}%{_bindir}/pianotrans <<'EOF'
#!/usr/bin/sh
exec %{__python3} -m PianoTrans "$@"
EOF
chmod 0755 %{buildroot}%{_bindir}/pianotrans

%files
%doc README.md
%{_bindir}/pianotrans
%pycached %{python3_sitelib}/PianoTrans.py

%changelog
* Wed Sep 02 2026 Codex <codex@localhost> - 1.1-1
- Package the v1.1 GitHub release tag.

* Wed Sep 02 2026 Codex <codex@localhost> - 1.0.1-1
- Initial RPM packaging for PianoTrans.
