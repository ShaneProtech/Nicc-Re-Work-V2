# ADAS Detection & Fault Analysis System - User Guide

## Overview

This guide explains the enhanced ADAS (Advanced Driver Assist Systems) detection and fault analysis capabilities that have been integrated into the NICC Calibration Application.

## Key Enhancements

### 1. Enhanced ADAS System Identification

The application now includes comprehensive ADAS keyword detection for accurate system identification from estimate PDFs:

#### ADAS Systems Covered:
- **ADAS Camera Calibration** - Forward-facing camera systems
  - Keywords: ADAS, forward camera, FCM, front camera, FCW, AEB, TSR
- **Radar Sensor Calibration** - ACC and collision avoidance
  - Keywords: radar, ACC, adaptive cruise control, BSM, RCTA
- **Lane Departure Warning System** - LDW/LKA systems
  - Keywords: LDW, LKA, lane keep assist, lane assist, LKAS
- **Blind Spot Monitoring** - BSM and side detection
  - Keywords: BSM, blind spot, BLIS, side assist
- **Parking Assist Sensors** - Ultrasonic sensors
  - Keywords: parking sensor, PDC, park distance control
- **360° Surround View Camera** - Multi-camera systems
  - Keywords: 360 camera, surround view, AVM, bird eye view
- **Adaptive Headlight Aiming** - AFS systems
  - Keywords: AFS, adaptive front lighting, adaptive headlight
- **Steering Angle Sensor** - SAS calibration
  - Keywords: SAS, steering angle sensor, ESC, stability control
- **Night Vision System** - Infrared cameras
  - Keywords: night vision, thermal camera, infrared, IR camera
- **Pedestrian Detection System** - AEB and collision mitigation
  - Keywords: pedestrian detection, AEB, pre-collision, FEB

### 2. Scan Report Fault Detection

The system now intelligently parses scan reports to identify **actual faults** (NOT "No Fault" entries):

#### How It Works:
1. **Fault Parsing**: Automatically extracts lines containing "Fault" while excluding "No Fault" entries
2. **System Identification**: Identifies which ADAS system the fault belongs to
3. **Fault Code Extraction**: Captures diagnostic trouble codes (DTCs) like B1234, C5678, U0123, P0456
4. **Context Analysis**: Analyzes surrounding text to determine the affected system

#### Fault Categories Detected:
- Camera System faults
- Radar System faults
- Lane Departure System faults
- Blind Spot System faults
- Parking Assist faults
- Emergency Braking System faults
- Steering System faults
- Adaptive Lighting System faults

### 3. Pre-Qualifications Display

Each affected ADAS system now displays its **pre-qualification requirements**:

#### Examples of Pre-Qualifications:

**ADAS Camera Calibration:**
- Vehicle must be on level surface
- Ensure proper wheel alignment completed first
- Battery voltage must be 12.5V or higher
- All ADAS-related DTCs must be cleared
- Windshield must be properly installed and cured

**Radar Sensor Calibration:**
- Clear area of at least 20 feet in front of vehicle
- Remove any metal objects near calibration area
- Ensure tire pressures are correct
- Complete wheel alignment if suspension work was performed
- Verify radar module is properly mounted

**Lane Departure Warning System:**
- Wheel alignment must meet OEM specifications
- Steering angle sensor must be calibrated
- Vehicle ride height must be at OEM specification
- Windshield camera must be clean and unobstructed
- Level surface required for calibration

### 4. Clickable Hyperlinks

Each system includes a clickable link to detailed calibration guides:

#### How to Use:
1. View the calibration results
2. Expand any system card
3. Scroll to the bottom to find "View Calibration Guide"
4. Click the link to open detailed instructions in your browser

#### Available Resources:
- Camera calibration procedures
- Radar calibration guides
- Lane departure system setup
- Blind spot monitoring calibration
- And more for all supported systems

## How to Use the Enhanced System

### Step 1: Upload Estimate PDF

1. Navigate to **PDF Upload** screen
2. Select your estimate PDF file
3. The system will extract text and identify:
   - Repair operations (windshield, bumper, etc.)
   - ADAS system mentions
   - Required calibrations

