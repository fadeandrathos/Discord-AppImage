#!/bin/bash
set -e

APP="Discord"
ARCH="x86_64"
APPDIR="${APP}.AppDir"

WORKDIR=$(mktemp -d)
trap 'echo "--> Cleaning up temporary directory..."; rm -r "$WORKDIR"' EXIT
cd "$WORKDIR"

echo "✅ Downloading necessary files..."
wget -q "https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-x86_64.AppImage" -O appimagetool
chmod +x appimagetool

echo "Downloading Discord..."
wget -q "https://discord.com/api/download?platform=linux&format=deb" -O discord.deb

echo "📦 Extracting package..."
ar x discord.deb
tar xf data.tar.gz

echo "🏗️ Assembling the AppDir..."
mv ./usr/share/discord ./"$APPDIR"

echo "🎨 Setting up icons and desktop entry..."
sed -i 's|^Exec=.*|Exec=AppRun|' ./"$APPDIR"/discord.desktop

echo "🚀 Creating the AppRun entrypoint..."
cat <<'EOF' > ./"$APPDIR"/AppRun
#!/bin/sh
HERE="$(dirname "$(readlink -f "${0}")")"
exec "$HERE/Discord" "$@"
EOF
chmod +x ./"$APPDIR"/AppRun

echo "🔎 Determining application version..."
VERSION=$(dpkg-deb -f discord.deb Version)
APPIMAGE_NAME="$APP-$VERSION-$ARCH.AppImage"

echo "Building $APPIMAGE_NAME..."

ARCH=x86_64 ./appimagetool \
    --comp zstd \
    --mksquashfs-opt -Xcompression-level --mksquashfs-opt 20 \
    ./"$APPDIR" \
    "$APPIMAGE_NAME"

echo "🎉 Build complete!"
mv "$APPIMAGE_NAME" "$OLDPWD"
echo "AppImage created at: $(realpath "$OLDPWD/$APPIMAGE_NAME")"

echo "version=$VERSION" >> "$GITHUB_OUTPUT"
echo "appimage_name=$APPIMAGE_NAME" >> "$GITHUB_OUTPUT"