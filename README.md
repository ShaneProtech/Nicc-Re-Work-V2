# 🚗 NICC Calibration Assistant

An astonishing Flutter application that uses AI to identify required ADAS (Advanced Driver Assistance Systems) calibrations based on repair estimates and expert knowledge.

## ✨ Features

### 🎯 Core Functionality
- **Estimate Analyzer**: Paste repair estimates and automatically identify required calibrations
- **AI Assistant**: Chat with an intelligent assistant about calibration requirements, costs, and procedures
- **Systems Library**: Browse comprehensive database of 10+ calibration systems
- **Analysis History**: Track past calibration analyses and results

### 🎨 Stunning UI/UX
- **Modern Material Design 3**: Dark theme with vibrant cyan/blue color scheme
- **Smooth Animations**: Page transitions, loading states, and interactive elements
- **Animated Background**: Dynamic gradient background with floating circles
- **Responsive Cards**: Beautiful cards with hover effects and shadows
- **Icon Integration**: Intuitive icons for every system and action

### 🤖 AI-Powered
- **Ollama Integration**: Uses local Ollama LLM for intelligent analysis
- **Fallback Mode**: Keyword-based analysis when AI is unavailable
- **Context-Aware**: AI has full knowledge of all calibration systems

### 💾 Database
- **SQLite Integration**: Local database for fast queries
- **10 Calibration Systems**:
  - ADAS Camera Calibration
  - Radar Sensor Calibration
  - Lane Departure Warning
  - Blind Spot Monitoring
  - Parking Assist Sensors
  - 360° Surround View Camera
  - Adaptive Headlight Aiming
  - Steering Angle Sensor
  - Night Vision System
  - Pedestrian Detection System

## 🚀 Getting Started

### Prerequisites
1. **Flutter SDK**: Install from [flutter.dev](https://flutter.dev)
2. **Ollama** (Optional): Install from [ollama.ai](https://ollama.ai)
   ```bash
   # After installing Ollama, pull a model:
   ollama pull llama2
   ```

### Installation

1. **Clone or navigate to the project directory**
   ```bash
   cd "C:\Users\SEang\OneDrive - Caliber Collision\Desktop\A ZACK\ZACK NICC\Nicc Re-Work"
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the app**
   ```bash
   # For Windows
   flutter run -d windows
   
   # For Android
   flutter run -d android
   
   # For iOS
   flutter run -d ios
   ```

## 📱 App Structure

```
lib/
├── main.dart                          # App entry point with theme
├── models/
│   └── calibration_system.dart       # Data models
├── services/
│   ├── database_service.dart         # SQLite database management
│   └── ollama_service.dart           # AI integration
├── providers/
│   └── calibration_provider.dart     # State management
├── screens/
│   ├── home_screen.dart              # Main dashboard
│   ├── estimate_analyzer_screen.dart # Estimate analysis
│   ├── ai_assistant_screen.dart      # Chat interface
│   ├── systems_library_screen.dart   # Browse systems
│   └── history_screen.dart           # Analysis history
└── widgets/
    ├── animated_background.dart      # Animated gradient background
    ├── feature_card.dart             # Interactive feature cards
    └── calibration_system_card.dart  # System detail cards
```

## 🎨 Design Features

### Color Scheme
- **Primary**: Cyan (#00B4D8) - Main brand color
- **Secondary**: Ocean Blue (#0077B6) - Accents and gradients
- **Tertiary**: Light Cyan (#CAF0F8) - Highlights
- **Surface**: Dark Navy (#1A1A2E) - Card backgrounds
- **Background**: Deep Space (#0F0F1E) - App background

### Typography
- **Font Family**: Poppins (Google Fonts)
- **Weights**: Regular (400), Medium (500), Semi-Bold (600), Bold (700)

### Animations
- **Page Transitions**: Slide and fade animations
- **Card Hover**: Scale and shadow effects
- **Loading States**: Rotating and pulsing indicators
- **Background**: Continuous floating circle animation

## 🔧 Configuration

### Ollama Settings
By default, the app connects to Ollama at `http://localhost:11434` using the `llama2` model.

To customize, edit `lib/services/ollama_service.dart`:
```dart
OllamaService({
  this.baseUrl = 'http://localhost:11434',
  this.model = 'llama2',  // Change to 'mistral', 'codellama', etc.
});
```

### Database
The SQLite database is automatically created on first run with sample calibration data. To modify the data, edit `lib/services/database_service.dart`.

## 📊 Calibration Systems Data

Each system includes:
- **Name**: System identification
- **Description**: What the system does
- **Category**: System classification
- **Required For**: Repair types that require calibration
- **Estimated Time**: Typical calibration duration
- **Estimated Cost**: Price range
- **Equipment Needed**: Required calibration tools
- **Priority**: Importance level (1-4)

## 🎯 Usage Examples

### Analyzing an Estimate
1. Open the **Estimate Analyzer**
2. Paste or type estimate details:
   ```
   - Windshield replacement
   - Front bumper repair
   - Right side mirror replacement
   ```
3. Click **Analyze with AI**
4. View required calibrations with costs and time estimates

### Asking Questions
1. Open the **AI Assistant**
2. Ask questions like:
   - "What calibrations are needed for windshield replacement?"
   - "How much does radar calibration cost?"
   - "What equipment is required for ADAS camera calibration?"

### Browsing Systems
1. Open **Systems Library**
2. Use search or filter by category
3. Tap any system to see full details

## 🛠️ Development

### Adding New Calibration Systems
Edit `lib/services/database_service.dart` and add to the `_insertSampleData` method:

```dart
CalibrationSystem(
  id: 'new_system',
  name: 'New Calibration System',
  description: 'System description',
  category: 'Camera Systems',
  requiredFor: ['trigger1', 'trigger2'],
  estimatedTime: '1-2 hours',
  estimatedCost: '\$100-\$200',
  equipmentNeeded: ['tool1', 'tool2'],
  iconName: 'camera',
  priority: 2,
),
```

### Customizing Theme
Edit the `_buildTheme()` method in `lib/main.dart` to customize colors, fonts, and other theme properties.

## 🧪 Testing

Run tests with:
```bash
flutter test
```

## 📦 Building for Production

### Windows
```bash
flutter build windows --release
```

### Android
```bash
flutter build apk --release
# or
flutter build appbundle --release
```

### iOS
```bash
flutter build ios --release
```

## 🤝 Contributing

This is a custom application for NICC calibration analysis. For modifications or suggestions, contact the development team.

## 📄 License

Proprietary - © 2025 Caliber Collision

## 🆘 Support

For issues or questions:
1. Check that Flutter is properly installed: `flutter doctor`
2. Ensure Ollama is running: `ollama list`
3. Verify database initialization in app logs
4. Contact IT support for technical assistance

## 🎉 Acknowledgments

- **Flutter Team** for the amazing framework
- **Ollama** for local AI capabilities
- **Google Fonts** for beautiful typography
- **Material Design 3** for modern UI guidelines

---

**Built with ❤️ using Flutter**










