# PS3 Waves Wallpaper

A KDE Plasma 6 live wallpaper that creates animated wave effects reminiscent of PlayStation 3's visual style. It uses a single lightweight GPU shader pass and is suitable for always-on desktop use.

## Features

- Animated wave effects with customizable frequency, amplitude, and speed
- Adjustable framerate for performance tuning
- Customizable background color and wave brightness
- Smooth animation using a GPU-accelerated shader
- Low GPU overhead: no textures, noise lookups, framebuffers, or extra render passes
- Timer-driven animation with a configurable 15–60 FPS cap

## Installation

### Manual Installation

1. Clone or download this repository
2. Navigate to the project directory
3. Run the installation commands:
   ```bash
   just install
   just restart-plasmashell
   ```

### Uninstallation

To uninstall the wallpaper:
```bash
just uninstall
```

## Configuration

The wallpaper can be configured through the Plasma Wallpaper settings:
- **Frequency**: Controls how many waves appear on screen
- **Amplitude**: Controls the height of the waves
- **Center**: Positions the wave group on the screen
- **Thickness**: Controls the thickness of all layered wave bands
- **Gradient Falloff**: Controls how quickly each wave band fades toward its edges
- **Speed**: Controls how fast the waves move
- **Framerate**: Controls animation smoothness (higher = smoother but more resource intensive)
- **Brightness**: Controls how much brighter the animated waves are than the background
- **Color**: The color behind the waves; the waves automatically use a brighter version of it

The default framerate is 30 FPS. Lower it for minimum power use; increase it
when a smoother animation is preferred. The shader renders layered analytic
ribbons in one full-screen pass without animation textures or feedback.


## Requirements

- KDE Plasma 6.0 or higher
- OpenGL 2.0 or higher support
- Compatible graphics drivers

## License

MIT License - see LICENSE file for details

## Author

relvacode
