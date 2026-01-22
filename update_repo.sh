#!/bin/bash
set -e

# Configuration
REPO_ROOT=$(pwd)
DIST_DIR="$REPO_ROOT/dists/stable"
COMP_DIR="$DIST_DIR/main/binary-amd64"

# Ensure directories exist
mkdir -p "$COMP_DIR"

echo "Generating Packages..."
# Generate Packages file using apt-ftparchive or dpkg-scanpackages
# We use apt-ftparchive if available, or fallback to simple scan
if command -v apt-ftparchive >/dev/null; then
    apt-ftparchive packages ./pool > "$COMP_DIR/Packages"
else
    # Fallback to dpkg-scanpackages which is part of dpkg-dev
    dpkg-scanpackages --multiversion ./pool > "$COMP_DIR/Packages"
fi

gzip -k -f "$COMP_DIR/Packages"

echo "Generating Release..."
# Create Release file
cat > "$DIST_DIR/Release" <<EOF
Origin: fs-analyzer
Label: fs-analyzer
Suite: stable
Codename: stable
Components: main
Architectures: amd64
Date: $(date -R)
EOF

# Calculate hashes for the Packages files relative to dists/stable
# This is a simplified Release generation
cd "$DIST_DIR"
{
  echo "MD5Sum:"
  md5sum "main/binary-amd64/Packages" | awk '{print " " $1 " " $2}'
  md5sum "main/binary-amd64/Packages.gz" | awk '{print " " $1 " " $2}'
  echo "SHA1:"
  sha1sum "main/binary-amd64/Packages" | awk '{print " " $1 " " $2}'
  sha1sum "main/binary-amd64/Packages.gz" | awk '{print " " $1 " " $2}'
  echo "SHA256:"
  sha256sum "main/binary-amd64/Packages" | awk '{print " " $1 " " $2}'
  sha256sum "main/binary-amd64/Packages.gz" | awk '{print " " $1 " " $2}'
} >> "$DIST_DIR/Release"

# Sign Release
echo "Signing Release..."
# Remove old signatures
rm -f Release.gpg InRelease

# Sign
gpg --default-key "olowoyobabajide@gmail.com" -abs -o Release.gpg Release
gpg --default-key "olowoyobabajide@gmail.com" --clearsign -o InRelease Release

echo "Done."
