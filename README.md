# Cross-compile GnuPG for Windows using Docker

This Dockerfile downloads the GnuPG sources, including dependencies,
then cross-compiles using Mingw-w64 in Docker for Windows host. Most
features are disabled since I only use this for testing on Windows.

## Usage

    docker build -t gnupg-build .
    docker run --rm gnupg-build >gnupg.zip
