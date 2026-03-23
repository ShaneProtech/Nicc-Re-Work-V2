# NICC Calibration Data Documentation Template
## Complete Column Reference & AI Field Interpretation Guide

---

## Dataset Information

| Field | Value |
|-------|-------|
| **Dataset Name** | NICC ADAS Calibration Database |
| **Vehicle Make(s)** | Acura, Alfa Romeo, Audi, BMW, Buick, Cadillac, Chevrolet, Chrysler, Dodge, Fiat, Ford, Genesis, GMC, Honda, Hyundai, Infiniti, Jaguar, Jeep, Kia, Land Rover, Lexus, Lincoln, Mazda, Mercedes, Mini, Mitsubishi, Nissan, Porsche, Ram, Subaru, Tesla, Toyota, Volkswagen, Volvo |
| **Version** | 4.0 |
| **Last Updated** | February 2026 |
| **Maintained By** | Caliber Collision - Protech Information Solutions |
| **Source File(s)** | Excel files per vehicle make (e.g., Acura.xlsx, Honda.xlsx, Toyota.xlsx) |

### Dataset Purpose
This dataset defines ADAS calibration requirements, vehicle applicability, pre-qualification requirements, and service information links for the NICC Calibration Assistant application used by Caliber Collision technicians to determine required calibrations after collision repairs.

---

# COMPLETE COLUMN REFERENCE

## Column A: OEM ADAS System Name

| Attribute | Value |
|-----------|-------|
| **Column Position** | A (1st column) |
| **Database Field** | `name` (alternate) |
| **Data Type** | Text |
| **Required** | No (if Protech Generic System Name exists) |
| **Meaning** | The manufacturer's specific name for the ADAS system |
| **Example Values** | Honda Sensing, Toyota Safety Sense, EyeSight, Co-Pilot360, Nissan Safety Shield 360 |
| **AI Interpretation** | Use for display when OEM-specific terminology is preferred |
| **Validation Rules** | Text, no special characters required |
| **Notes** | May differ significantly between manufacturers for same functionality |

### OEM System Name Examples by Manufacturer

| Make | OEM System Name | Equivalent Generic Name |
|------|-----------------|------------------------|
| Honda | Honda Sensing | ACC, AEB, LKA |
| Toyota | Toyota Safety Sense 2.5 | ACC, AEB, LKA |
| Subaru | EyeSight Driver Assist | ACC, AEB, LKA |
| Ford | Ford Co-Pilot360 | ACC, AEB, BSW, LKA |
| Nissan | Nissan Safety Shield 360 | ACC, AEB, BSW |
| Hyundai | Hyundai SmartSense | ACC, AEB, LKA, BSW |
| BMW | BMW Driving Assistant Professional | ACC, AEB, LKA |
| Mercedes | Mercedes Driver Assistance Package | ACC, AEB, LKA |
| GM | Super Cruise | ACC, LKA |
| Tesla | Autopilot / Full Self-Driving | ACC, AEB, LKA |

---

## Column B: Protech Generic System Name

| Attribute | Value |
|-----------|-------|
| **Column Position** | B (2nd column) |
| **Database Field** | `name` |
| **Data Type** | Text (standardized code) |
| **Required** | **YES - PRIMARY KEY COMPONENT** |
| **Meaning** | Standardized ADAS system identifier used by Protech across all manufacturers |
| **Example Values** | ACC, AEB, AHL, APA, BSW, BUC, LKA, NV, SAS, SVC |
| **AI Interpretation** | Primary system identifier for grouping and lookup |
| **Validation Rules** | Must be one of the standard system codes |
| **Notes** | This is the PRIMARY field used for Database Manager navigation |

### Complete System Code Reference

