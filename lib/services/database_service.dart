import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../models/calibration_system.dart';

class DatabaseService {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await initializeDatabase();
    return _database!;
  }

  /// Get the database synchronously (must be initialized first)
  Database? get databaseSync => _database;

  Future<Database> initializeDatabase() async {
    // Initialize FFI for Windows/Linux desktop
    if (Platform.isWindows || Platform.isLinux) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      
      // Use a simple path for Windows/Linux
      final appDocDir = await getApplicationDocumentsDirectory();
      final path = join(appDocDir.path, 'nicc_calibration.db');
      
      return await databaseFactory.openDatabase(
        path,
        options: OpenDatabaseOptions(
          version: 4, // Increased version to add vehicle_make column
          onCreate: _createDatabase,
          onUpgrade: _upgradeDatabase,
        ),
      );
    }
    
    // For mobile platforms
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, 'nicc_calibration.db');

    return await openDatabase(
      path,
      version: 4, // Increased version to add vehicle_make column
      onCreate: _createDatabase,
      onUpgrade: _upgradeDatabase,
    );
  }

  Future<void> _upgradeDatabase(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add new columns for version 2
      await db.execute('ALTER TABLE calibration_systems ADD COLUMN pre_qualifications TEXT DEFAULT ""');
      await db.execute('ALTER TABLE calibration_systems ADD COLUMN hyperlink TEXT DEFAULT ""');
      await db.execute('ALTER TABLE calibration_systems ADD COLUMN adas_keywords TEXT DEFAULT ""');
      
      // Update existing records with new data
      await _updateExistingSystemsWithNewData(db);
    }
    if (oldVersion < 3) {
      // Add vehicle_year and vehicle_model columns for version 3
      await db.execute('ALTER TABLE calibration_systems ADD COLUMN vehicle_year TEXT DEFAULT ""');
      await db.execute('ALTER TABLE calibration_systems ADD COLUMN vehicle_model TEXT DEFAULT ""');
    }
    if (oldVersion < 4) {
      // Add vehicle_make column for version 4
      await db.execute('ALTER TABLE calibration_systems ADD COLUMN vehicle_make TEXT DEFAULT ""');
    }
  }

  Future<void> _updateExistingSystemsWithNewData(Database db) async {
    // Real Caliber Collision NICC ADAS systems data
    final systems = [
      // ACC - Adaptive Cruise Control
      CalibrationSystem(
        id: 'acc_1',
        name: 'Adaptive Cruise Control (ACC)',
        description: 'Static/Dynamic Calibration - Adaptive Cruise Control for collision avoidance and speed control',
        category: 'Radar Systems',
        requiredFor: ['front radar work', 'bumper replacement', 'front collision', 'radar removal', 'grille replacement'],
        estimatedTime: '1-2 hours',
        estimatedCost: '\$150-\$300',
        equipmentNeeded: ['ADAS calibration targets', 'corner reflectors', 'diagnostic scanner', 'level surface'],
        iconName: 'radar',
        priority: 1,
        preQualifications: [
          'Alignment: Please ensure that the vehicle is accurately aligned. If the vehicle is out of alignment, suspected of being out of alignment, or was involved in a collision, please ensure a 4-Wheel Alignment is performed prior to the ADAS appointment and after your repairs are completed.',
          'Cargo Area: Please ensure the Cargo and Passenger areas are unloaded of all non-factory weight.',
          'Full Fuel Tank: Please ensure the Fuel tank is full.',
          'Ride Height: Please ensure the Vehicle Ride Height is at OEM specification [unmodified suspension, wheel size, & tire size]',
        ],
        hyperlink: 'https://calibercollision.sharepoint.com/:b:/s/O365-Protech-InformationSolutions/EaZwnPFWKJhFkBanxe_G-ysBKJbR5h2bu_M0qseJwEvHhg?e=jN9MbM',
        adasKeywords: ['ACC', 'acc', 'adaptive cruise', 'cruise control', 'adaptive cruise control', 'front radar', 'ACC system', 'smart cruise'],
      ),
      // AEB - Automatic Emergency Braking
      CalibrationSystem(
        id: 'aeb_1',
        name: 'Automatic Emergency Braking (AEB)',
        description: 'Static/Dynamic Calibration - Automatic Emergency Braking and Collision Mitigation System',
        category: 'Radar Systems',
        requiredFor: ['front radar work', 'bumper replacement', 'front collision', 'windshield replacement', 'camera work'],
        estimatedTime: '1-2 hours',
        estimatedCost: '\$150-\$300',
        equipmentNeeded: ['ADAS calibration targets', 'corner reflectors', 'diagnostic scanner', 'level surface'],
        iconName: 'radar',
        priority: 1,
        preQualifications: [
          'Alignment: Please ensure that the vehicle is accurately aligned. If the vehicle is out of alignment, suspected of being out of alignment, or was involved in a collision, please ensure a 4-Wheel Alignment is performed prior to the ADAS appointment and after your repairs are completed.',
          'Cargo Area: Please ensure the Cargo and Passenger areas are unloaded of all non-factory weight.',
          'Full Fuel Tank: Please ensure the Fuel tank is full.',
          'Ride Height: Please ensure the Vehicle Ride Height is at OEM specification [unmodified suspension, wheel size, & tire size]',
        ],
        hyperlink: 'https://calibercollision.sharepoint.com/:b:/s/O365-Protech-InformationSolutions/ESDEzx_wrvpLnOv6ERXftr0BRiYFVtCZ39u9BN-X6c14Dw?e=Jjf9gu',
        adasKeywords: ['AEB', 'aeb', 'automatic emergency braking', 'emergency braking', 'collision mitigation', 'CMBS', 'pre-collision', 'forward collision warning', 'FCW', 'collision avoidance', 'forward emergency braking'],
      ),
      // LKA/LDW - Lane Keep Assist
      CalibrationSystem(
        id: 'lka_1',
        name: 'Lane Keep Assist / Lane Departure Warning',
        description: 'Static/Dynamic Calibration - Lane Keeping Assist System (LKAS) and Lane Departure Warning',
        category: 'Camera Systems',
        requiredFor: ['windshield replacement', 'windshield camera work', 'camera removal', 'suspension work', 'alignment', 'front-end collision'],
        estimatedTime: '1-2 hours',
        estimatedCost: '\$125-\$275',
        equipmentNeeded: ['ADAS calibration targets', 'lane pattern targets', 'diagnostic scanner', 'level surface'],
        iconName: 'camera',
        priority: 2,
        preQualifications: [
          'Alignment: Please ensure that the vehicle is accurately aligned. If the vehicle is out of alignment, suspected of being out of alignment, or was involved in a collision, please ensure a 4-Wheel Alignment is performed prior to the ADAS appointment and after your repairs are completed.',
          'Cargo Area: Please ensure the Cargo and Passenger areas are unloaded of all non-factory weight.',
          'Full Fuel Tank: Please ensure the Fuel tank is full.',
          'Ride Height: Please ensure the Vehicle Ride Height is at OEM specification [unmodified suspension, wheel size, & tire size]',
        ],
        hyperlink: 'https://calibercollision.sharepoint.com/:b:/s/O365-Protech-InformationSolutions/ETEWxLVyXYlGou5bEXkcFlMBbr3hTWnYAhvg8VvH6Y057Q?e=5uqUDX',
        adasKeywords: ['LKA', 'lka', 'LDW', 'ldw', 'lane keep assist', 'lane departure warning', 'LKAS', 'lane keeping', 'lane assist', 'lane centering', 'windshield camera', 'forward camera'],
      ),
      // BSW - Blind Spot Warning
      CalibrationSystem(
        id: 'bsw_1',
        name: 'Blind Spot Warning / Blind Spot Monitoring',
        description: 'Static/Dynamic/On-Board Calibration - Blind Spot Information System and Rear Cross Traffic Alert',
        category: 'Radar Systems',
        requiredFor: ['rear bumper replacement', 'quarter panel repair', 'rear sensor work', 'mirror replacement', 'side sensor work'],
        estimatedTime: '0.5-1.5 hours',
        estimatedCost: '\$100-\$200',
        equipmentNeeded: ['Calibration targets', 'diagnostic scanner', 'rear bumper R&I may be required'],
        iconName: 'radar',
        priority: 2,
        preQualifications: [
          'Alignment: Please ensure that the vehicle is accurately aligned. If the vehicle is out of alignment, suspected of being out of alignment, or was involved in a collision, please ensure a 4-Wheel Alignment is performed prior to the ADAS appointment and after your repairs are completed.',
          'Cargo Area: Please ensure the Cargo and Passenger areas are unloaded of all non-factory weight.',
          'Full Fuel Tank: Please ensure the Fuel tank is full.',
          'Ride Height: Please ensure the Vehicle Ride Height is at OEM specification [unmodified suspension, wheel size, & tire size]',
          'Rear Bumper R&I: Please be aware that the rear bumper may require removal and installation for calibration.',
        ],
        hyperlink: 'https://calibercollision.sharepoint.com/:b:/s/O365-Protech-InformationSolutions/EQPoYkCqSQdHoaJmY-U07e4B2Mr-SZ0V67R-Wp9pEvds6A?e=4sC5tx',
        adasKeywords: ['BSW', 'bsw', 'blind spot', 'blind spot warning', 'blind spot monitor', 'BSM', 'BLIS', 'blind spot information', 'RCTA', 'rear cross traffic', 'side assist', 'blind spot detection', 'side obstacle detection'],
      ),
      // APA - Advanced Parking Assist
      CalibrationSystem(
        id: 'apa_1',
        name: 'Advanced Parking Assist (APA)',
        description: 'On-Board/Static Calibration - Parking Aid and Parking Assist System with ultrasonic sensors',
        category: 'Sensor Systems',
        requiredFor: ['bumper replacement', 'sensor replacement', 'parking aid work', 'sonar sensor work'],
        estimatedTime: '0.5-1 hour',
        estimatedCost: '\$75-\$175',
        equipmentNeeded: ['Diagnostic scanner', 'sensor testing equipment'],
        iconName: 'sensors',
        priority: 3,
        preQualifications: [
          'No Pre-Qualifications Required for this calibration Procedure',
        ],
        hyperlink: 'https://calibercollision.sharepoint.com/:b:/s/O365-Protech-InformationSolutions/EYyofvc08B1NphKIjs_9nhwBOrUcgw_rYNKL696SCGofsg?e=XePSeG',
        adasKeywords: ['APA', 'apa', 'parking assist', 'park assist', 'parking aid', 'PDC', 'park distance control', 'ultrasonic sensor', 'parking sensor', 'sonar', 'intuitive park assist', 'parking and back-up sensor'],
      ),
      // SVC - Surround View Camera
      CalibrationSystem(
        id: 'svc_1',
        name: 'Surround View Camera / 360° Camera',
        description: 'Static/Dynamic Calibration - Multi View Camera System (MVCS) and 360-degree camera system',
        category: 'Camera Systems',
        requiredFor: ['camera replacement', 'bumper work', 'mirror work', 'any 360 camera work'],
        estimatedTime: '1-2 hours',
        estimatedCost: '\$200-\$350',
        equipmentNeeded: ['Multi-camera calibration targets', 'grid patterns', 'diagnostic scanner', 'level surface'],
        iconName: 'camera',
        priority: 2,
        preQualifications: [
          'Please ensure that the vehicle is accurately aligned. If the vehicle is out of alignment, suspected of being out of alignment, or was involved in a collision, please ensure a 4-Wheel Alignment is performed prior to the ADAS appointment and after your repairs are completed.',
          'Please ensure the Cargo and Passenger areas are unloaded of all non-factory weight.',
          'Please ensure the Fuel tank is full.',
          'Please ensure the Vehicle Ride Height is at OEM specification [unmodified suspension, wheel size, & tire size]',
        ],
        hyperlink: 'https://calibercollision.sharepoint.com/:b:/s/O365-Protech-InformationSolutions/EbhjT9Ht7YlBq34XDz9lI08B-sjxS8cZ4V0hGr_KTEwtTw?e=wKfSGh',
        adasKeywords: ['SVC', 'svc', '360 camera', 'surround view', 'surround view camera', 'around view monitor', 'AVM', 'bird eye view', 'top view', 'multi view camera', 'MVCS', 'peripheral camera', 'panoramic view'],
      ),
      // BUC - Backup Camera
      CalibrationSystem(
        id: 'buc_1',
        name: 'Backup Camera / Rear View Camera',
        description: 'Static/On-Board Calibration - Rear view camera and parking camera system',
        category: 'Camera Systems',
        requiredFor: ['backup camera replacement', 'rear camera work', 'tailgate work'],
        estimatedTime: '0.5-1 hour',
        estimatedCost: '\$75-\$150',
        equipmentNeeded: ['Calibration targets', 'diagnostic scanner'],
        iconName: 'camera',
        priority: 3,
        preQualifications: [
          'No Pre-Qualifications Required for this calibration Procedure',
        ],
        hyperlink: 'https://calibercollision.sharepoint.com/:b:/s/O365-Protech-InformationSolutions/EQXJL7JdiadKmh7TrshWlBUBrgWRVnvcBqYWk3VIkGmcLQ?e=QNZr5C',
        adasKeywords: ['BUC', 'buc', 'backup camera', 'rear view camera', 'rear camera', 'rearview camera', 'parkview', 'reverse camera'],
      ),
      // AHL - Adaptive Headlights
      CalibrationSystem(
        id: 'ahl_1',
        name: 'Adaptive Headlights / Adaptive Front Lighting',
        description: 'Static/On-Board Calibration - Adaptive headlamp and dynamic lighting system aiming',
        category: 'Lighting Systems',
        requiredFor: ['headlight replacement', 'front-end collision', 'suspension work', 'ride height changes'],
        estimatedTime: '0.5-1 hour',
        estimatedCost: '\$75-\$175',
        equipmentNeeded: ['Headlight aiming equipment', 'diagnostic scanner', 'alignment screen'],
        iconName: 'lightbulb',
        priority: 3,
        preQualifications: [
          'Full Fuel Tank: Please ensure the Fuel tank is full.',
        ],
        hyperlink: 'https://calibercollision.sharepoint.com/:b:/s/O365-Protech-InformationSolutions/EXP7o0ceYP5Mr0_RolQfNC4BAq7-RT29TS6Z59-tjOeRgQ?e=9JeZg7',
        adasKeywords: ['AHL', 'ahl', 'adaptive headlight', 'adaptive front lighting', 'AFS', 'swivel headlight', 'cornering light', 'auto high beam', 'dynamic headlight', 'adaptive healights'],
      ),
      // SAS - Steering Angle Sensor (Critical prerequisite for ADAS)
      CalibrationSystem(
        id: 'sas_1',
        name: 'Steering Angle Sensor Calibration',
        description: 'Steering angle sensor zero-point calibration - Required prerequisite for most ADAS calibrations',
        category: 'Chassis Systems',
        requiredFor: ['wheel alignment', 'steering work', 'suspension repair', 'any ADAS calibration', 'after any alignment'],
        estimatedTime: '0.5 hours',
        estimatedCost: '\$50-\$125',
        equipmentNeeded: ['Diagnostic scanner', 'alignment equipment'],
        iconName: 'steering',
        priority: 1,
        preQualifications: [
          'Wheel alignment must be completed first and meet OEM specifications',
          'Steering wheel must be centered',
          'Vehicle must be on level ground',
          'Ignition on, engine off for calibration',
          'Battery voltage must be adequate (12.5V minimum)',
        ],
        hyperlink: 'https://calibercollision.sharepoint.com/:f:/s/O365-Protech-InformationSolutions/EmNJbuXeBc5OofPHo0avKLYBEVx_G6X1yJUMP7JFWJQGzQ?e=waDk4W',
        adasKeywords: ['SAS', 'sas', 'steering angle sensor', 'steering sensor', 'ESC', 'stability control', 'VSC', 'vehicle stability', 'steering calibration', 'steering angle'],
      ),
      // NV - Night Vision System (if equipped)
      CalibrationSystem(
        id: 'nv_1',
        name: 'Night Vision System / Infrared Camera',
        description: 'Static Calibration - Infrared night vision camera system for pedestrian and animal detection',
        category: 'Camera Systems',
        requiredFor: ['front camera work', 'grille replacement', 'radiator support repair', 'night vision camera work'],
        estimatedTime: '1-2 hours',
        estimatedCost: '\$150-\$300',
        equipmentNeeded: ['Thermal imaging targets', 'ADAS calibration system', 'diagnostic scanner'],
        iconName: 'camera',
        priority: 3,
        preQualifications: [
          'Pending Further Research',
        ],
        hyperlink: 'https://calibercollision.sharepoint.com/:b:/s/O365-Protech-InformationSolutions/EZNeQVS-L6ZCtdq3NhpK_3UBNQKuLmiDcUmFzMVQfEN54A?e=aN1QYh',
        adasKeywords: ['NV', 'nv', 'night vision', 'thermal camera', 'infrared', 'IR camera', 'infared system', 'infrared night vision', 'NVS'],
      ),
    ];

    // Update each system with new data
    for (var system in systems) {
      await db.update(
        'calibration_systems',
        {
          'pre_qualifications': system.preQualifications.join(','),
          'hyperlink': system.hyperlink ?? '',
          'adas_keywords': system.adasKeywords.join(','),
        },
        where: 'id = ?',
        whereArgs: [system.id],
      );
    }
  }

  Future<void> _createDatabase(Database db, int version) async {
    // Create calibration_systems table
    await db.execute('''
      CREATE TABLE calibration_systems (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        category TEXT,
        required_for TEXT,
        estimated_time TEXT,
        estimated_cost TEXT,
        equipment_needed TEXT,
        icon_name TEXT,
        priority INTEGER,
        pre_qualifications TEXT,
        hyperlink TEXT,
        adas_keywords TEXT,
        vehicle_year TEXT,
        vehicle_model TEXT,
        vehicle_make TEXT
      )
    ''');

    // Create calibration_results table
    await db.execute('''
      CREATE TABLE calibration_results (
        id TEXT PRIMARY KEY,
        system_id TEXT,
        system_name TEXT,
        reason TEXT,
        required INTEGER,
        analyzed_at TEXT,
        FOREIGN KEY (system_id) REFERENCES calibration_systems (id)
      )
    ''');

    // Insert sample calibration systems
    await _insertSampleData(db);
  }

  Future<void> _insertSampleData(Database db) async {
    // Real Caliber Collision NICC ADAS systems - same as update method
    final systems = [
      // ACC - Adaptive Cruise Control
      CalibrationSystem(
        id: 'acc_1',
        name: 'Adaptive Cruise Control (ACC)',
        description: 'Static/Dynamic Calibration - Adaptive Cruise Control for collision avoidance and speed control',
        category: 'Radar Systems',
        requiredFor: ['front radar work', 'bumper replacement', 'front collision', 'radar removal', 'grille replacement'],
        estimatedTime: '1-2 hours',
        estimatedCost: '\$150-\$300',
        equipmentNeeded: ['ADAS calibration targets', 'corner reflectors', 'diagnostic scanner', 'level surface'],
        iconName: 'radar',
        priority: 1,
        preQualifications: [
          'Alignment: Please ensure that the vehicle is accurately aligned. If the vehicle is out of alignment, suspected of being out of alignment, or was involved in a collision, please ensure a 4-Wheel Alignment is performed prior to the ADAS appointment and after your repairs are completed.',
          'Cargo Area: Please ensure the Cargo and Passenger areas are unloaded of all non-factory weight.',
          'Full Fuel Tank: Please ensure the Fuel tank is full.',
          'Ride Height: Please ensure the Vehicle Ride Height is at OEM specification [unmodified suspension, wheel size, & tire size]',
        ],
        hyperlink: 'https://calibercollision.sharepoint.com/:b:/s/O365-Protech-InformationSolutions/EaZwnPFWKJhFkBanxe_G-ysBKJbR5h2bu_M0qseJwEvHhg?e=jN9MbM',
        adasKeywords: ['ACC', 'acc', 'adaptive cruise', 'cruise control', 'adaptive cruise control', 'front radar', 'ACC system', 'smart cruise'],
      ),
      // AEB - Automatic Emergency Braking
      CalibrationSystem(
        id: 'aeb_1',
        name: 'Automatic Emergency Braking (AEB)',
        description: 'Static/Dynamic Calibration - Automatic Emergency Braking and Collision Mitigation System',
        category: 'Radar Systems',
        requiredFor: ['front radar work', 'bumper replacement', 'front collision', 'windshield replacement', 'camera work'],
        estimatedTime: '1-2 hours',
        estimatedCost: '\$150-\$300',
        equipmentNeeded: ['ADAS calibration targets', 'corner reflectors', 'diagnostic scanner', 'level surface'],
        iconName: 'radar',
        priority: 1,
        preQualifications: [
          'Alignment: Please ensure that the vehicle is accurately aligned. If the vehicle is out of alignment, suspected of being out of alignment, or was involved in a collision, please ensure a 4-Wheel Alignment is performed prior to the ADAS appointment and after your repairs are completed.',
          'Cargo Area: Please ensure the Cargo and Passenger areas are unloaded of all non-factory weight.',
          'Full Fuel Tank: Please ensure the Fuel tank is full.',
          'Ride Height: Please ensure the Vehicle Ride Height is at OEM specification [unmodified suspension, wheel size, & tire size]',
        ],
        hyperlink: 'https://calibercollision.sharepoint.com/:b:/s/O365-Protech-InformationSolutions/ESDEzx_wrvpLnOv6ERXftr0BRiYFVtCZ39u9BN-X6c14Dw?e=Jjf9gu',
        adasKeywords: ['AEB', 'aeb', 'automatic emergency braking', 'emergency braking', 'collision mitigation', 'CMBS', 'pre-collision', 'forward collision warning', 'FCW', 'collision avoidance', 'forward emergency braking'],
      ),
      // LKA/LDW - Lane Keep Assist
      CalibrationSystem(
        id: 'lka_1',
        name: 'Lane Keep Assist / Lane Departure Warning',
        description: 'Static/Dynamic Calibration - Lane Keeping Assist System (LKAS) and Lane Departure Warning',
        category: 'Camera Systems',
        requiredFor: ['windshield replacement', 'windshield camera work', 'camera removal', 'suspension work', 'alignment', 'front-end collision'],
        estimatedTime: '1-2 hours',
        estimatedCost: '\$125-\$275',
        equipmentNeeded: ['ADAS calibration targets', 'lane pattern targets', 'diagnostic scanner', 'level surface'],
        iconName: 'camera',
        priority: 2,
        preQualifications: [
          'Alignment: Please ensure that the vehicle is accurately aligned. If the vehicle is out of alignment, suspected of being out of alignment, or was involved in a collision, please ensure a 4-Wheel Alignment is performed prior to the ADAS appointment and after your repairs are completed.',
          'Cargo Area: Please ensure the Cargo and Passenger areas are unloaded of all non-factory weight.',
          'Full Fuel Tank: Please ensure the Fuel tank is full.',
          'Ride Height: Please ensure the Vehicle Ride Height is at OEM specification [unmodified suspension, wheel size, & tire size]',
        ],
        hyperlink: 'https://calibercollision.sharepoint.com/:b:/s/O365-Protech-InformationSolutions/ETEWxLVyXYlGou5bEXkcFlMBbr3hTWnYAhvg8VvH6Y057Q?e=5uqUDX',
        adasKeywords: ['LKA', 'lka', 'LDW', 'ldw', 'lane keep assist', 'lane departure warning', 'LKAS', 'lane keeping', 'lane assist', 'lane centering', 'windshield camera', 'forward camera'],
      ),
      // BSW - Blind Spot Warning
      CalibrationSystem(
        id: 'bsw_1',
        name: 'Blind Spot Warning / Blind Spot Monitoring',
        description: 'Static/Dynamic/On-Board Calibration - Blind Spot Information System and Rear Cross Traffic Alert',
        category: 'Radar Systems',
        requiredFor: ['rear bumper replacement', 'quarter panel repair', 'rear sensor work', 'mirror replacement', 'side sensor work'],
        estimatedTime: '0.5-1.5 hours',
        estimatedCost: '\$100-\$200',
        equipmentNeeded: ['Calibration targets', 'diagnostic scanner', 'rear bumper R&I may be required'],
        iconName: 'radar',
        priority: 2,
        preQualifications: [
          'Alignment: Please ensure that the vehicle is accurately aligned. If the vehicle is out of alignment, suspected of being out of alignment, or was involved in a collision, please ensure a 4-Wheel Alignment is performed prior to the ADAS appointment and after your repairs are completed.',
          'Cargo Area: Please ensure the Cargo and Passenger areas are unloaded of all non-factory weight.',
          'Full Fuel Tank: Please ensure the Fuel tank is full.',
          'Ride Height: Please ensure the Vehicle Ride Height is at OEM specification [unmodified suspension, wheel size, & tire size]',
          'Rear Bumper R&I: Please be aware that the rear bumper may require removal and installation for calibration.',
        ],
        hyperlink: 'https://calibercollision.sharepoint.com/:b:/s/O365-Protech-InformationSolutions/EQPoYkCqSQdHoaJmY-U07e4B2Mr-SZ0V67R-Wp9pEvds6A?e=4sC5tx',
        adasKeywords: ['BSW', 'bsw', 'blind spot', 'blind spot warning', 'blind spot monitor', 'BSM', 'BLIS', 'blind spot information', 'RCTA', 'rear cross traffic', 'side assist', 'blind spot detection', 'side obstacle detection'],
      ),
      // APA - Advanced Parking Assist
      CalibrationSystem(
        id: 'apa_1',
        name: 'Advanced Parking Assist (APA)',
        description: 'On-Board/Static Calibration - Parking Aid and Parking Assist System with ultrasonic sensors',
        category: 'Sensor Systems',
        requiredFor: ['bumper replacement', 'sensor replacement', 'parking aid work', 'sonar sensor work'],
        estimatedTime: '0.5-1 hour',
        estimatedCost: '\$75-\$175',
        equipmentNeeded: ['Diagnostic scanner', 'sensor testing equipment'],
        iconName: 'sensors',
        priority: 3,
        preQualifications: [
          'No Pre-Qualifications Required for this calibration Procedure',
        ],
        hyperlink: 'https://calibercollision.sharepoint.com/:b:/s/O365-Protech-InformationSolutions/EYyofvc08B1NphKIjs_9nhwBOrUcgw_rYNKL696SCGofsg?e=XePSeG',
        adasKeywords: ['APA', 'apa', 'parking assist', 'park assist', 'parking aid', 'PDC', 'park distance control', 'ultrasonic sensor', 'parking sensor', 'sonar', 'intuitive park assist', 'parking and back-up sensor'],
      ),
      // SVC - Surround View Camera
      CalibrationSystem(
        id: 'svc_1',
        name: 'Surround View Camera / 360° Camera',
        description: 'Static/Dynamic Calibration - Multi View Camera System (MVCS) and 360-degree camera system',
        category: 'Camera Systems',
        requiredFor: ['camera replacement', 'bumper work', 'mirror work', 'any 360 camera work'],
        estimatedTime: '1-2 hours',
        estimatedCost: '\$200-\$350',
        equipmentNeeded: ['Multi-camera calibration targets', 'grid patterns', 'diagnostic scanner', 'level surface'],
        iconName: 'camera',
        priority: 2,
        preQualifications: [
          'Please ensure that the vehicle is accurately aligned. If the vehicle is out of alignment, suspected of being out of alignment, or was involved in a collision, please ensure a 4-Wheel Alignment is performed prior to the ADAS appointment and after your repairs are completed.',
          'Please ensure the Cargo and Passenger areas are unloaded of all non-factory weight.',
          'Please ensure the Fuel tank is full.',
          'Please ensure the Vehicle Ride Height is at OEM specification [unmodified suspension, wheel size, & tire size]',
        ],
        hyperlink: 'https://calibercollision.sharepoint.com/:b:/s/O365-Protech-InformationSolutions/EbhjT9Ht7YlBq34XDz9lI08B-sjxS8cZ4V0hGr_KTEwtTw?e=wKfSGh',
        adasKeywords: ['SVC', 'svc', '360 camera', 'surround view', 'surround view camera', 'around view monitor', 'AVM', 'bird eye view', 'top view', 'multi view camera', 'MVCS', 'peripheral camera', 'panoramic view'],
      ),
      // BUC - Backup Camera
      CalibrationSystem(
        id: 'buc_1',
        name: 'Backup Camera / Rear View Camera',
        description: 'Static/On-Board Calibration - Rear view camera and parking camera system',
        category: 'Camera Systems',
        requiredFor: ['backup camera replacement', 'rear camera work', 'tailgate work'],
        estimatedTime: '0.5-1 hour',
        estimatedCost: '\$75-\$150',
        equipmentNeeded: ['Calibration targets', 'diagnostic scanner'],
        iconName: 'camera',
        priority: 3,
        preQualifications: [
          'No Pre-Qualifications Required for this calibration Procedure',
        ],
        hyperlink: 'https://calibercollision.sharepoint.com/:b:/s/O365-Protech-InformationSolutions/EQXJL7JdiadKmh7TrshWlBUBrgWRVnvcBqYWk3VIkGmcLQ?e=QNZr5C',
        adasKeywords: ['BUC', 'buc', 'backup camera', 'rear view camera', 'rear camera', 'rearview camera', 'parkview', 'reverse camera'],
      ),
      // AHL - Adaptive Headlights
      CalibrationSystem(
        id: 'ahl_1',
        name: 'Adaptive Headlights / Adaptive Front Lighting',
        description: 'Static/On-Board Calibration - Adaptive headlamp and dynamic lighting system aiming',
        category: 'Lighting Systems',
        requiredFor: ['headlight replacement', 'front-end collision', 'suspension work', 'ride height changes'],
        estimatedTime: '0.5-1 hour',
        estimatedCost: '\$75-\$175',
        equipmentNeeded: ['Headlight aiming equipment', 'diagnostic scanner', 'alignment screen'],
        iconName: 'lightbulb',
        priority: 3,
        preQualifications: [
          'Full Fuel Tank: Please ensure the Fuel tank is full.',
        ],
        hyperlink: 'https://calibercollision.sharepoint.com/:b:/s/O365-Protech-InformationSolutions/EXP7o0ceYP5Mr0_RolQfNC4BAq7-RT29TS6Z59-tjOeRgQ?e=9JeZg7',
        adasKeywords: ['AHL', 'ahl', 'adaptive headlight', 'adaptive front lighting', 'AFS', 'swivel headlight', 'cornering light', 'auto high beam', 'dynamic headlight', 'adaptive healights'],
      ),
      // SAS - Steering Angle Sensor (Critical prerequisite for ADAS)
      CalibrationSystem(
        id: 'sas_1',
        name: 'Steering Angle Sensor Calibration',
        description: 'Steering angle sensor zero-point calibration - Required prerequisite for most ADAS calibrations',
        category: 'Chassis Systems',
        requiredFor: ['wheel alignment', 'steering work', 'suspension repair', 'any ADAS calibration', 'after any alignment'],
        estimatedTime: '0.5 hours',
        estimatedCost: '\$50-\$125',
        equipmentNeeded: ['Diagnostic scanner', 'alignment equipment'],
        iconName: 'steering',
        priority: 1,
        preQualifications: [
          'Wheel alignment must be completed first and meet OEM specifications',
          'Steering wheel must be centered',
          'Vehicle must be on level ground',
          'Ignition on, engine off for calibration',
          'Battery voltage must be adequate (12.5V minimum)',
        ],
        hyperlink: 'https://calibercollision.sharepoint.com/:f:/s/O365-Protech-InformationSolutions/EmNJbuXeBc5OofPHo0avKLYBEVx_G6X1yJUMP7JFWJQGzQ?e=waDk4W',
        adasKeywords: ['SAS', 'sas', 'steering angle sensor', 'steering sensor', 'ESC', 'stability control', 'VSC', 'vehicle stability', 'steering calibration', 'steering angle'],
      ),
      // NV - Night Vision System (if equipped)
      CalibrationSystem(
        id: 'nv_1',
        name: 'Night Vision System / Infrared Camera',
        description: 'Static Calibration - Infrared night vision camera system for pedestrian and animal detection',
        category: 'Camera Systems',
        requiredFor: ['front camera work', 'grille replacement', 'radiator support repair', 'night vision camera work'],
        estimatedTime: '1-2 hours',
        estimatedCost: '\$150-\$300',
        equipmentNeeded: ['Thermal imaging targets', 'ADAS calibration system', 'diagnostic scanner'],
        iconName: 'camera',
        priority: 3,
        preQualifications: [
          'Pending Further Research',
        ],
        hyperlink: 'https://calibercollision.sharepoint.com/:b:/s/O365-Protech-InformationSolutions/EZNeQVS-L6ZCtdq3NhpK_3UBNQKuLmiDcUmFzMVQfEN54A?e=aN1QYh',
        adasKeywords: ['NV', 'nv', 'night vision', 'thermal camera', 'infrared', 'IR camera', 'infared system', 'infrared night vision', 'NVS'],
      ),
    ];

    for (var system in systems) {
      await db.insert('calibration_systems', system.toMap());
    }
  }

  Future<List<CalibrationSystem>> getAllSystems() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'calibration_systems',
      orderBy: 'priority ASC',
    );

    return List.generate(maps.length, (i) => CalibrationSystem.fromMap(maps[i]));
  }

  Future<List<CalibrationSystem>> searchSystems(String query) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'calibration_systems',
      where: 'name LIKE ? OR description LIKE ? OR required_for LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
      orderBy: 'priority ASC',
    );

    return List.generate(maps.length, (i) => CalibrationSystem.fromMap(maps[i]));
  }

  Future<void> saveCalibrationResult(CalibrationResult result) async {
    final db = await database;
    await db.insert(
      'calibration_results',
      result.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<CalibrationResult>> getRecentResults({int limit = 10}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'calibration_results',
      orderBy: 'analyzed_at DESC',
      limit: limit,
    );

    return List.generate(maps.length, (i) => CalibrationResult.fromMap(maps[i]));
  }

  // Get systems relevant to specific vehicle types
  Future<List<CalibrationSystem>> getSystemsByVehicleType(String vehicleType) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'calibration_systems',
      where: 'required_for LIKE ? OR description LIKE ?',
      whereArgs: ['%$vehicleType%', '%$vehicleType%'],
      orderBy: 'priority ASC',
    );

    return List.generate(maps.length, (i) => CalibrationSystem.fromMap(maps[i]));
  }

  // Get systems relevant to specific impact areas
  Future<List<CalibrationSystem>> getSystemsByImpactArea(String impactArea) async {
    final db = await database;
    final impactKeywords = _getImpactKeywords(impactArea);
    
    final List<Map<String, dynamic>> maps = await db.query(
      'calibration_systems',
      where: impactKeywords.map((_) => 'required_for LIKE ?').join(' OR '),
      whereArgs: impactKeywords.map((keyword) => '%$keyword%').toList(),
      orderBy: 'priority ASC',
    );

    return List.generate(maps.length, (i) => CalibrationSystem.fromMap(maps[i]));
  }

  // Get pre-qualification requirements for specific systems
  Future<List<CalibrationSystem>> getPreQualificationRequirements(String systemName) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'calibration_systems',
      where: 'name LIKE ? OR category LIKE ?',
      whereArgs: ['%$systemName%', '%$systemName%'],
      orderBy: 'priority ASC',
    );

    return List.generate(maps.length, (i) => CalibrationSystem.fromMap(maps[i]));
  }

  // Helper method to map impact areas to relevant keywords
  List<String> _getImpactKeywords(String impactArea) {
    final area = impactArea.toLowerCase();
    
    if (area.contains('front') || area.contains('front-end')) {
      return ['front', 'windshield', 'bumper', 'headlight', 'camera', 'radar'];
    } else if (area.contains('rear') || area.contains('back')) {
      return ['rear', 'bumper', 'trunk', 'backup', 'parking'];
    } else if (area.contains('side') || area.contains('quarter')) {
      return ['side', 'quarter', 'mirror', 'blind spot', 'door'];
    } else if (area.contains('roof') || area.contains('top')) {
      return ['roof', 'headliner', 'sunroof', 'antenna'];
    } else if (area.contains('suspension') || area.contains('alignment')) {
      return ['suspension', 'alignment', 'steering', 'wheel'];
    } else {
      return [impactArea];
    }
  }

  // Insert a new calibration system
  Future<void> insertCalibrationSystem(CalibrationSystem system) async {
    final db = await database;
    await db.insert(
      'calibration_systems',
      system.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Update an existing calibration system
  Future<void> updateCalibrationSystem(CalibrationSystem system) async {
    final db = await database;
    await db.update(
      'calibration_systems',
      system.toMap(),
      where: 'id = ?',
      whereArgs: [system.id],
    );
  }

  // Delete a calibration system
  Future<void> deleteCalibrationSystem(String id) async {
    final db = await database;
    await db.delete(
      'calibration_systems',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Get all calibration systems ordered by vehicle make
  Future<List<CalibrationSystem>> getAllCalibrationSystems() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'calibration_systems',
      orderBy: 'name ASC',
    );
    
    // Sort by extracting vehicle make from system name
    final systems = List.generate(maps.length, (i) => CalibrationSystem.fromMap(maps[i]));
    
    // Extract make from system name and sort
    systems.sort((a, b) {
      final makeA = _extractVehicleMake(a.name);
      final makeB = _extractVehicleMake(b.name);
      
      if (makeA == makeB) {
        return a.name.compareTo(b.name);
      }
      return makeA.compareTo(makeB);
    });
    
    return systems;
  }
  
  String _extractVehicleMake(String name) {
    // Extract vehicle make from system name
    final makes = [
      'acura', 'alfa romeo', 'audi', 'bmw', 'buick', 'cadillac', 'chevrolet', 'chrysler',
      'dodge', 'fiat', 'ford', 'gmc', 'genesis', 'honda', 'hyundai', 'infiniti',
      'jaguar', 'jeep', 'kia', 'land rover', 'lexus', 'lincoln', 'mazda', 'mercedes',
      'mini', 'mitsubishi', 'nissan', 'porsche', 'ram', 'subaru', 'tesla', 'toyota',
      'volkswagen', 'volvo', 'gm',
    ];
    
    final lowerName = name.toLowerCase();
    for (final make in makes) {
      if (lowerName.contains(make)) {
        return make.toUpperCase();
      }
    }
    
    return 'UNKNOWN';
  }
}

