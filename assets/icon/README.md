# App Icon Setup

## Required Files

Place your ZENiT app icon files in this directory:

1. **app_icon.png** - Main icon (1024x1024 px, PNG with transparency)
2. **app_icon_foreground.png** - Foreground layer for Android adaptive icon (1024x1024 px)

## Icon Design Tips

For a focus/productivity app like ZENiT:
- Use a simple, recognizable symbol (e.g., timer, zen circle, focus dot)
- Keep background dark (#121212) to match app theme
- Foreground should be white/light colored for contrast
- Ensure the icon looks good at small sizes

## Generate Icon

After adding your icon files, run:
```bash
flutter pub get
flutter pub run flutter_launcher_icons
```

This will automatically generate all required icon sizes for Android and iOS.

## Quick Option: Use Material Icons

If you don't have a custom icon yet, you can temporarily use a Material Icon.
The zen_mode view uses `Icons.timer` - this represents the app's focus theme well.
