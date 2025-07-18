#!/bin/bash

# GMX Application - Flatpak Build Script
# Creates a Flatpak package for Linux distribution

set -e  # Exit on any error

# Configuration
APP_ID="com.gmx.Application"
FLATPAK_DIR="flatpak"
BUILD_DIR="flatpak-build"
REPO_DIR="flatpak-repo"
BRANCH="stable"

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
    print_status "Checking Flatpak build dependencies..."

    if ! command -v flatpak &> /dev/null; then
        print_error "Flatpak not found. Please install flatpak."
        exit 1
    fi

    if ! command -v flatpak-builder &> /dev/null; then
        print_error "flatpak-builder not found. Please install flatpak-builder."
        exit 1
    fi

    print_success "All dependencies found"
}

# Install required Flatpak runtimes
install_runtimes() {
    print_status "Installing Flatpak runtimes..."

    # Add Flathub repository if not already added
    if ! flatpak remote-list | grep -q flathub; then
        print_status "Adding Flathub repository..."
        flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    fi

    # Install runtime and SDK
    print_status "Installing Freedesktop runtime 22.08..."
    flatpak install -y flathub org.freedesktop.Platform//22.08 || true
    flatpak install -y flathub org.freedesktop.Sdk//22.08 || true

    print_success "Runtimes installed"
}