| Code | Full Name | Category | Description | Common Triggers |
|------|-----------|----------|-------------|-----------------|
| ACC | Adaptive Cruise Control | Radar Systems | Radar-based cruise control maintaining distance from vehicles ahead | Front bumper R&R, front collision, grille replacement, radar sensor work |
| AEB | Automatic Emergency Braking | Radar Systems | Automatic braking to prevent or mitigate collisions | Front bumper R&R, windshield replacement, front camera work, radar work |
| AHL | Adaptive Headlights / Adaptive Front Lighting | Lighting Systems | Dynamic headlamp aiming, cornering lights, auto high beam | Headlight replacement, front collision, suspension work, ride height changes |
| APA | Advanced Parking Assist | Sensor Systems | Ultrasonic parking sensors for parking assistance | Front/rear bumper R&R, sensor replacement, parking aid work |
| BSW | Blind Spot Warning / Blind Spot Monitoring | Radar Systems | Side and rear detection for lane changes | Rear bumper R&R, quarter panel repair, mirror replacement, side sensor work |
| BUC | Backup Camera / Rear View Camera | Camera Systems | Rear view camera for reversing assistance | Tailgate/trunk lid work, rear camera replacement, backup camera R&R |
| LKA | Lane Keep Assist / Lane Departure Warning | Camera Systems | Camera-based lane tracking and steering assist | Windshield replacement, forward camera work, alignment, suspension work |
| NV | Night Vision System | Camera Systems | Infrared thermal imaging for pedestrian/animal detection | Grille replacement, front camera work, radiator support repair |
| SAS | Steering Angle Sensor | Chassis Systems | Steering position sensor for stability control systems | Wheel alignment, steering work, suspension repair, ANY other ADAS calibration |
| SVC | Surround View Camera / 360° Camera | Camera Systems | Multi-camera bird's eye view system | Any camera replacement, bumper work, mirror work |
| RCTA | Rear Cross Traffic Alert | Radar Systems | Detection of crossing traffic when reversing | Rear bumper R&R, rear corner sensor work |
| FCW | Forward Collision Warning | Radar/Camera | Warning system for imminent front collision | Front bumper, windshield, camera or radar work |
| LDW | Lane Departure Warning | Camera Systems | Warning when vehicle leaves lane unintentionally | Windshield replacement, camera work |
| TSR | Traffic Sign Recognition | Camera Systems | Camera-based recognition of road signs | Windshield replacement, camera work |
| DMS | Driver Monitoring System | Camera Systems | Interior camera monitoring driver attention | Interior camera work, mirror replacement |

---

## Column C: Make

| Attribute | Value |
|-----------|-------|
| **Column Position** | C (3rd column) |
| **Database Field** | `vehicle_make` |
| **Data Type** | Text |
| **Required** | **YES - PRIMARY KEY COMPONENT** |
| **Meaning** | Vehicle manufacturer brand name |
| **Example Values** | Acura, Honda, Toyota, Ford, BMW, Mercedes, Chevrolet |
| **AI Interpretation** | Used for filtering and navigation; first level of vehicle selection |
| **Validation Rules** | Must match standard OEM names |
| **Notes** | Stored in uppercase for consistency |

### Supported Vehicle Makes

| Make | Parent Company | Common ADAS Systems |
|------|---------------|---------------------|
| Acura | Honda | Honda Sensing (ACC, AEB, LKA, BSW) |
| Alfa Romeo | Stellantis | ACC, AEB, LKA, BSW |
| Audi | Volkswagen Group | ACC, AEB, LKA, BSW, SVC, NV |
| BMW | BMW Group | ACC, AEB, LKA, BSW, SVC, AHL, NV |
| Buick | General Motors | ACC, AEB, LKA, BSW, SVC |
| Cadillac | General Motors | Super Cruise, ACC, AEB, LKA, BSW, SVC, NV |
| Chevrolet | General Motors | ACC, AEB, LKA, BSW, SVC |
| Chrysler | Stellantis | ACC, AEB, LKA, BSW |
| Dodge | Stellantis | ACC, AEB, BSW |
| Fiat | Stellantis | ACC, AEB, LKA |
| Ford | Ford Motor | Co-Pilot360 (ACC, AEB, LKA, BSW) |
| Genesis | Hyundai | ACC, AEB, LKA, BSW, SVC |
| GMC | General Motors | ACC, AEB, LKA, BSW, SVC |
| Honda | Honda | Honda Sensing (ACC, AEB, LKA) |
| Hyundai | Hyundai | SmartSense (ACC, AEB, LKA, BSW) |
| Infiniti | Nissan | ProPILOT (ACC, AEB, LKA, BSW) |
| Jaguar | Tata Motors | ACC, AEB, LKA, BSW, SVC |
| Jeep | Stellantis | ACC, AEB, LKA, BSW |
| Kia | Hyundai | Drive Wise (ACC, AEB, LKA, BSW) |
| Land Rover | Tata Motors | ACC, AEB, LKA, BSW, SVC |
| Lexus | Toyota | Lexus Safety System+ (ACC, AEB, LKA) |
| Lincoln | Ford Motor | Co-Pilot360 (ACC, AEB, LKA, BSW) |
| Mazda | Mazda | i-Activsense (ACC, AEB, LKA, BSW) |
| Mercedes | Daimler | Driver Assistance (ACC, AEB, LKA, BSW, SVC, NV) |
| Mini | BMW Group | ACC, AEB, LKA |
| Mitsubishi | Mitsubishi | MI-PILOT (ACC, AEB, LKA) |
| Nissan | Nissan | Safety Shield 360 (ACC, AEB, LKA, BSW) |
| Porsche | Volkswagen Group | ACC, AEB, LKA, BSW, SVC, NV |
| Ram | Stellantis | ACC, AEB, BSW |
| Subaru | Subaru | EyeSight (ACC, AEB, LKA) |
| Tesla | Tesla | Autopilot (ACC, AEB, LKA) |
| Toyota | Toyota | TSS 2.5 (ACC, AEB, LKA) |
| Volkswagen | Volkswagen Group | IQ.DRIVE (ACC, AEB, LKA, BSW) |
| Volvo | Geely | Pilot Assist (ACC, AEB, LKA, BSW, SVC) |

