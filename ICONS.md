# App Icons for Permit Management System

This directory contains the app icons for the Permit Management System across all platforms.

## Icon Design

The app icon features:
- **Building/Construction**: Represents the construction industry
- **Permit Document**: Shows the document management aspect
- **Checkmark**: Indicates approval and completion
- **Permit Stamp**: Represents official approval
- **Blue Background**: Professional and trustworthy color scheme

## Icon Files

### Source Files
- `app-icon.svg` - Detailed version with multiple elements
- `app-icon-simple.svg` - Simplified version for mobile apps

### Generated Icons
Run `./generate-icons.sh` to create all icon sizes:

#### Android Icons
- `icon-48x48.png` - mdpi
- `icon-72x72.png` - hdpi
- `icon-96x96.png` - xhdpi
- `icon-144x144.png` - xxhdpi
- `icon-192x192.png` - xxxhdpi
- `icon-512x512.png` - Play Store

#### iOS Icons
- `ios-icon-20x20.png` - iPhone notification
- `ios-icon-40x40.png` - iPhone notification @2x
- `ios-icon-60x60.png` - iPhone notification @3x
- `ios-icon-76x76.png` - iPad notification
- `ios-icon-80x80.png` - iPad notification @2x
- `ios-icon-120x120.png` - iPhone app @2x
- `ios-icon-152x152.png` - iPad app
- `ios-icon-167x167.png` - iPad app @2x
- `ios-icon-180x180.png` - iPhone app @3x
- `ios-icon-1024x1024.png` - App Store

#### Desktop Icons
- `desktop-icon-16x16.png` - Small desktop
- `desktop-icon-32x32.png` - Standard desktop
- `desktop-icon-64x64.png` - Large desktop
- `desktop-icon-128x128.png` - High DPI desktop
- `desktop-icon-256x256.png` - Retina desktop
- `desktop-icon-512x512.png` - Large desktop
- `app-icon.ico` - Windows executable icon

#### Web Icons
- `favicon-16x16.png` - Small favicon
- `favicon-32x32.png` - Standard favicon

## Usage Instructions

### Prerequisites
Install ImageMagick to generate icons:
```bash
# macOS
brew install imagemagick

# Ubuntu/Debian
sudo apt-get install imagemagick

# Windows
# Download from https://imagemagick.org/
```

### Generate All Icons
```bash
./generate-icons.sh
```

### Manual Conversion
Convert specific sizes:
```bash
convert app-icon-simple.svg -resize 512x512 icon-512x512.png
```

## Platform Integration

### Android
Place icons in `composeApp/src/androidMain/res/mipmap-*`:
- `mipmap-mdpi/ic_launcher.png` (48x48)
- `mipmap-hdpi/ic_launcher.png` (72x72)
- `mipmap-xhdpi/ic_launcher.png` (96x96)
- `mipmap-xxhdpi/ic_launcher.png` (144x144)
- `mipmap-xxxhdpi/ic_launcher.png` (192x192)

### iOS
Place icons in `iosApp/iosApp/Assets.xcassets/AppIcon.appiconset/`:
- `app-icon-20x20@2x.png` (40x40)
- `app-icon-20x20@3x.png` (60x60)
- `app-icon-29x29@2x.png` (58x58)
- `app-icon-29x29@3x.png` (87x87)
- `app-icon-40x40@2x.png` (80x80)
- `app-icon-40x40@3x.png` (120x120)
- `app-icon-60x60@2x.png` (120x120)
- `app-icon-60x60@3x.png` (180x180)
- `app-icon-76x76@2x.png` (152x152)
- `app-icon-83.5x83.5@2x.png` (167x167)
- `app-icon-1024x1024.png` (1024x1024)

### Desktop
For Kotlin Multiplatform Desktop, update the build configuration to include the icon.

### Web
Place favicon files in the web assets directory.

## Icon Specifications

### Design Principles
- **Scalable**: Works at all sizes from 16x16 to 1024x1024
- **Recognizable**: Clear meaning even at small sizes
- **Professional**: Appropriate for construction industry
- **Consistent**: Same design across all platforms

### Color Scheme
- **Primary Blue**: #2563eb to #1d4ed8 (trustworthy, professional)
- **Construction Yellow**: #fbbf24 to #f59e0b (industry standard)
- **Success Green**: #10b981 to #059669 (approval, completion)
- **Warning Red**: #dc2626 (important notices, stamps)

### Technical Requirements
- **Format**: SVG source, PNG output
- **Transparency**: Supported in all formats
- **Aspect Ratio**: 1:1 (square)
- **Padding**: 10% safe area around content
- **Resolution**: Vector-based, scales to any size

## Customization

### Colors
Edit the SVG file to change colors:
- Background gradient: `bgGradient`
- Building gradient: `buildingGradient`
- Checkmark gradient: `checkmarkGradient`

### Elements
The icon consists of:
1. **Building**: Main construction element
2. **Document**: Permit/checklist representation
3. **Checkmark**: Approval indicator
4. **Stamp**: Official permit seal

### Adding Elements
To add new elements, edit the SVG file and regenerate icons:
```bash
# Edit app-icon-simple.svg
# Then regenerate
./generate-icons.sh
```

## Troubleshooting

### Common Issues
1. **ImageMagick not found**: Install ImageMagick first
2. **Permission denied**: Make script executable with `chmod +x generate-icons.sh`
3. **SVG not rendering**: Ensure SVG is valid XML
4. **Icons too small**: Check that resize dimensions are correct

### Quality Assurance
- Test icons at all sizes
- Verify they look good on dark and light backgrounds
- Ensure they're recognizable at small sizes
- Check that they meet platform guidelines

## License

The app icons are part of the Permit Management System and follow the same license as the main project. 