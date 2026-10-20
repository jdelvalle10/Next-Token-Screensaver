#!/usr/bin/env bash
# Next Token display — installer for Ubuntu (GNOME, X11 or Wayland) with Firefox.
# Installs for the CURRENT user only; no sudo needed.
# Usage:  bash install.sh            (adds a launcher icon to the app grid, dock and desktop)
#         bash install.sh --no-dock  (skip adding it to the dock)
set -euo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ADD_DOCK=1
[[ "${1:-}" == "--no-dock" ]] && ADD_DOCK=0

command -v firefox >/dev/null 2>&1 || { echo "Firefox not found. Install it first."; exit 1; }

# Ubuntu ships Firefox as a snap; a snap can only read hidden folders inside its own area,
# so the files go where Firefox is allowed to open them.
if snap list firefox >/dev/null 2>&1; then
  BASE="$HOME/snap/firefox/common/next-token"
  echo "Firefox: snap package"
else
  BASE="$HOME/.local/share/next-token"
  echo "Firefox: regular package"
fi

mkdir -p "$BASE/profile"
install -m 644 "$SRC/next-token.html" "$BASE/next-token.html"
install -m 644 "$SRC/icon.svg" "$BASE/icon.svg"

# Dedicated, quiet Firefox profile (does not touch your normal Firefox profile).
cat > "$BASE/profile/user.js" <<'EOF'
user_pref("dom.allow_scripts_to_close_windows", true);
user_pref("browser.shell.checkDefaultBrowser", false);
user_pref("browser.aboutwelcome.enabled", false);
user_pref("browser.startup.homepage_override.mstone", "ignore");
user_pref("startup.homepage_welcome_url", "");
user_pref("startup.homepage_welcome_url.additional", "");
user_pref("datareporting.policy.dataSubmissionPolicyBypassNotification", true);
user_pref("datareporting.policy.firstRunURL", "");
user_pref("datareporting.healthreport.uploadEnabled", false);
user_pref("toolkit.telemetry.enabled", false);
user_pref("app.normandy.enabled", false);
user_pref("browser.sessionstore.resume_from_crash", false);
user_pref("browser.tabs.warnOnClose", false);
user_pref("browser.translations.automaticallyPopup", false);
user_pref("full-screen-api.warning.timeout", 0);
EOF

# Launcher script
cat > "$BASE/launch.sh" <<EOF
#!/usr/bin/env bash
# Starts the Next Token display full screen. Touch the board or press any key to exit.
BASE="$BASE"
URL="file://\$BASE/next-token.html?kiosk=1"
# Keep the screen from blanking while it plays.
if command -v gnome-session-inhibit >/dev/null 2>&1; then
  exec gnome-session-inhibit --inhibit idle --reason "Next Token display" \\
    firefox --no-remote --profile "\$BASE/profile" --kiosk "\$URL"
else
  exec firefox --no-remote --profile "\$BASE/profile" --kiosk "\$URL"
fi
EOF
chmod 755 "$BASE/launch.sh"

# App-grid entry
APPS="$HOME/.local/share/applications"
mkdir -p "$APPS"
cat > "$APPS/next-token.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=Next Token
Comment=How a language model writes, one token at a time (classroom display)
Exec="$BASE/launch.sh"
Icon=$BASE/icon.svg
Terminal=false
Categories=Education;Science;
StartupNotify=false
EOF
chmod 644 "$APPS/next-token.desktop"
command -v update-desktop-database >/dev/null 2>&1 && update-desktop-database "$APPS" >/dev/null 2>&1 || true

# Desktop icon (Ubuntu needs it marked trusted to launch on double-tap)
DESK="$(xdg-user-dir DESKTOP 2>/dev/null || echo "$HOME/Desktop")"
if [[ -d "$DESK" ]]; then
  install -m 755 "$APPS/next-token.desktop" "$DESK/next-token.desktop"
  gio set "$DESK/next-token.desktop" metadata::trusted true 2>/dev/null || true
fi

# Dock favorite
if [[ $ADD_DOCK -eq 1 ]] && command -v gsettings >/dev/null 2>&1; then
  CUR="$(gsettings get org.gnome.shell favorite-apps 2>/dev/null || echo "")"
  if [[ -n "$CUR" && "$CUR" != *"next-token.desktop"* ]]; then
    NEW="$(python3 -c 'import ast,sys; l=ast.literal_eval(sys.argv[1].replace("@as ","")); l.append("next-token.desktop"); print(str(l))' "$CUR")"
    gsettings set org.gnome.shell favorite-apps "$NEW" || true
  fi
fi

echo
echo "Installed to: $BASE"
echo "Start it from the dock, the app grid (search 'Next Token'), or the desktop icon."
echo "Touch the board or press any key to exit."