---

## Column D: Model Year

| Attribute | Value |
|-----------|-------|
| **Column Position** | D (4th column) |
| **Database Field** | `vehicle_year` |
| **Data Type** | Text/Number (4-digit year) |
| **Required** | **YES - PRIMARY KEY COMPONENT** |
| **Meaning** | Model year of the vehicle |
| **Example Values** | 2020, 2021, 2022, 2023, 2024, 2025, 2026 |
| **AI Interpretation** | Used for filtering; ADAS availability varies by year |
| **Validation Rules** | 4-digit year, typically 2010-2030 range |
| **Notes** | Same model may have different ADAS in different years |

### Year Range Considerations

| Year Range | ADAS Availability | Notes |
|------------|-------------------|-------|
| 2010-2014 | Limited | Early ADAS, mostly luxury brands |
| 2015-2017 | Growing | ADAS becoming more common |
| 2018-2020 | Standard | Most new vehicles have basic ADAS |
| 2021-2023 | Widespread | ADAS standard on most trims |
| 2024-2026 | Universal | Advanced ADAS on nearly all vehicles |

---

## Column E: Model

| Attribute | Value |
|-----------|-------|
| **Column Position** | E (5th column) |
| **Database Field** | `vehicle_model` |
| **Data Type** | Text |
| **Required** | **YES - PRIMARY KEY COMPONENT** |
| **Meaning** | Vehicle model name/designation |
| **Example Values** | MDX, Accord, Camry, F-150, 3 Series, Model 3, Civic |
| **AI Interpretation** | Final level of vehicle selection before system display |
| **Validation Rules** | Must match OEM model designation |
| **Notes** | Include trim level if ADAS varies by trim |

---

## Column F: Calibration Type

| Attribute | Value |
|-----------|-------|
| **Column Position** | F (6th column) |
| **Database Field** | `category` |
| **Data Type** | Text (enumerated values) |
| **Required** | Yes |
| **Meaning** | Method of calibration required for the system |
| **Example Values** | Static, Dynamic, On-Board, Static/Dynamic, No Cal Req, Scan Tool, Pending |
| **AI Interpretation** | Determines calibration procedure and equipment requirements |
| **Validation Rules** | Must be one of the standard calibration types |
| **Notes** | Critical for determining service requirements |

### Calibration Type Values - Complete Reference

| Value | Full Meaning | Procedure Description | Equipment Required | Typical Duration | AI Action |
|-------|--------------|----------------------|-------------------|------------------|-----------|
| No Cal Req | No Calibration Required | System does not require calibration after service | None | N/A | Do NOT generate calibration steps |
| On-Board | On-Board Calibration | Calibration via scan tool commands only, no targets | Diagnostic scanner, OEM software | 15-30 minutes | Suggest scan tool procedure |
| Static | Static Calibration | Stationary calibration using targets/patterns | ADAS targets, calibration frame, level surface, scanner | 1-2 hours | Require target setup verification |
| Dynamic | Dynamic Calibration | Drive cycle calibration on public roads | Diagnostic scanner, GPS (some), clear road conditions | 30-60 minutes | Require drive cycle conditions |
| Static/Dynamic | Static and/or Dynamic | May require one or both methods per OEM | Full ADAS equipment set | 1-3 hours | Check OEM for specific requirement |
| Scan Tool | Scan Tool Reset | Basic reset/relearn via scan tool | Diagnostic scanner | 15-30 minutes | Perform scan tool procedure |
| Pending | Pending Research | Calibration requirements being researched | TBD | TBD | Flag as incomplete, do not recommend |
| Sys N/A | System Not Available | System not equipped on this vehicle | None | N/A | Do not show this system |
| Dealer Only | Dealer Only Calibration | Must be performed at dealership | OEM-specific equipment | Varies | Recommend dealer referral |
| OEM Specific | OEM Specific Procedure | Unique procedure per manufacturer | Varies | Varies | Refer to OEM service information |

