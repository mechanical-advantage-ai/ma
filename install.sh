#!/bin/sh
# Install script for ma CLI
# Usage: curl -fsSL https://raw.githubusercontent.com/mechanical-advantage-ai/ma/main/install.sh | sh
set -e

REPO="mechanical-advantage-ai/ma"
BINARY="ma"
INSTALL_DIR="$HOME/.ma/bin"

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

add_to_path() {
    path_entry='export PATH="$HOME/.ma/bin:$PATH"'

    # Detect shell and rc file
    case "$(basename "$SHELL")" in
        zsh)  rc_file="$HOME/.zshrc" ;;
        bash)
            if [ -f "$HOME/.bashrc" ]; then
                rc_file="$HOME/.bashrc"
            else
                rc_file="$HOME/.bash_profile"
            fi
            ;;
        fish)
            # Fish uses a different syntax
            fish_path_cmd="fish_add_path $HOME/.ma/bin"
            fish_config="$HOME/.config/fish/config.fish"
            if [ -f "$fish_config" ] && grep -qF ".ma/bin" "$fish_config" 2>/dev/null; then
                return
            fi
            mkdir -p "$(dirname "$fish_config")"
            echo "$fish_path_cmd" >> "$fish_config"
            echo "Added $INSTALL_DIR to PATH in $fish_config"
            return
            ;;
        *)    rc_file="$HOME/.profile" ;;
    esac

    # Check if already in the rc file
    if [ -f "$rc_file" ] && grep -qF ".ma/bin" "$rc_file" 2>/dev/null; then
        return
    fi

    echo "" >> "$rc_file"
    echo "# Added by ma CLI installer" >> "$rc_file"
    echo "$path_entry" >> "$rc_file"
    echo "Added $INSTALL_DIR to PATH in $rc_file"
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
    mkdir -p "$INSTALL_DIR"
    cp "${tmp_dir}/${BINARY}" "${INSTALL_DIR}/${BINARY}"
    chmod +x "${INSTALL_DIR}/${BINARY}"

    # Add to PATH if needed
    case ":$PATH:" in
        *":$INSTALL_DIR:"*) ;;
        *) add_to_path ;;
    esac

    echo ""
    echo "ma ${version} installed successfully to ${INSTALL_DIR}/${BINARY}"
    echo ""
    if ! command -v ma >/dev/null 2>&1; then
        echo "Restart your shell or run:"
        echo "  export PATH=\"\$HOME/.ma/bin:\$PATH\""
        echo ""
    fi
    echo "Run 'ma --help' to get started."
}

main
