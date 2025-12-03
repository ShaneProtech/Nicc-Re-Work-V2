# 📱 NICC Calibration Assistant - App Overview

## 🎯 Purpose

The NICC Calibration Assistant is an intelligent Flutter application designed to help automotive technicians and estimators quickly identify which ADAS (Advanced Driver Assistance Systems) calibrations are required based on repair estimates. It combines a beautiful, modern UI with powerful AI capabilities.

## 🏗️ Architecture

### Technology Stack
```
Frontend:     Flutter (Dart)
Database:     SQLite
AI Service:   Ollama (Local LLM)
State Mgmt:   Provider
UI Library:   Material Design 3
Animations:   Flutter Animate, Staggered Animations
Typography:   Google Fonts (Poppins)
```

### Project Structure
```
NICC Re-Work/
│
├── lib/                                    # Main application code
│   ├── main.dart                          # App entry, theme config
│   │
│   ├── models/                            # Data models
│   │   └── calibration_system.dart       # System & Result models
│   │
│   ├── services/                          # Business logic
│   │   ├── database_service.dart         # SQLite operations
│   │   └── ollama_service.dart           # AI integration
│   │
│   ├── providers/                         # State management
│   │   └── calibration_provider.dart     # App state & logic
│   │
│   ├── screens/                           # UI screens
│   │   ├── home_screen.dart              # Main dashboard
│   │   ├── estimate_analyzer_screen.dart # Estimate analysis UI
│   │   ├── ai_assistant_screen.dart      # Chat interface
│   │   ├── systems_library_screen.dart   # Browse systems
│   │   └── history_screen.dart           # View past analyses
│   │
│   └── widgets/                           # Reusable components
│       ├── animated_background.dart      # Animated gradient BG
│       ├── feature_card.dart             # Interactive cards
│       └── calibration_system_card.dart  # System detail cards
│
├── assets/                                # Static resources
│   ├── animations/                        # Lottie animations
│   ├── icons/                             # Custom icons
│   ├── images/                            # Image assets
│   └── README.md                          # Asset guidelines
│
├── .vscode/                               # Editor config
│   └── launch.json                        # Debug configurations
│
├── pubspec.yaml                           # Dependencies
├── analysis_options.yaml                  # Linting rules
├── .gitignore                             # Git ignore rules
│
├── README.md                              # Main documentation
├── QUICK_START.md                         # Setup guide
├── CHANGELOG.md                           # Version history
└── APP_OVERVIEW.md                        # This file
```

## 🎨 Design System

### Color Palette
| Color | Hex | Usage |
|-------|-----|-------|
| Primary Cyan | `#00B4D8` | Buttons, highlights, main brand |
| Ocean Blue | `#0077B6` | Gradients, accents |
| Deep Blue | `#023E8A` | Secondary elements |
| Light Cyan | `#CAF0F8` | Tertiary, highlights |
| Sky Blue | `#90E0EF` | Text highlights |
| Dark Navy | `#1A1A2E` | Card backgrounds |
| Deep Space | `#0F0F1E` | App background |

### Typography
- **Font Family**: Poppins (Google Fonts)
- **Display**: 57px, 45px, 36px (Bold/Semi-bold)
- **Headlines**: 32px, 28px (Semi-bold)
- **Title**: 22px (Medium)
- **Body**: 16px, 14px (Regular)

### Component Styles
- **Cards**: Rounded 20-24px, gradient backgrounds, subtle borders
- **Buttons**: Rounded 16px, elevated with shadows
- **Input Fields**: Rounded 16px, filled with glass effect
- **Icons**: Material Icons, 24-40px sizes
- **Spacing**: 8px base unit (multiples of 4 or 8)

## 🔧 Core Features

### 1. Estimate Analyzer
**Purpose**: Identify calibrations from repair text

**Flow**:
```
User Input → Paste/Type Estimate Text
     ↓
AI Analysis → Ollama processes with context
     ↓
Keyword Match → Fallback if AI unavailable
     ↓
Results → Display required systems
     ↓
Summary → Cost & time estimates
     ↓
Database → Save to history
```

**Key Files**:
- `screens/estimate_analyzer_screen.dart`
- `services/ollama_service.dart`
- `providers/calibration_provider.dart`

### 2. AI Assistant
**Purpose**: Answer questions about calibrations

**Flow**:
```
User Question → Chat input
     ↓
Context Building → Include all system data
     ↓
AI Query → Send to Ollama with context
     ↓
Response → Display in chat bubble
     ↓
History → Save conversation
```

**Key Files**:
- `screens/ai_assistant_screen.dart`
- `services/ollama_service.dart`

### 3. Systems Library
**Purpose**: Browse and search calibration systems

**Features**:
- Search by name/description
- Filter by category
- Expandable detail cards
- Category badges

**Key Files**:
- `screens/systems_library_screen.dart`
- `widgets/calibration_system_card.dart`

### 4. History
**Purpose**: Track past analyses

**Features**:
- Grouped by date
- Time stamps
- Required/not required indicators
- Searchable

**Key Files**:
- `screens/history_screen.dart`
- `services/database_service.dart`

## 💾 Database Schema

### Tables

#### calibration_systems
```sql
CREATE TABLE calibration_systems (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT,
  category TEXT,
  required_for TEXT,           -- Comma-separated triggers
  estimated_time TEXT,
  estimated_cost TEXT,
  equipment_needed TEXT,        -- Comma-separated items
  icon_name TEXT,
  priority INTEGER
)
```