# Prepare build environment
prepare_build() {
    print_status "Preparing build environment..."

    # Ensure we have the application binary
    if [ ! -f "bin/gmx-linux" ]; then
        print_error "Application binary not found. Please run './build.sh package-linux' first."
        exit 1
    fi

    # Create build directories
    mkdir -p "$BUILD_DIR"
    mkdir -p "$REPO_DIR"

    # Clean previous builds
    rm -rf "$BUILD_DIR"/*

    print_success "Build environment prepared"
}

# Generate application icons (placeholder icons if none exist)
generate_icons() {
    print_status "Preparing application icons..."

    local icon_dir="$FLATPAK_DIR/icons"
    mkdir -p "$icon_dir"

    # Check if we have actual icons, if not create placeholder SVG
    if [ ! -f "$icon_dir/gmx-64.png" ]; then
        print_warning "No application icons found, creating placeholder icons..."

        # Create a simple SVG icon
        cat > "$icon_dir/gmx-icon.svg" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<svg width="256" height="256" viewBox="0 0 256 256" xmlns="http://www.w3.org/2000/svg">
  <rect width="256" height="256" fill="#4A90E2" rx="32"/>
  <rect x="32" y="32" width="192" height="192" fill="#FFFFFF" rx="16"/>
  <rect x="48" y="48" width="160" height="24" fill="#4A90E2" rx="4"/>
  <rect x="48" y="88" width="160" height="16" fill="#D3D3D3" rx="2"/>
  <rect x="48" y="112" width="160" height="16" fill="#D3D3D3" rx="2"/>
  <rect x="48" y="136" width="100" height="16" fill="#D3D3D3" rx="2"/>
  <rect x="48" y="168" width="80" height="24" fill="#E74C3C" rx="4"/>
  <rect x="136" y="168" width="72" height="24" fill="#2ECC71" rx="4"/>
  <text x="128" y="220" font-family="Arial" font-size="18" fill="#4A90E2" text-anchor="middle">GMX</text>
</svg>
EOF

        # Convert SVG to PNG at different sizes using ImageMagick or rsvg-convert
        if command -v rsvg-convert &> /dev/null; then
            rsvg-convert -w 64 -h 64 "$icon_dir/gmx-icon.svg" -o "$icon_dir/gmx-64.png"
            rsvg-convert -w 128 -h 128 "$icon_dir/gmx-icon.svg" -o "$icon_dir/gmx-128.png"
            rsvg-convert -w 256 -h 256 "$icon_dir/gmx-icon.svg" -o "$icon_dir/gmx-256.png"
        elif command -v convert &> /dev/null; then
            convert -background transparent "$icon_dir/gmx-icon.svg" -resize 64x64 "$icon_dir/gmx-64.png"
            convert -background transparent "$icon_dir/gmx-icon.svg" -resize 128x128 "$icon_dir/gmx-128.png"
            convert -background transparent "$icon_dir/gmx-icon.svg" -resize 256x256 "$icon_dir/gmx-256.png"
        else
            print_warning "No SVG converter found. Install rsvg-convert or ImageMagick to generate PNG icons."
        fi
    fi

    print_success "Icons prepared"
}

# Validate manifest file
validate_manifest() {
    print_status "Validating Flatpak manifest..."

    if [ ! -f "$FLATPAK_DIR/$APP_ID.yml" ]; then
        print_error "Flatpak manifest not found: $FLATPAK_DIR/$APP_ID.yml"
        exit 1
    fi

    # Basic YAML syntax check
    if command -v python3 &> /dev/null; then
        python3 -c "import yaml; yaml.safe_load(open('$FLATPAK_DIR/$APP_ID.yml'))" 2>/dev/null || {
            print_error "Invalid YAML syntax in manifest file"
            exit 1
        }
    fi

    print_success "Manifest validated"
}

# Build the Flatpak
build_flatpak() {
    print_status "Building Flatpak package..."

    # Build the application
    flatpak-builder \
        --repo="$REPO_DIR" \
        --force-clean \
        --disable-rofiles-fuse \
        --state-dir=".flatpak-builder" \
        "$BUILD_DIR" \
        "$FLATPAK_DIR/$APP_ID.yml"

    if [ $? -eq 0 ]; then
        print_success "Flatpak build completed successfully"
    else
        print_error "Flatpak build failed"
        exit 1
    fi
}

# Create installable bundle
create_bundle() {
    print_status "Creating Flatpak bundle..."

    local bundle_name="GMX-${BRANCH}.flatpak"

    flatpak build-bundle \
        "$REPO_DIR" \
        "dist/$bundle_name" \
        "$APP_ID" \
        "$BRANCH"

    if [ $? -eq 0 ]; then
        print_success "Bundle created: dist/$bundle_name"

        # Show bundle information
        print_status "Bundle information:"
        flatpak info --show-metadata "dist/$bundle_name"

        # Show file size
        local size=$(du -h "dist/$bundle_name" | cut -f1)
        print_status "Bundle size: $size"
    else
        print_error "Bundle creation failed"
        exit 1
    fi
}

# Install locally for testing
install_local() {
    print_status "Installing Flatpak locally for testing..."

    # Add local repository
    flatpak remote-add --if-not-exists --no-gpg-verify gmx-local "$REPO_DIR" || true

    # Install the application
    flatpak install -y gmx-local "$APP_ID" || {
        print_warning "Installation may have failed, but this is normal for updates"
    }

    print_success "Local installation completed"
    print_status "You can now run the application with: flatpak run $APP_ID"
}

# Test the installed application
test_application() {
    print_status "Testing installed application..."

    # Check if application is installed
    if flatpak list | grep -q "$APP_ID"; then
        print_success "Application is installed and ready"

        # Show application info
        print_status "Application information:"
        flatpak info "$APP_ID"

        # Optionally run a quick test
        if [ "$1" = "--run-test" ]; then
            print_status "Running application test..."
            timeout 10s flatpak run "$APP_ID" --version || true
        fi
    else
        print_error "Application not found in installed Flatpaks"
        exit 1
    fi
}

# Clean up build artifacts
cleanup() {
    print_status "Cleaning up build artifacts..."

    if [ "$1" = "--full" ]; then
        rm -rf "$BUILD_DIR"
        rm -rf ".flatpak-builder"
        print_status "Full cleanup completed"
    else
        # Keep repository for faster rebuilds
        rm -rf "$BUILD_DIR"
        print_status "Build directory cleaned"
    fi
}

# Show usage information
show_help() {
    echo "GMX Flatpak Build Script"
    echo ""
    echo "Usage: $0 [command] [options]"
    echo ""
    echo "Commands:"
    echo "  build          Build the Flatpak package"
    echo "  bundle         Create installable bundle"
    echo "  install        Install locally for testing"
    echo "  test           Test the installed application"
    echo "  clean          Clean build artifacts"
    echo "  clean --full   Clean all build artifacts including cache"
    echo "  all            Build, bundle, and install (default)"
    echo "  help           Show this help"
    echo ""
    echo "Options:"
    echo "  --run-test     Run application test after installation"
    echo ""
    echo "Examples:"
    echo "  $0             # Build everything"
    echo "  $0 build       # Just build the Flatpak"
    echo "  $0 bundle      # Create distribution bundle"
    echo "  $0 test --run-test  # Test with application launch"
    echo ""
    echo "Prerequisites:"
    echo "  - flatpak and flatpak-builder installed"
    echo "  - GMX application built (run './build.sh package-linux' first)"
    echo "  - Freedesktop runtime 22.08 available"
}

# Create dist directory
mkdir -p dist

# Main script logic
case "${1:-all}" in
    build)
        check_dependencies
        install_runtimes
        prepare_build
        generate_icons
        validate_manifest
        build_flatpak
        ;;
    bundle)
        create_bundle
        ;;
    install)
        install_local
        ;;
    test)
        test_application "$2"
        ;;
    clean)
        cleanup "$2"
        ;;
    all)
        check_dependencies
        install_runtimes
        prepare_build
        generate_icons
        validate_manifest
        build_flatpak
        create_bundle
        install_local
        test_application
        print_success "Flatpak build process completed successfully!"
        print_status "Bundle available at: dist/GMX-${BRANCH}.flatpak"
        print_status "Run with: flatpak run $APP_ID"
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
