#!/bin/bash
set -euo pipefail

mode=sandbox
case "${1:-}" in
  "") ;;
  --autofill) mode=autofill ;;
  --help)
    printf 'Usage: ./build.sh [--autofill]\n\nDefault: sandbox-only, ad-hoc signed app.\n--autofill: also claim the restricted AutoFill entitlement on host and extension.\nmacOS can reject that ad-hoc build before it starts. No OS settings are changed.\n'
    exit 0
    ;;
  *) printf 'Unknown option: %s\n' "$1" >&2; exit 1 ;;
esac
if [[ $# -gt 1 ]]; then
  printf 'Expected at most one option.\n' >&2
  exit 1
fi
if [[ "$(uname -s)" != Darwin ]]; then
  printf 'AutoFill Sprout requires macOS.\n' >&2
  exit 1
fi

root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
sdk="$(xcrun --sdk macosx --show-sdk-path)"
target="$(uname -m)-apple-macos15.0"
app="$root/build/AutoFill Sprout.app"
mkdir -p "$root/build"
staging="$(mktemp -d "$root/build/.sprout.XXXXXX")"
trap 'rm -rf "$staging"' EXIT
bundle="$staging/AutoFill Sprout.app"
extension="$bundle/Contents/PlugIns/ProbeExtension.appex"
mkdir -p "$bundle/Contents/MacOS" "$extension/Contents/MacOS"

cat > "$bundle/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>CFBundleDisplayName</key><string>AutoFill Sprout</string>
  <key>CFBundleName</key><string>AutoFill Sprout</string>
  <key>CFBundleExecutable</key><string>sprout</string>
  <key>CFBundleIdentifier</key><string>com.jasonlovesdoggo.autofill-sprout</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>1.0</string>
  <key>CFBundleVersion</key><string>1</string>
  <key>LSMinimumSystemVersion</key><string>15.0</string>
</dict></plist>
PLIST
cat > "$extension/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>CFBundleDisplayName</key><string>AutoFill Sprout Provider</string>
  <key>CFBundleName</key><string>AutoFill Sprout Provider</string>
  <key>CFBundleExecutable</key><string>extension</string>
  <key>CFBundleIdentifier</key><string>com.jasonlovesdoggo.autofill-sprout.extension</string>
  <key>CFBundlePackageType</key><string>XPC!</string>
  <key>CFBundleShortVersionString</key><string>1.0</string>
  <key>CFBundleVersion</key><string>1</string>
  <key>LSMinimumSystemVersion</key><string>15.0</string>
  <key>NSExtension</key><dict>
    <key>NSExtensionPointIdentifier</key><string>com.apple.authentication-services-credential-provider-ui</string>
    <key>NSExtensionPrincipalClass</key><string>ProbeExtension.ProbeCredentialProvider</string>
    <key>NSExtensionAttributes</key><dict>
      <key>ASCredentialProviderExtensionShowsConfigurationUI</key><true/>
      <key>ASCredentialProviderExtensionCapabilities</key><dict>
        <key>ProvidesPasswords</key><true/>
      </dict>
    </dict>
  </dict>
</dict></plist>
PLIST

entitlements="$staging/entitlements.plist"
cat > "$entitlements" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>com.apple.security.app-sandbox</key><true/>
</dict></plist>
PLIST
if [[ "$mode" == autofill ]]; then
  /usr/libexec/PlistBuddy -c 'Add :com.apple.developer.authentication-services.autofill-credential-provider bool true' "$entitlements"
fi

xcrun swiftc -sdk "$sdk" -target "$target" \
  -framework AppKit -framework AuthenticationServices \
  "$root/Sources/ProbeHost.swift" -o "$bundle/Contents/MacOS/sprout"
xcrun swiftc -sdk "$sdk" -target "$target" \
  -framework AppKit -framework AuthenticationServices \
  -application-extension -module-name ProbeExtension \
  -Xlinker -e -Xlinker _NSExtensionMain \
  "$root/Sources/ProbeExtension.swift" -o "$extension/Contents/MacOS/extension"

codesign --force --sign - --entitlements "$entitlements" "$extension"
codesign --force --sign - --entitlements "$entitlements" "$bundle"
codesign --verify --deep --strict "$bundle"
rm -rf "$app"
mv "$bundle" "$app"
printf 'Built: %s\nMode: %s (ad-hoc signed)\n' "$app" "$mode"
if [[ "$mode" == autofill ]]; then
  printf 'This claims a restricted entitlement without an Apple-authorized profile.\nmacOS may kill it before startup, despite codesign verification passing.\n'
fi