---

## Column G: Parent Component

| Attribute | Value |
|-----------|-------|
| **Column Position** | G (7th column) |
| **Database Field** | `category` (alternate mapping) |
| **Data Type** | Text |
| **Required** | No |
| **Meaning** | Primary vehicle component associated with the ADAS system |
| **Example Values** | Front Camera, Front Radar, Rear Camera, Rear Radar, Side Sensors, Headlights |
| **AI Interpretation** | Helps determine which repairs trigger calibration |
| **Validation Rules** | Text, should match standard component names |
| **Notes** | Multiple systems may share the same parent component |

### Parent Component Reference

| Component | Location | Associated Systems | Common Repairs Triggering Calibration |
|-----------|----------|-------------------|--------------------------------------|
| Front Camera | Windshield (behind mirror) | LKA, AEB, TSR, FCW | Windshield replacement, camera R&R |
| Front Radar | Front bumper/grille | ACC, AEB, FCW | Bumper R&R, grille replacement, front collision |
| Rear Camera | Tailgate/trunk lid | BUC | Tailgate work, camera replacement |
| Rear Radar | Rear bumper corners | BSW, RCTA | Rear bumper R&R, quarter panel repair |
| Side Cameras | Side mirrors/doors | SVC, BSW | Mirror replacement, door repair |
| Ultrasonic Sensors | Front/rear bumpers | APA | Bumper R&R, sensor replacement |
| Night Vision Camera | Front grille | NV | Grille work, radiator support repair |
| Headlight Module | Headlight assemblies | AHL | Headlight replacement, front collision |
| Steering Column Sensor | Steering column | SAS | Alignment, steering work, suspension |
| Interior Camera | Rearview mirror/dash | DMS | Mirror replacement, interior work |

---

## Column H: Calibration Prerequisites / Pre-Req / Pre-Qual

| Attribute | Value |
|-----------|-------|
| **Column Position** | H (8th column) |
| **Database Field** | `pre_qualifications` |
| **Data Type** | Text (may be multi-line or delimited) |
| **Required** | Yes (if applicable) |
| **Meaning** | Requirements that MUST be completed BEFORE calibration |
| **Example Values** | 4-Wheel Alignment, Full Fuel Tank, Empty Cargo Area, OEM Ride Height |
| **AI Interpretation** | Display as mandatory prerequisites; calibration cannot proceed without these |
| **Validation Rules** | Text, comma or newline separated for multiple items |
| **Notes** | Critical for successful calibration; must be communicated to customer |

### Complete Pre-Qualification Reference

| Pre-Qual Short Code | Full Requirement Text | Applies To | Reason Required |
|--------------------|----------------------|------------|-----------------|
| ALIGN | Please ensure that the vehicle is accurately aligned. If the vehicle is out of alignment, suspected of being out of alignment, or was involved in a collision, please ensure a 4-Wheel Alignment is performed prior to the ADAS appointment and after your repairs are completed. | ACC, AEB, LKA, BSW, SVC | Camera/radar aim depends on vehicle alignment |
| CARGO | Please ensure the Cargo and Passenger areas are unloaded of all non-factory weight. | ACC, AEB, LKA, BSW, SVC | Affects ride height and calibration accuracy |
| FUEL | Please ensure the Fuel tank is full. | ACC, AEB, LKA, BSW, SVC, AHL | Affects ride height consistency |
| RIDE_HT | Please ensure the Vehicle Ride Height is at OEM specification [unmodified suspension, wheel size, & tire size] | ACC, AEB, LKA, BSW, SVC | Critical for static calibration accuracy |
| TIRE_PSI | Ensure all tires are inflated to OEM door placard specification | All | Affects ride height and alignment |
| BUMPER_RI | Please be aware that the rear bumper may require removal and installation for calibration. | BSW, RCTA | Access to sensors required |
| STEER_CTR | Steering wheel must be centered | SAS | Required for zero-point calibration |
| LEVEL | Vehicle must be on level ground | SAS, Static calibrations | Calibration accuracy requirement |
| BATTERY | Battery voltage must be adequate (12.5V minimum) | All | Electronic systems require stable power |
| IGN_ON | Ignition on, engine off for calibration | SAS, some On-Board | Specific to calibration procedure |
| NO_PREQUAL | No Pre-Qualifications Required for this calibration Procedure | APA, BUC (some) | Simple procedures without prerequisites |
| CLEAN_CAMERA | Ensure camera lens and windshield are clean | LKA, AEB, TSR | Vision-based systems need clear view |
| CLEAR_CODES | Clear all DTCs before calibration | All | Start calibration with clean slate |

