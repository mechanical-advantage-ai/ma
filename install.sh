#!/bin/sh
# Install script for ma CLI
# Usage: curl -fsSL https://raw.githubusercontent.com/mechanical-advantage-ai/ma/main/install.sh | sh
set -e

REPO="mechanical-advantage-ai/ma"
BINARY="ma"
INSTALL_DIR="/usr/local/bin"

detect_os() {
    os=$(uname -s | tr '[:upper:]' '[:lower:]')
    case "$os" in
        darwin)  echo "darwin" ;;
        linux)   echo "linux" ;;
        mingw*|msys*|cygwin*) echo "windows" ;;
        *)
            echo "Error: unsupported operating system: $os" >&2
            exit 1
            ;;
    esac
}

detect_arch() {
    arch=$(uname -m)
    case "$arch" in
        x86_64|amd64)    echo "amd64" ;;
        aarch64|arm64)   echo "arm64" ;;
        *)
            echo "Error: unsupported architecture: $arch" >&2
            exit 1
            ;;
    esac
}

get_latest_version() {
    curl -fsSL "https://api.github.com/repos/${REPO}/releases/latest" |
        grep '"tag_name"' |
        sed -E 's/.*"tag_name": *"([^"]+)".*/\1/'
}

main() {
    os=$(detect_os)
    arch=$(detect_arch)

    echo "Detected: ${os}/${arch}"

    # Get version (allow override via MA_VERSION env var)
    version="${MA_VERSION:-$(get_latest_version)}"
    version_num="${version#v}"

    echo "Installing ma ${version}..."

    # Determine archive extension
    ext="tar.gz"
    if [ "$os" = "windows" ]; then
        ext="zip"
    fi

    # Construct download URL
    filename="${BINARY}_${version_num}_${os}_${arch}.${ext}"
    url="https://github.com/${REPO}/releases/download/${version}/${filename}"

    # Create temp directory with cleanup trap
    tmp_dir=$(mktemp -d)
    trap 'rm -rf "$tmp_dir"' EXIT

    echo "Downloading ${url}..."
    curl -fsSL -o "${tmp_dir}/${filename}" "$url"

    # Extract
    if [ "$ext" = "zip" ]; then
        unzip -q "${tmp_dir}/${filename}" -d "${tmp_dir}"
    else
        tar -xzf "${tmp_dir}/${filename}" -C "${tmp_dir}"
    fi

    # Install binary
    if [ -w "$INSTALL_DIR" ]; then
        cp "${tmp_dir}/${BINARY}" "${INSTALL_DIR}/${BINARY}"
        chmod +x "${INSTALL_DIR}/${BINARY}"
    else
        echo "Requesting sudo to install to ${INSTALL_DIR}..."
        sudo cp "${tmp_dir}/${BINARY}" "${INSTALL_DIR}/${BINARY}"
        sudo chmod +x "${INSTALL_DIR}/${BINARY}"
    fi

    echo "ma ${version} installed successfully! Run 'ma --help' to get started."
}

main
