# Justfile for PS3 Waves KDE Live Wallpaper

compile-shader:
    /usr/lib/qt6/bin/qsb --qt6 --glsl "100 es,120,150" --hlsl 50 --msl 12 -o contents/ui/shaders/wave.qsb contents/ui/shaders/wave.frag

# Build the package to upload to the KDE Store
package: compile-shader
    @mkdir -p build/package
    @rm -rf build/package/contents
    @cp -r contents metadata.json build/package/
    @rm -f build/com.github.relvacode.waves.tar.gz
    @cd build/package && tar -czf ../com.github.relvacode.waves.tar.gz contents metadata.json
    @echo "Package created at build/com.github.relvacode.waves.tar.gz"

# Install the wallpaper by copying files to the correct locations
install: compile-shader
	@echo "Installing PS3 Waves wallpaper..."
	@mkdir -p ~/.local/share/plasma/wallpapers/com.github.relvacode.waves
	@cp -r contents metadata.json ~/.local/share/plasma/wallpapers/com.github.relvacode.waves/
	@echo "Installation complete! Restart KDE Plasma to see the changes."

# Uninstall the wallpaper
uninstall:
	@echo "Uninstalling PS3 Waves wallpaper..."
	@rm -rf ~/.local/share/plasma/wallpapers/com.github.relvacode.waves
	@echo "Uninstallation complete! Restart KDE Plasma to see the changes."

# Check if installation is valid
check-install:
	kpackagetool6 --type Plasma/Wallpaper --show com.github.relvacode.waves


# Clean build files (if any were created)
clean:
	@echo "Cleaning build files..."
	@rm -rf build

restart-plasmashell:
	kquitapp6 plasmashell
	kstart plasmashell


# Default command
default: install