---

## Column I: Calibration Prerequisites Short Hand

| Attribute | Value |
|-----------|-------|
| **Column Position** | I (9th column) |
| **Database Field** | `pre_qualifications` (alternate) |
| **Data Type** | Text (abbreviated) |
| **Required** | No (if full prerequisites exist) |
| **Meaning** | Abbreviated version of pre-qualification requirements |
| **Example Values** | Align, Fuel, Cargo, Ride Height |
| **AI Interpretation** | Use for quick reference; expand to full text for customer communication |
| **Validation Rules** | Short text codes |
| **Notes** | Maps to full pre-qualification text |

---

## Column J: Service Information Hyperlink

| Attribute | Value |
|-----------|-------|
| **Column Position** | J (10th column) |
| **Database Field** | `hyperlink` |
| **Data Type** | URL |
| **Required** | Recommended |
| **Meaning** | Link to OEM service information or calibration procedure documentation |
| **Example Values** | https://calibercollision.sharepoint.com/:b:/s/O365-Protech-InformationSolutions/... |
| **AI Interpretation** | Provide as reference; open in viewer when user clicks "View Documentation" |
| **Validation Rules** | Valid URL format |
| **Notes** | Typically SharePoint links to Caliber Collision internal documentation |

---

## Column K: OE Glass Service Info Hyperlink

| Attribute | Value |
|-----------|-------|
| **Column Position** | K (11th column) |
| **Database Field** | `hyperlink` (alternate for glass-related) |
| **Data Type** | URL |
| **Required** | No |
| **Meaning** | Specific link for glass replacement service information |
| **Example Values** | https://calibercollision.sharepoint.com/... |
| **AI Interpretation** | Use specifically when windshield/glass work is involved |
| **Validation Rules** | Valid URL format |
| **Notes** | Windshield replacement has specific calibration requirements |

---

## Column L: Feature

| Attribute | Value |
|-----------|-------|
| **Column Position** | L (12th column) |
| **Database Field** | Not currently mapped |
| **Data Type** | Text |
| **Required** | No |
| **Meaning** | Specific vehicle feature associated with the ADAS system |
| **Example Values** | Cruise Control, Emergency Braking, Lane Keeping, Parking Assist |
| **AI Interpretation** | Use for customer-facing descriptions |
| **Validation Rules** | Text |
| **Notes** | Customer-friendly feature name |

---

## Column M: SME Calibration Type / Expert Classification

| Attribute | Value |
|-----------|-------|
| **Column Position** | M (13th column) |
| **Database Field** | Not currently mapped |
| **Data Type** | Text (enumerated) |
| **Required** | No |
| **Meaning** | Calibration type as classified/overridden by Subject Matter Expert |
| **Example Values** | Confirmed Required, Placeholder, Sys N/A, Pending Review |
| **AI Interpretation** | Expert override takes precedence over standard calibration type |
| **Validation Rules** | Must be standard SME classification |
| **Notes** | Used when standard data needs expert correction |

### SME Classification Values

| Value | Meaning | AI Handling Rule |
|-------|---------|-----------------|
| Confirmed Required | SME has verified calibration is required | Treat as definitive; include in recommendations |
| Placeholder | Temporary data; not verified | Flag as unconfirmed; recommend verification |
| Sys N/A | SME confirmed system not available | Do not show calibration option |
| Pending Review | Awaiting SME verification | Flag for follow-up; use with caution |
| Dealer Confirmed | Dealer has confirmed requirements | Use dealer-specific procedure |

---

## Column N: Internal Display Value

| Attribute | Value |
|-----------|-------|
| **Column Position** | N (14th column) |
| **Database Field** | Not currently mapped |
| **Data Type** | Text |
| **Required** | No |
| **Meaning** | Internal-facing label combining calibration type and component |
| **Example Values** | "Static - Front Camera", "Dynamic - Front Radar" |
| **AI Interpretation** | Use for internal reports and technician-facing displays |
| **Validation Rules** | Text |
| **Notes** | Combines multiple fields for quick reference |