#### calibration_results
```sql
CREATE TABLE calibration_results (
  id TEXT PRIMARY KEY,
  system_id TEXT,
  system_name TEXT,
  reason TEXT,
  required INTEGER,             -- Boolean: 1 or 0
  analyzed_at TEXT,             -- ISO 8601 timestamp
  FOREIGN KEY (system_id) REFERENCES calibration_systems (id)
)
```

## 🤖 AI Integration

### Ollama Configuration
- **Default URL**: `http://localhost:11434`
- **Default Model**: `llama2`
- **Alternative Models**: `mistral`, `phi`, `codellama`

### AI Prompts

**Estimate Analysis**:
```
You are an ADAS calibration specialist.
Given: List of available systems with triggers
Task: Analyze estimate text
Output: Exact system names that require calibration
```

**Question Answering**:
```
You are an ADAS expert with full system knowledge.
Given: All system details (name, cost, time, equipment)
Task: Answer user question
Output: Professional, detailed response
```

### Fallback Logic
If Ollama is unavailable:
- Keyword matching against `required_for` fields
- Still provides accurate results for common repairs
- App remains fully functional

## 📊 Data Flow

### State Management (Provider)
```
CalibrationProvider
  ├── allSystems: List<CalibrationSystem>
  ├── requiredSystems: List<CalibrationSystem>
  ├── recentResults: List<CalibrationResult>
  ├── isLoading: bool
  ├── ollamaAvailable: bool
  └── errorMessage: String?
```

### Key Operations
1. **Initialize**: Load systems from DB, check Ollama
2. **Analyze**: Process text → Get matches → Save results
3. **Search**: Query DB → Update UI
4. **Ask**: Send to AI → Display response

## 🎬 Animations

### Page Transitions
- **Home → Feature**: Slide + Fade (300ms)
- **Back Navigation**: Reverse slide

### Element Animations
- **Cards**: Staggered fade-in + scale (50ms delay each)
- **Background**: Continuous floating circles (20s loop)
- **Hover**: Scale 1.0 → 1.05 (200ms)
- **Loading**: Rotating + pulsing (1000ms)

### Libraries Used
- `flutter_animate`: Simple animations
- `flutter_staggered_animations`: List animations
- Custom `AnimatedBackground`: Canvas painting

## 🚀 Performance

### Optimizations
- **Lazy Loading**: Only load visible items
- **Local Database**: Fast SQLite queries (<10ms)
- **Cached Fonts**: Google Fonts cached locally
- **Efficient Animations**: GPU-accelerated
- **Provider**: Only rebuilds affected widgets

### Target Performance
- **Cold Start**: <2 seconds
- **Hot Reload**: <500ms
- **DB Query**: <10ms
- **AI Response**: 2-10 seconds (varies by model)
- **UI Responsiveness**: 60 FPS

## 🔒 Security & Privacy

- **Local-First**: All data stored on device
- **No Cloud**: No data sent to external servers
- **Offline**: Works without internet
- **Ollama**: AI runs locally, no data leaves machine
- **No Analytics**: No tracking or telemetry

## 🧪 Testing Strategy

### Unit Tests (Planned)
- Model serialization/deserialization
- Database operations
- Provider state changes

### Widget Tests (Planned)
- Screen rendering
- User interactions
- Navigation flows

### Integration Tests (Planned)
- End-to-end estimate analysis
- AI assistant conversation
- Search functionality

## 📦 Dependencies

### Core
- `flutter`: SDK
- `provider`: State management
- `sqflite`: SQLite database
- `path_provider`: File system paths

### UI/UX
- `google_fonts`: Typography
- `flutter_animate`: Animations
- `flutter_staggered_animations`: List animations
- `animations`: Shared element transitions

### Network/Data
- `http`: HTTP client
- `dio`: Advanced HTTP client
- `intl`: Internationalization

### Utilities
- `uuid`: Unique identifiers
- `shared_preferences`: Simple key-value storage
- `file_picker`: File selection

## 🎓 Learning Resources

### Flutter
- [Flutter Docs](https://flutter.dev/docs)
- [Material Design 3](https://m3.material.io/)
- [Provider Docs](https://pub.dev/packages/provider)

### ADAS
- Calibration system documentation in code
- Industry standards (OEM specific)
- ASE certification materials

## 🔮 Future Roadmap

### Phase 2 (Next 3 months)
- [ ] PDF import functionality
- [ ] Export reports to PDF
- [ ] Vehicle make/model database
- [ ] OEM-specific requirements

### Phase 3 (6 months)
- [ ] Cloud sync (optional)
- [ ] Multi-user support
- [ ] Photo damage assessment
- [ ] Parts ordering integration

### Phase 4 (1 year)
- [ ] Mobile app optimization
- [ ] Barcode scanning
- [ ] Voice commands
- [ ] AR visualization

## 📞 Support & Maintenance

### Regular Updates
- Monthly dependency updates
- Quarterly feature releases
- Immediate security patches

### Known Issues
- None currently

### Reporting Bugs
Contact IT support with:
1. Flutter version (`flutter --version`)
2. Error messages/screenshots
3. Steps to reproduce

---

**Version**: 1.0.0  
**Last Updated**: October 2, 2025  
**Maintainer**: Development Team  
**License**: Proprietary







