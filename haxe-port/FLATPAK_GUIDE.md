# GMX Application - Flatpak Guide

## Overview

This guide covers building, installing, and using the GMX application as a Flatpak package on Linux systems. Flatpak provides sandboxed execution, automatic dependency management, and cross-distribution compatibility.

## What is Flatpak?

Flatpak is a universal package format for Linux that provides:
- **Sandboxed Applications**: Enhanced security through isolation
- **Cross-Distribution**: Works on any Linux distribution
- **Dependency Management**: Bundled runtimes eliminate dependency conflicts
- **Desktop Integration**: Proper theming and system integration
- **Easy Updates**: Built-in update mechanisms

## Prerequisites

### Installing Flatpak

#### Ubuntu/Debian
```bash
sudo apt update
sudo apt install flatpak flatpak-builder
```

#### Fedora
```bash
sudo dnf install flatpak flatpak-builder
```

#### Arch Linux
```bash
sudo pacman -S flatpak flatpak-builder
```

#### openSUSE
```bash
sudo zypper install flatpak flatpak-builder
```

#### Add Flathub Repository
```bash
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
```

### Development Dependencies
For building from source:
```bash
# Install SVG converter for icon generation
sudo apt install librsvg2-bin  # Ubuntu/Debian
sudo dnf install librsvg2-tools  # Fedora
sudo pacman -S librsvg  # Arch Linux
```

## Building the Flatpak

### Quick Build
```bash
# Navigate to project directory
cd gmx/haxe-port

# Build the native Linux binary first
./build.sh package-linux

# Build Flatpak package
./build.sh package-flatpak
```

### Manual Build Process
```bash
# Step 1: Build application
./build.sh release

# Step 2: Create Linux binary
./build.sh package-linux

# Step 3: Build Flatpak
./scripts/build-flatpak.sh all
```

### Build Output
After successful build:
- **Bundle**: `dist/GMX-stable.flatpak` (installable package)
- **Repository**: `flatpak-repo/` (local repository)
- **Build artifacts**: `flatpak-build/` (temporary files)

## Installing the Flatpak

### From Bundle File
```bash
# Install the generated bundle
flatpak install --user dist/GMX-stable.flatpak

# Or system-wide (requires sudo)
sudo flatpak install dist/GMX-stable.flatpak
```

### From Local Repository
```bash
# Add local repository
flatpak remote-add --no-gpg-verify --if-not-exists gmx-local flatpak-repo

# Install from repository
flatpak install gmx-local com.gmx.Application
```

### Verification
```bash
# Check if installed
flatpak list | grep gmx

# Show application info
flatpak info com.gmx.Application
```

## Running the Application

### Command Line
```bash
# Run the application
flatpak run com.gmx.Application

# Run with specific file
flatpak run com.gmx.Application /path/to/file.xml

# Run with debug output
flatpak run --env=GMX_DEBUG=1 com.gmx.Application
```

### Desktop Integration
After installation, GMX will appear in your application menu under:
- **Categories**: Development, Office, Database
- **Name**: GMX Application
- **Description**: Form Builder

### Desktop Actions
Right-click on the application icon for quick actions:
- **New Form**: Create a new form
- **Open Recent**: Open recently used files

## Configuration and Data

### File System Access
The GMX Flatpak has access to:
- **Home Directory**: Read/write access to user files
- **Documents**: XDG Documents folder
- **Downloads**: XDG Downloads folder

### Data Locations
```bash
# Application data
~/.local/share/gmx/

# Configuration files
~/.config/gmx/

# Cache files
~/.cache/gmx/
```

### Network Access
GMX has network permissions for:
- Control channel communication
- Remote server connections
- File downloads/uploads

## Updating the Application

### Manual Update
```bash
# Reinstall with new bundle
flatpak install --user dist/GMX-stable.flatpak

# Or update from repository
flatpak update com.gmx.Application
```

### Automatic Updates
If distributed through Flathub or other repositories:
```bash
# Update all Flatpaks
flatpak update

# Update specific application
flatpak update com.gmx.Application
```

## Troubleshooting

### Common Issues

#### Installation Problems
```bash
# Error: Runtime not found
flatpak install org.freedesktop.Platform//22.08
flatpak install org.freedesktop.Sdk//22.08

# Error: Bundle signature verification failed
flatpak install --user --no-verify dist/GMX-stable.flatpak
```

#### Runtime Issues
```bash
# Check available runtimes
flatpak list --runtime

# Install required runtime
flatpak install flathub org.freedesktop.Platform//22.08
```

