# Assets Directory

This directory contains all static assets for the NICC Calibration App.

## Folders

### animations/
Place Lottie animation files (.json) here for enhanced UI animations.

Suggested animations:
- Loading animations
- Success/completion animations
- Error state animations

### icons/
Custom icon assets (PNG, SVG) for the app.

The app uses Material Icons by default, but custom icons can be placed here.

### images/
Image assets for the app:
- Logo files
- Splash screen images
- Background images
- Illustration assets

## Adding Assets

1. Place your files in the appropriate folder
2. Update `pubspec.yaml` if needed to include specific file paths
3. Reference in code:
   ```dart
   // For images
   Image.asset('assets/images/your_image.png')
   
   // For Lottie animations
   Lottie.asset('assets/animations/your_animation.json')
   ```

## Asset Guidelines

- **Images**: Use PNG for complex images, SVG for icons when possible
- **Animations**: Lottie JSON files from [LottieFiles](https://lottiefiles.com/)
- **Naming**: Use lowercase with underscores (e.g., `loading_animation.json`)
- **Size**: Optimize images for mobile (compress when possible)