---

## Column O: External Display Value

| Attribute | Value |
|-----------|-------|
| **Column Position** | O (15th column) |
| **Database Field** | Not currently mapped |
| **Data Type** | Text |
| **Required** | No |
| **Meaning** | Customer-facing label using standardized terminology |
| **Example Values** | "Windshield Camera Calibration", "Front Radar Calibration" |
| **AI Interpretation** | Use for customer communications and estimates |
| **Validation Rules** | Text, customer-appropriate language |
| **Notes** | Avoids technical jargon |

---

## Column P: Description / Notes

| Attribute | Value |
|-----------|-------|
| **Column Position** | P (16th column) |
| **Database Field** | `description` |
| **Data Type** | Text |
| **Required** | No |
| **Meaning** | Additional description or notes about the calibration |
| **Example Values** | "Static/Dynamic Calibration - Adaptive Cruise Control for collision avoidance" |
| **AI Interpretation** | Use for detailed explanations when needed |
| **Validation Rules** | Text, may be multi-line |
| **Notes** | Currently hidden in UI but stored in database |

---

## Column Q: Required For / Trigger Conditions

| Attribute | Value |
|-----------|-------|
| **Column Position** | Q (17th column) |
| **Database Field** | `required_for` |
| **Data Type** | Text (comma-separated list) |
| **Required** | No |
| **Meaning** | Repair operations that trigger this calibration requirement |
| **Example Values** | "front bumper R&R, front collision, windshield replacement, camera work" |
| **AI Interpretation** | Use to automatically recommend calibrations based on repair operations |
| **Validation Rules** | Comma-separated text |
| **Notes** | Currently hidden in UI but used for AI recommendations |

### Common Trigger Conditions

| Trigger | Systems Affected | Description |
|---------|-----------------|-------------|
| Front bumper R&R | ACC, AEB, APA (front) | Any front bumper removal/replacement |
| Rear bumper R&R | BSW, RCTA, APA (rear), BUC | Any rear bumper removal/replacement |
| Windshield replacement | LKA, AEB, TSR | Forward camera is attached to windshield |
| Front collision | ACC, AEB, LKA, AHL | Impact may affect sensor alignment |
| Rear collision | BSW, RCTA, BUC | Impact may affect rear sensors |
| Side collision | BSW, SVC | Impact may affect side sensors/cameras |
| Quarter panel repair | BSW | Rear corner radar affected |
| Mirror replacement | BSW, SVC | Side sensors/cameras in mirrors |
| Headlight replacement | AHL | Adaptive headlight modules |
| Grille replacement | ACC, NV | Front radar, night vision camera |
| Wheel alignment | SAS | Always requires SAS calibration |
| Suspension work | SAS, may affect all | Ride height changes affect calibration |
| Steering work | SAS | Steering angle sensor affected |
| Tailgate work | BUC | Backup camera location |
| Radiator support | ACC, NV | Front-mounted sensors |

---

## Column R: Equipment Needed

| Attribute | Value |
|-----------|-------|
| **Column Position** | R (18th column) |
| **Database Field** | `equipment_needed` |
| **Data Type** | Text (comma-separated list) |
| **Required** | No |
| **Meaning** | Equipment required to perform the calibration |
| **Example Values** | "ADAS calibration targets, corner reflectors, diagnostic scanner, level surface" |
| **AI Interpretation** | List for technician preparation |
| **Validation Rules** | Comma-separated text |
| **Notes** | Currently hidden in UI |

### Equipment Reference

| Equipment | Used For | Systems |
|-----------|----------|---------|
| Diagnostic Scanner | All calibrations | All |
| ADAS Calibration Targets | Static calibrations | ACC, AEB, LKA, SVC |
| Lane Pattern Targets | Lane system calibrations | LKA |
| Corner Reflectors | Radar calibrations | ACC, AEB, BSW |
| Calibration Frame/Stand | Target positioning | Static calibrations |
| Level Surface | Static calibrations | All static |
| Headlight Aiming Equipment | Headlight calibration | AHL |
| Wheel Alignment Equipment | Alignment-dependent cals | SAS, all |
| Multi-camera Target Set | 360 camera systems | SVC |
| Thermal/IR Targets | Night vision calibration | NV |

---

## Column S: Estimated Time

