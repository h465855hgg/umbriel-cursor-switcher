%global debug_package %{nil}

Name:           cursor-switcher
Version:        0.1.0
Release:        1%{?dist}
Summary:        PRTS cursor theme and shader effect switcher for Umbriel
License:        MIT
URL:            https://github.com/h465855hgg/cursor-switcher
BuildArch:      %{?buildarch}
Requires:       gtk3
Requires:       python3
Requires:       hicolor-icon-theme

%description
A small GUI to switch the Xcursor theme, cursor size and Umbriel cursor
shader effects. Built with HuxerUI. Ships a tray icon and applies changes
immediately by writing ~/.config/umbriel/config.toml and reloading Umbriel.

%install
install -d %{buildroot}/opt/cursor-switcher
cp -a %{stage}/opt/cursor-switcher/. %{buildroot}/opt/cursor-switcher/
install -d %{buildroot}%{_bindir}
ln -s ../opt/cursor-switcher/cursor-switcher %{buildroot}%{_bindir}/cursor-switcher
install -d %{buildroot}%{_datadir}/applications
install -m644 %{stage}/usr/share/applications/cursor-switcher.desktop %{buildroot}%{_datadir}/applications/
install -d %{buildroot}%{_datadir}/icons/hicolor/256x256/apps
install -m644 %{stage}/usr/share/icons/hicolor/256x256/apps/cursor-switcher.png %{buildroot}%{_datadir}/icons/hicolor/256x256/apps/
install -d %{buildroot}%{_datadir}/metainfo
install -m644 %{stage}/usr/share/metainfo/cursor-switcher.metainfo.xml %{buildroot}%{_datadir}/metainfo/

%post
update-desktop-database -q %{_datadir}/applications >/dev/null 2>&1 || :
gtk-update-icon-cache -q -t -f %{_datadir}/icons/hicolor >/dev/null 2>&1 || :

%postun
update-desktop-database -q %{_datadir}/applications >/dev/null 2>&1 || :
gtk-update-icon-cache -q -t -f %{_datadir}/icons/hicolor >/dev/null 2>&1 || :

%files
/opt/cursor-switcher
%{_bindir}/cursor-switcher
%{_datadir}/applications/cursor-switcher.desktop
%{_datadir}/icons/hicolor/256x256/apps/cursor-switcher.png
%{_datadir}/metainfo/cursor-switcher.metainfo.xml

%changelog
* Tue Nov 24 2026 h465855hgg <h465855hgg@users.noreply.github.com> - 1.0.0-1
- Initial package