### Step 2: Upload Scan Report PDF (Optional but Recommended)

1. Upload the vehicle scan report
2. The system will:
   - Parse for fault entries
   - Exclude "No Fault" entries
   - Match faults to affected ADAS systems
   - Prioritize systems with actual faults

### Step 3: Review Results

The results will display:

1. **Affected ADAS Systems** (prioritized by faults detected)
2. **System Details**:
   - System name and description
   - Estimated time and cost
   - Required equipment
   - Trigger conditions

3. **Pre-Qualifications** (Green Section):
   - List of requirements before calibration
   - Step-by-step preparation checklist

4. **Calibration Guide Link** (Blue Section):
   - Clickable link to detailed procedures
   - Opens in external browser

### Step 4: Use Estimate Analyzer

Alternative method using text input:

1. Navigate to **Estimate Analyzer** screen
2. Paste estimate text or scan report text
3. Click "Analyze with AI"
4. Review identified systems with pre-quals and links

## Technical Details

### ADAS Keyword Matching

The system uses intelligent keyword matching:
- **Exact matches**: "ADAS", "radar", "camera"
- **Acronyms**: "FCW", "LDW", "BSM", "ACC", "AEB"
- **Variations**: "lane keep", "lane keeping", "lane assist"
- **Context-aware**: Analyzes surrounding text for accurate identification

### Fault Detection Algorithm

```
1. Read scan report line by line
2. For each line:
   - Check if contains "fault" (case-insensitive)
   - Verify it does NOT contain "no fault"
   - Extract DTC code if present
   - Identify system from context
   - Match to ADAS systems in database
3. Return list of actual faults
4. Match faults to affected systems
5. Display pre-quals and hyperlinks for affected systems
```

### Database Schema

Enhanced database includes:
- `pre_qualifications`: Comma-separated list of requirements
- `hyperlink`: URL to calibration guide
- `adas_keywords`: Comma-separated list of detection keywords

## Example Workflow

### Scenario: Front-End Collision with ADAS

**Input:**
- Estimate PDF mentions: "Windshield replacement, front bumper replacement, radar removal"
- Scan Report shows: "Camera System Fault: B1234 - Forward Camera Alignment Error"

**Output:**
1. **ADAS Camera Calibration** (Priority 1 - Fault Detected)
   - Pre-Qualifications displayed
   - Hyperlink to camera calibration guide
   - Estimated time: 1-2 hours
   - Estimated cost: $150-$300

2. **Radar Sensor Calibration** (Priority 2 - Required by estimate)
   - Pre-Qualifications displayed
   - Hyperlink to radar calibration guide
   - Estimated time: 0.5-1 hour
   - Estimated cost: $100-$200

3. **Steering Angle Sensor** (Priority 1 - Pre-requisite)
   - Required before other calibrations
   - Pre-Qualifications displayed

### Total Estimated:
- Time: 2.0 hours
- Cost: $300+

## Benefits

1. **Accurate Detection**: Enhanced ADAS keyword database ensures no systems are missed
2. **Fault Prioritization**: Systems with actual faults are prioritized
3. **Complete Requirements**: Pre-qualifications ensure proper setup before calibration
4. **Quick Reference**: Clickable links provide instant access to detailed procedures
5. **Time Savings**: Reduces research time with integrated documentation
6. **Cost Accuracy**: Better estimates with complete system identification

## Troubleshooting

### If ADAS systems are not detected:
1. Check that the estimate mentions ADAS-related repairs
2. Verify the scan report contains fault information (not just "No Fault")
3. Try the text analyzer with manual input

### If pre-qualifications don't display:
1. Expand the system card completely
2. Pre-quals only show for systems with requirements defined

### If hyperlinks don't work:
1. Ensure internet connection is active
2. Check default browser settings
3. Some corporate networks may block external links

## Updates and Maintenance

The ADAS keyword database and pre-qualification requirements are regularly updated to include:
- New vehicle systems
- Updated calibration procedures
- Additional manufacturer-specific requirements
- Enhanced fault code recognition

---

**For technical support or to report issues, please contact your system administrator.**

**Version:** 2.0 (Enhanced ADAS Detection)
**Last Updated:** October 2025







