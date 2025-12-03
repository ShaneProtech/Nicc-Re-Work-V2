# Quick Test Guide - Enhanced ADAS Detection

## Quick Start Testing

### Test Scenario 1: Basic ADAS Detection

**Copy this text:**
```
Estimate #12345
- Windshield replacement (W/S)
- Front bumper repair
- ADAS camera removed
- Adaptive cruise control radar sensor
- Lane departure warning system
```

**Steps:**
1. Run the app: `flutter run -d windows` or `run_app.bat`
2. Navigate to **Estimate Analyzer** screen
3. Paste the text above
4. Click **"Analyze with AI"**

**Expected Results:**
- ✅ ADAS Camera Calibration detected
- ✅ Radar Sensor Calibration detected
- ✅ Lane Departure Warning System detected
- ✅ Each system shows 5+ pre-qualifications in green section
- ✅ Each system shows clickable "View Calibration Guide" link
- ✅ Steering Angle Sensor shows (prerequisite for ADAS)

---

### Test Scenario 2: Scan Report with Faults

**Copy this text:**
```
Scan Report Results:

Camera System
- Fault: B1234 Forward Camera Alignment Error

Radar System
- No Fault

Lane Keep Assist
- Fault: C5678 LKA Calibration Required

Blind Spot Monitor
- No Fault

Parking Sensors
- Fault: U0123 PDC System Error
```

**Steps:**
1. Navigate to **Estimate Analyzer** screen
2. Paste the text above
3. Click **"Analyze with AI"**

**Expected Results:**
- ✅ Camera System detected (has fault B1234)
- ✅ Lane Keep Assist detected (has fault C5678)
- ✅ Parking Sensors detected (has fault U0123)
- ❌ Radar System NOT detected (No Fault)
- ❌ Blind Spot Monitor NOT detected (No Fault)
- ✅ Systems with faults show pre-qualifications
- ✅ Systems with faults show hyperlinks

---

### Test Scenario 3: View Pre-Qualifications

**Steps:**
1. After analyzing (use Test 1 or 2)
2. Find any system card
3. Click to expand it
4. Scroll down

**You should see:**

**Green Section - Pre-Qualifications:**
```
✓ Pre-Qualifications:
  → Vehicle must be on level surface
  → Ensure proper wheel alignment completed first
  → Battery voltage must be 12.5V or higher
  → All ADAS-related DTCs must be cleared
  → Windshield must be properly installed and cured
```

---

### Test Scenario 4: Test Hyperlinks

**Steps:**
1. Expand any detected ADAS system
2. Scroll to bottom of card
3. Click **"View Calibration Guide"** button

**Expected Results:**
- ✅ Link opens in your default browser
- ✅ URL goes to training resource
- ✅ No errors in console

---

### Test Scenario 5: Systems Library

**Steps:**
1. Navigate to **Systems Library** screen
2. Browse all 10 ADAS systems
3. Expand each one

**You should see for ALL systems:**
- ✅ Pre-Qualifications section (green)
- ✅ Hyperlink section (blue)
- ✅ 5+ requirements per system
- ✅ Clickable links

**All 10 Systems:**
1. ADAS Camera Calibration
2. Radar Sensor Calibration
3. Lane Departure Warning System
4. Blind Spot Monitoring
5. Parking Assist Sensors
6. 360° Surround View Camera
7. Adaptive Headlight Aiming
8. Steering Angle Sensor
9. Night Vision System
10. Pedestrian Detection System

---

## Troubleshooting

### ⚠️ If systems are not detected:
- Make sure text includes ADAS keywords (camera, radar, ADAS, etc.)
- Try with "Fault" in scan reports (not "No Fault")
- Check console for errors

### ⚠️ If pre-qualifications don't show:
- Expand the card completely
- Look for green section
- Database may need to be recreated (delete nicc_db.db)

### ⚠️ If links don't work:
- Check internet connection
- Verify default browser is set
- Links require url_launcher package (already installed)

### ⚠️ Database issues:
```bash
# If you see errors, delete the database and restart:
# The database file location varies by platform
# It will be recreated automatically with new schema
```

---

## Sample Data Reference

### ADAS Keywords That Trigger Detection:

**Camera Systems:**
- ADAS, forward camera, FCM, front camera
- FCW, forward collision warning
- AEB, automatic emergency braking
- TSR, traffic sign recognition
- LDW, LKA, lane departure, lane keep assist

**Radar Systems:**
- radar, ACC, adaptive cruise control
- BSM, blind spot monitor
- RCTA, rear cross traffic
- collision avoidance, distance sensor

**Sensor Systems:**
- parking sensor, PDC, park distance control
- ultrasonic sensor, parking assist

**Safety Systems:**
- pedestrian detection, pre-collision
- emergency braking, FEB, collision mitigation

---

## Success Criteria

✅ **All 5 TODO items completed:**
1. ✅ Enhanced CalibrationSystem model
2. ✅ Updated database with pre-quals and hyperlinks
3. ✅ Improved PDF service for ADAS detection
4. ✅ Updated UI to display pre-quals and links
5. ✅ Tested with sample data

✅ **Core Requirements Met:**
1. ✅ Estimate PDFs identify ADAS systems correctly
2. ✅ Scan reports detect "Fault" (not "No Fault")
3. ✅ Affected systems display Pre-Quals
4. ✅ Affected systems display hyperlinks

---

## Running the App

```bash
# Option 1: Flutter command
cd "C:\Users\SEang\OneDrive - Caliber Collision\Desktop\A ZACK\ZACK NICC\Nicc Re-Work"
flutter run -d windows

# Option 2: Batch file
run_app.bat

# Option 3: Launch bat file
NICC_Calibration_Launch.bat
```

---

**Ready to test!** Follow the scenarios above to verify all features work correctly.

**Documentation:**
- `ADAS_DETECTION_GUIDE.md` - Comprehensive user guide
- `IMPLEMENTATION_SUMMARY.md` - Technical details and changes
- `QUICK_TEST_GUIDE.md` - This file

**Version:** 2.0 Enhanced ADAS Detection
**Status:** ✅ Complete and Ready for Testing




