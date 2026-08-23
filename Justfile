# Justfile for PS3 Waves KDE Live Wallpaper

# Install the wallpaper by copying files to the correct locations
install:
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
