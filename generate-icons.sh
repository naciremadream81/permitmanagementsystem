#!/bin/bash

# Icon generation script for Permit Management System
# Requires: ImageMagick (install with: brew install imagemagick)

echo "🎨 Generating app icons for Permit Management System..."

# Create icons directory
mkdir -p icons

# Convert SVG to PNG at different sizes
echo "Converting SVG to PNG at various sizes..."

# Android icons
convert app-icon-simple.svg -resize 48x48 icons/icon-48x48.png
convert app-icon-simple.svg -resize 72x72 icons/icon-72x72.png
convert app-icon-simple.svg -resize 96x96 icons/icon-96x96.png
convert app-icon-simple.svg -resize 144x144 icons/icon-144x144.png
convert app-icon-simple.svg -resize 192x192 icons/icon-192x192.png
convert app-icon-simple.svg -resize 512x512 icons/icon-512x512.png

# iOS icons
convert app-icon-simple.svg -resize 20x20 icons/ios-icon-20x20.png
convert app-icon-simple.svg -resize 40x40 icons/ios-icon-40x40.png
convert app-icon-simple.svg -resize 60x60 icons/ios-icon-60x60.png
convert app-icon-simple.svg -resize 76x76 icons/ios-icon-76x76.png
convert app-icon-simple.svg -resize 80x80 icons/ios-icon-80x80.png
convert app-icon-simple.svg -resize 120x120 icons/ios-icon-120x120.png
convert app-icon-simple.svg -resize 152x152 icons/ios-icon-152x152.png
convert app-icon-simple.svg -resize 167x167 icons/ios-icon-167x167.png
convert app-icon-simple.svg -resize 180x180 icons/ios-icon-180x180.png
convert app-icon-simple.svg -resize 1024x1024 icons/ios-icon-1024x1024.png

# Desktop icons
convert app-icon-simple.svg -resize 16x16 icons/desktop-icon-16x16.png
convert app-icon-simple.svg -resize 32x32 icons/desktop-icon-32x32.png
convert app-icon-simple.svg -resize 64x64 icons/desktop-icon-64x64.png
convert app-icon-simple.svg -resize 128x128 icons/desktop-icon-128x128.png
convert app-icon-simple.svg -resize 256x256 icons/desktop-icon-256x256.png
convert app-icon-simple.svg -resize 512x512 icons/desktop-icon-512x512.png

# Favicon
convert app-icon-simple.svg -resize 32x32 icons/favicon-32x32.png
convert app-icon-simple.svg -resize 16x16 icons/favicon-16x16.png

# Create ICO file for Windows
convert icons/desktop-icon-16x16.png icons/desktop-icon-32x32.png icons/desktop-icon-64x64.png icons/desktop-icon-128x128.png icons/desktop-icon-256x256.png icons/app-icon.ico

echo "✅ Icons generated successfully!"
echo "📁 Icons are saved in the 'icons' directory"
echo ""
echo "📱 Android icons:"
ls -la icons/icon-*.png
echo ""
echo "🍎 iOS icons:"
ls -la icons/ios-icon-*.png
echo ""
echo "🖥️  Desktop icons:"
ls -la icons/desktop-icon-*.png
echo ""
echo "🌐 Favicon:"
ls -la icons/favicon-*.png
echo ""
echo "🪟 Windows ICO:"
ls -la icons/app-icon.ico 