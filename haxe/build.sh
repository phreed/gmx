#!/bin/bash

# GMX Haxe/HashLink Build Script
# Cross-platform build automation for the GMX application port

set -e  # Exit on any error

# Configuration
PROJECT_NAME="GMX"
BUILD_DIR="bin"
ASSETS_DIR="assets"
DIST_DIR="dist"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if required tools are installed
check_dependencies() {
    print_status "Checking dependencies..."

    if ! command -v haxe &> /dev/null; then
        print_error "Haxe compiler not found. Please install Haxe 4.3.0 or higher."
        exit 1
    fi

    if ! command -v hl &> /dev/null; then
        print_error "HashLink not found. Please install HashLink 1.13 or higher."
        exit 1
    fi

    print_success "All dependencies found"
}

# Install Haxe libraries
install_libraries() {
    print_status "Installing Haxe libraries..."

    haxelib install heaps --quiet
    haxelib install hlsdl --quiet
    haxelib install format --quiet

    print_success "Libraries installed"
}

# Create build directories
setup_directories() {
    print_status "Setting up build directories..."

    mkdir -p "$BUILD_DIR"
    mkdir -p "$DIST_DIR"
    mkdir -p "$ASSETS_DIR"

    print_success "Directories created"
}

# Clean build artifacts
clean() {
    print_status "Cleaning build artifacts..."

    rm -rf "$BUILD_DIR"/*
    rm -rf "$DIST_DIR"/*

    print_success "Clean completed"
}

# Build development version
build_dev() {
    print_status "Building development version..."

    haxe build.hxml

    if [ $? -eq 0 ]; then
        print_success "Development build completed: $BUILD_DIR/gmx.hl"
    else
        print_error "Development build failed"
        exit 1
    fi
}

# Build release version
build_release() {
    print_status "Building release version..."

    haxe build-release.hxml

    if [ $? -eq 0 ]; then
        print_success "Release build completed: $BUILD_DIR/gmx.hl"
    else
        print_error "Release build failed"
        exit 1
    fi
}

# Copy assets to build directory
copy_assets() {
    if [ -d "$ASSETS_DIR" ] && [ "$(ls -A $ASSETS_DIR)" ]; then
        print_status "Copying assets..."
        cp -r "$ASSETS_DIR"/* "$BUILD_DIR/"
        print_success "Assets copied"
    else
        print_warning "No assets found to copy"
    fi
}

# Package for Windows
package_windows() {
    print_status "Packaging for Windows..."

    if [ ! -f "$BUILD_DIR/gmx.hl" ]; then
        print_error "Build file not found. Run build first."
        exit 1
    fi

    # Compile to native Windows executable
    hl --compile-hl "$BUILD_DIR/gmx.hl" "$DIST_DIR/gmx-windows.exe"

    if [ $? -eq 0 ]; then
        print_success "Windows package created: $DIST_DIR/gmx-windows.exe"
    else
        print_error "Windows packaging failed"
        exit 1
    fi
}

# Package for Linux
package_linux() {
    print_status "Packaging for Linux..."

    if [ ! -f "$BUILD_DIR/gmx.hl" ]; then
        print_error "Build file not found. Run build first."
        exit 1
    fi

    # Compile to native Linux executable
    hl --compile-hl "$BUILD_DIR/gmx.hl" "$DIST_DIR/gmx-linux"

    if [ $? -eq 0 ]; then
        chmod +x "$DIST_DIR/gmx-linux"
        print_success "Linux package created: $DIST_DIR/gmx-linux"
    else
        print_error "Linux packaging failed"
        exit 1
    fi
}

# Package for Linux as Flatpak
package_flatpak() {
    print_status "Packaging for Linux as Flatpak..."

    if [ ! -f "$BUILD_DIR/gmx.hl" ]; then
        print_error "Build file not found. Run build first."
        exit 1
    fi

    # First create the native Linux binary
    if [ ! -f "$DIST_DIR/gmx-linux" ]; then
        package_linux
    fi

    # Copy binary to bin directory for Flatpak build
    mkdir -p "bin"
    cp "$DIST_DIR/gmx-linux" "bin/"

    # Run Flatpak build script
    if [ -f "scripts/build-flatpak.sh" ]; then
        print_status "Building Flatpak package..."
        ./scripts/build-flatpak.sh all
        print_success "Flatpak package created successfully"
    else
        print_error "Flatpak build script not found"
        exit 1
    fi
}

# Package for macOS
package_macos() {
    print_status "Packaging for macOS..."

    if [ ! -f "$BUILD_DIR/gmx.hl" ]; then
        print_error "Build file not found. Run build first."
        exit 1
    fi

    # Create app bundle structure
    APP_BUNDLE="$DIST_DIR/$PROJECT_NAME.app"
    mkdir -p "$APP_BUNDLE/Contents/MacOS"
    mkdir -p "$APP_BUNDLE/Contents/Resources"

    # Compile to native macOS executable
    hl --compile-hl "$BUILD_DIR/gmx.hl" "$APP_BUNDLE/Contents/MacOS/$PROJECT_NAME"

    if [ $? -eq 0 ]; then
        chmod +x "$APP_BUNDLE/Contents/MacOS/$PROJECT_NAME"

        # Create Info.plist
        cat > "$APP_BUNDLE/Contents/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>$PROJECT_NAME</string>
    <key>CFBundleIdentifier</key>
    <string>com.gmx.application</string>
    <key>CFBundleName</key>
    <string>$PROJECT_NAME</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundleVersion</key>
    <string>1.0.0</string>
</dict>
</plist>
EOF

        print_success "macOS package created: $APP_BUNDLE"
    else
        print_error "macOS packaging failed"
        exit 1
    fi
}

# Package all platforms
package_all() {
    print_status "Packaging for all platforms..."

    case "$OSTYPE" in
        darwin*)
            package_macos
            ;;
        linux*)
            package_linux
            ;;
        msys*|cygwin*|win32)
            package_windows
            ;;
        *)
            print_warning "Unknown platform: $OSTYPE"
            print_status "Attempting to package for current platform..."
            hl --compile-hl "$BUILD_DIR/gmx.hl" "$DIST_DIR/gmx-native"
            ;;
    esac
}

# Run the application
run() {
    if [ ! -f "$BUILD_DIR/gmx.hl" ]; then
        print_error "Build file not found. Run build first."
        exit 1
    fi

    print_status "Running application..."
    hl "$BUILD_DIR/gmx.hl"
}

# Show help
show_help() {
    echo "GMX Build Script"
    echo ""
    echo "Usage: $0 [command]"
    echo ""
    echo "Commands:"
    echo "  setup          Install dependencies and setup directories"
    echo "  clean          Clean build artifacts"
    echo "  dev            Build development version"
    echo "  release        Build release version"
    echo "  run            Run the application"
    echo "  package        Package for current platform"
    echo "  package-win    Package for Windows"
    echo "  package-linux  Package for Linux"
    echo "  package-flatpak Package as Flatpak for Linux"
    echo "  package-mac    Package for macOS"
    echo "  package-all    Package for all platforms"
    echo "  help           Show this help"
    echo ""
    echo "Examples:"
    echo "  $0 setup      # First time setup"
    echo "  $0 dev        # Quick development build"
    echo "  $0 release    # Optimized release build"
    echo "  $0 run        # Build and run"
    echo "  $0 package-flatpak  # Create Flatpak package"
}

# Main script logic
case "${1:-help}" in
    setup)
        check_dependencies
        install_libraries
        setup_directories
        ;;
    clean)
        clean
        ;;
    dev)
        check_dependencies
        setup_directories
        build_dev
        copy_assets
        ;;
    release)
        check_dependencies
        setup_directories
        build_release
        copy_assets
        ;;
    run)
        check_dependencies
        setup_directories
        build_dev
        copy_assets
        run
        ;;
    package)
        package_all
        ;;
    package-win|package-windows)
        package_windows
        ;;
    package-linux)
        package_linux
        ;;
    package-flatpak)
        package_flatpak
        ;;
    package-mac|package-macos)
        package_macos
        ;;
    package-all)
        package_windows
        package_linux
        package_macos
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        print_error "Unknown command: $1"
        show_help
        exit 1
        ;;
esac

print_success "Script completed successfully"