| Attribute | Value |
|-----------|-------|
| **Column Position** | S (19th column) |
| **Database Field** | `estimated_time` |
| **Data Type** | Text |
| **Required** | No |
| **Meaning** | Estimated labor time for calibration |
| **Example Values** | "0.5 hours", "1-2 hours", "30 minutes" |
| **AI Interpretation** | Use for scheduling and estimates |
| **Validation Rules** | Time duration text |
| **Notes** | Currently hidden in UI |

---

## Column T: Estimated Cost

| Attribute | Value |
|-----------|-------|
| **Column Position** | T (20th column) |
| **Database Field** | `estimated_cost` |
| **Data Type** | Text (currency) |
| **Required** | No |
| **Meaning** | Estimated cost for calibration service |
| **Example Values** | "$150-$300", "$75-$175" |
| **AI Interpretation** | Use for customer estimates |
| **Validation Rules** | Currency format |
| **Notes** | Currently hidden in UI |

---

## Column U: Priority

| Attribute | Value |
|-----------|-------|
| **Column Position** | U (21st column) |
| **Database Field** | `priority` |
| **Data Type** | Integer (1-3) |
| **Required** | No |
| **Meaning** | Display/importance priority (1=highest) |
| **Example Values** | 1, 2, 3 |
| **AI Interpretation** | Sort order for display; prioritize safety-critical systems |
| **Validation Rules** | Integer 1-3 |
| **Notes** | Currently hidden in UI |

### Priority Levels

| Priority | Meaning | Systems | AI Handling |
|----------|---------|---------|-------------|
| 1 | Critical/Safety | ACC, AEB, SAS | Always recommend first |
| 2 | Important | LKA, BSW, SVC | Recommend after priority 1 |
| 3 | Standard | APA, BUC, AHL, NV | Include in recommendations |

---

## Column V: Keywords / Search Terms

| Attribute | Value |
|-----------|-------|
| **Column Position** | V (22nd column) |
| **Database Field** | `adas_keywords` |
| **Data Type** | Text (comma-separated) |
| **Required** | No |
| **Meaning** | Search keywords for finding this system |
| **Example Values** | "ACC, adaptive cruise, cruise control, front radar, smart cruise" |
| **AI Interpretation** | Use for search functionality |
| **Validation Rules** | Comma-separated text |
| **Notes** | Currently hidden in UI |

---

## Column W: Remarks / Additional Notes

| Attribute | Value |
|-----------|-------|
| **Column Position** | W (23rd column) |
| **Database Field** | Not currently mapped |
| **Data Type** | Text |
| **Required** | No |
| **Meaning** | Additional remarks or special instructions |
| **Example Values** | "Dealer only for this model year", "Requires OEM-specific target" |
| **AI Interpretation** | Display as special notes/warnings |
| **Validation Rules** | Text |
| **Notes** | For exceptional cases |

---

## Column X: Last Updated

| Attribute | Value |
|-----------|-------|
| **Column Position** | X (24th column) |
| **Database Field** | Not currently mapped |
| **Data Type** | Date |
| **Required** | No |
| **Meaning** | Date this record was last updated |
| **Example Values** | 2026-02-09, 01/15/2026 |
| **AI Interpretation** | Track data freshness |
| **Validation Rules** | Date format |
| **Notes** | For data management |

---

## Column Y: Updated By

| Attribute | Value |
|-----------|-------|
| **Column Position** | Y (25th column) |
| **Database Field** | Not currently mapped |
| **Data Type** | Text |
| **Required** | No |
| **Meaning** | Person who last updated this record |
| **Example Values** | "John Smith", "Protech Team" |
| **AI Interpretation** | For audit trail |
| **Validation Rules** | Text |
| **Notes** | For data management |

---

## Column Z: Data Source

| Attribute | Value |
|-----------|-------|
| **Column Position** | Z (26th column) |
| **Database Field** | Not currently mapped |
| **Data Type** | Text |
| **Required** | No |
| **Meaning** | Source of the calibration data |
| **Example Values** | "OEM Service Manual", "Dealer Confirmation", "Field Testing" |
| **AI Interpretation** | Confidence indicator |
| **Validation Rules** | Text |
| **Notes** | For data quality tracking |

---

# DATA IMPORT RULES

## Record Uniqueness
Records are uniquely identified by the combination of:
- **Protech Generic System Name** (Column B)
- **Make** (Column C)  
- **Model Year** (Column D)
- **Model** (Column E)

**Example Unique ID:** `buc_acura_2023_mdx`