#### Permission Issues
```bash
# Grant additional file system access
flatpak override --user --filesystem=/path/to/directory com.gmx.Application

# Grant network access (if restricted)
flatpak override --user --share=network com.gmx.Application

# Reset permissions
flatpak override --user --reset com.gmx.Application
```

#### Graphics Issues
```bash
# Force software rendering
flatpak run --env=HEAPS_DRIVER=software com.gmx.Application

# Check graphics capabilities
flatpak run --command=glxinfo com.gmx.Application
```

### Debug Mode
```bash
# Run with debug output
flatpak run --env=GMX_DEBUG=1 --env=G_MESSAGES_DEBUG=all com.gmx.Application

# Run with shell access for debugging
flatpak run --command=bash --devel com.gmx.Application
```

### Log Files
```bash
# System logs
journalctl --user -f | grep gmx

# Application logs
~/.local/share/gmx/logs/

# Flatpak logs
~/.var/app/com.gmx.Application/
```

## Advanced Usage

### Custom Permissions
```bash
# Grant access to specific directories
flatpak override --user --filesystem=/media com.gmx.Application
flatpak override --user --filesystem=/mnt com.gmx.Application

# Remove network access (offline mode)
flatpak override --user --unshare=network com.gmx.Application

# Allow device access
flatpak override --user --device=all com.gmx.Application
```

### Environment Variables
```bash
# Set custom data directory
flatpak run --env=GMX_DATA_DIR=/custom/path com.gmx.Application

# Set configuration directory
flatpak run --env=GMX_CONFIG_DIR=/custom/config com.gmx.Application

# Enable verbose logging
flatpak run --env=GMX_VERBOSE=1 com.gmx.Application
```

### Integration with IDEs
```bash
# Launch from VS Code
flatpak run com.gmx.Application "$(pwd)/form.xml"

# Integration with file managers
# Add to ~/.local/share/applications/ for custom launchers
```

## Development and Testing

### Local Development
```bash
# Build and test locally
./scripts/build-flatpak.sh build
./scripts/build-flatpak.sh install
./scripts/build-flatpak.sh test --run-test
```

### Debugging the Build
```bash
# Verbose build output
flatpak-builder --verbose flatpak-build flatpak/com.gmx.Application.yml

# Interactive build shell
flatpak-builder --run flatpak-build flatpak/com.gmx.Application.yml bash
```

### Packaging for Distribution

#### Create Release Bundle
```bash
# Build optimized release
./build.sh release
./scripts/build-flatpak.sh all

# Verify bundle
flatpak info --show-metadata dist/GMX-stable.flatpak
```

#### Repository Setup
```bash
# Initialize repository with GPG key
ostree init --mode=archive-z2 --repo=release-repo
flatpak build-commit-from release-repo flatpak-repo com.gmx.Application stable
```

## Performance Optimization

### Startup Performance
- Flatpak adds ~200-500ms startup overhead
- Benefits from warm cache after first run
- Native performance once running

### Memory Usage
- Sandboxing adds ~10-20MB memory overhead
- Shared runtimes reduce overall system memory usage
- Better isolation prevents memory leaks affecting system

### Storage
```bash
# Check Flatpak storage usage
flatpak list --columns=application,size

# Clean up unused runtimes
flatpak uninstall --unused

# Clear application cache
rm -rf ~/.var/app/com.gmx.Application/cache/
```

## Security Benefits

### Sandboxing
- Limited file system access
- Controlled network access
- Isolated from system changes
- Protected user data

### Updates
- Cryptographically signed packages
- Verified dependency chain
- Rollback capability
- Secure distribution channels

## Uninstalling

### Remove Application
```bash
# Remove user installation
flatpak uninstall --user com.gmx.Application

# Remove system installation
sudo flatpak uninstall com.gmx.Application

# Remove user data (optional)
rm -rf ~/.local/share/gmx/
rm -rf ~/.config/gmx/
rm -rf ~/.var/app/com.gmx.Application/
```

### Clean Up Build Environment
```bash
# Remove build artifacts
./scripts/build-flatpak.sh clean --full

# Remove local repository
rm -rf flatpak-repo/
```

## Support and Community

### Getting Help
- **Documentation**: This guide and project README
- **Issues**: GitHub issue tracker
- **Flatpak Community**: https://flatpak.org/community
- **Matrix Chat**: #flatpak:matrix.org

### Contributing
- Report bugs with Flatpak packaging
- Suggest improvements to sandboxing
- Test on different Linux distributions
- Help with documentation updates

---

*This guide ensures secure, reliable installation and usage of the GMX application through Flatpak's modern packaging system, providing enhanced security and cross-distribution compatibility.*