## Import Behavior
| Scenario | Action |
|----------|--------|
| New unique record | INSERT new record |
| Existing record (same key) | UPDATE existing record |
| Empty required field | Skip row with warning |
| Invalid data format | Skip row with warning |

## Column Name Matching (Excel → Database)

| Database Field | Accepted Excel Column Headers |
|----------------|------------------------------|
| `name` | Protech Generic System Name, OEM ADAS System Name, System Name, System, Name |
| `vehicle_make` | Make, OEM, Manufacturer, Vehicle Make |
| `vehicle_year` | Model Year, Vehicle Year, Year |
| `vehicle_model` | Vehicle Model, Model Name, Model |
| `category` | Calibration Type, Cal Type, Category, Type, Parent Component |
| `pre_qualifications` | Pre-Req, Pre-Qual, Calibration Prerequisites, Calibration Prerequisites Short Hand, Prerequisites |
| `hyperlink` | Hyperlink, Service Information Hyperlink, OE Glass Service Info Hyperlink, Link, URL |
| `description` | Description, Desc, Notes, Details |
| `required_for` | Required For, Required, Trigger, Applies To |
| `equipment_needed` | Equipment, Equipment Needed, Tools, Required Equipment |
| `estimated_time` | Estimated Time, Time, Duration, Labor Time |
| `estimated_cost` | Estimated Cost, Cost, Price, Fee |
| `adas_keywords` | Keywords, Keyword, Search, Tags |
| `priority` | Priority |

---

# AI INTERPRETATION RULES

## Calibration Decision Logic

```
IF Calibration Type = "No Cal Req" THEN
    DO NOT generate calibration steps
    INFORM user no calibration needed for this system
    
IF Calibration Type = "On-Board" THEN
    RECOMMEND scan tool procedure only
    NO target setup required
    
IF Calibration Type = "Static" THEN
    REQUIRE target setup verification
    REQUIRE level surface confirmation
    REQUIRE pre-qualifications completed
    
IF Calibration Type = "Dynamic" THEN
    REQUIRE specific drive conditions
    PROVIDE drive cycle requirements
    REQUIRE pre-qualifications completed
    
IF Calibration Type = "Static/Dynamic" THEN
    CHECK OEM procedure for specific requirement
    MAY require both procedures
    REQUIRE pre-qualifications completed
    
IF Calibration Type = "Pending" THEN
    FLAG as incomplete data
    RECOMMEND contacting Protech for guidance
    DO NOT make definitive recommendation
```

## Pre-Qualification Enforcement

```
IF Pre-Qualifications exist THEN
    DISPLAY as MANDATORY requirements
    REQUIRE acknowledgment before proceeding
    INCLUDE in customer communication
    
IF "Alignment" in Pre-Qualifications THEN
    VERIFY alignment completed AFTER repairs
    VERIFY alignment completed BEFORE ADAS appointment
    
IF "Fuel Tank" in Pre-Qualifications THEN
    REQUIRE full fuel tank
    INCLUDE in appointment instructions
```

## System Priority Logic

```
SORT recommendations by Priority (1=first)
Priority 1: Safety-critical (ACC, AEB, SAS)
Priority 2: Driver assist (LKA, BSW, SVC)  
Priority 3: Convenience (APA, BUC, AHL, NV)
```

---

# CHANGE LOG

| Date | Change Description | Updated By | Version |
|------|-------------------|------------|---------|
| 2026-02-17 | Complete column documentation created | Development | 4.1 |
| 2026-02-09 | Added vehicle_make column to database | Development | 4.0 |
| 2026-02-09 | Updated record uniqueness to include Make | Development | 4.0 |
| 2026-02-09 | Added Pre-Req/Pre-Qual column mapping | Development | 4.0 |
| 2026-02-09 | Hidden non-essential fields from UI | Development | 4.0 |

---

# VALIDATION CHECKLIST

## Before Import
- [ ] All required columns present (B, C, D, E minimum)
- [ ] Column headers match expected names
- [ ] No completely empty rows
- [ ] Calibration types use standard values
- [ ] Year values are valid (4-digit, 2010-2030)
- [ ] URLs are properly formatted

## After Import
- [ ] Record count matches expected
- [ ] Spot-check 5 random records
- [ ] Navigation works: Make → Year → Model → System
- [ ] Pre-qualifications display correctly
- [ ] Hyperlinks open correctly

---

# CONTACT INFORMATION

| Role | Contact |
|------|---------|
| Data Owner | Protech Information Solutions |
| Technical Support | NICC Development Team |
| SME Contact | Caliber Collision ADAS Team |
