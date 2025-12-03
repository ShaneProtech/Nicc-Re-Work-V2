# Database Update Feature

## Overview
The Database Update feature allows you to easily import ADAS calibration system data from Excel files into the app's database. This makes it simple to keep your calibration data synchronized with your company's NICC database.

## How to Use

### Step 1: Prepare Your Excel Files
Your Excel files should follow this format:

**First Row (Header)**: Column names that describe the data
**Subsequent Rows**: Data for each ADAS system

#### Supported Column Names
The import service recognizes various column name variations:

| Field | Recognized Column Names |
|-------|------------------------|
| System Name | "System", "Name", "ADAS" |
| Description | "Description", "Desc", "Calibration Type" |
| Category | "Category", "Type", "Component", "Parent" |
| Time | "Time", "Duration", "Estimated Time" |
| Cost | "Cost", "Price", "Estimated Cost" |
| Pre-Qualifications | "Pre-Qualification", "Prequalification", "Requirement" |
| Hyperlink | "Hyperlink", "Link", "URL" |
| Keywords | "Keyword", "Search", "OEM" |
| Required For | "Required", "Trigger" |
| Equipment | "Equipment", "Tool" |
| Priority | "Priority" |

#### Example Excel Structure

```
| System Name | Description | Category | Pre-Qualifications | Hyperlink | Keywords |
|-------------|-------------|----------|-------------------|-----------|----------|
| ACC | Adaptive Cruise Control | Radar | Alignment required;Full tank | https://... | ACC,cruise,radar |
| AEB | Auto Emergency Braking | Safety | Alignment;Cargo empty | https://... | AEB,braking,collision |
| LKA | Lane Keep Assist | Camera | Windshield clear;Full tank | https://... | LKA,lane,LKAS |
```

### Step 2: Access the Update Database Screen
1. Open the NICC Calibration App
2. From the home screen, click the **"Update Database"** button (green card with cloud upload icon)

### Step 3: Select Your Data Source
You have two options:

#### Option A: Select a Folder
- Click "Select Folder"
- Browse to a folder containing your Excel files
- The app will import **all** `.xlsx` and `.xls` files in that folder

#### Option B: Select a Single File
- Click "Select File"
- Browse to and select a single `.xlsx` or `.xls` file
- Only that file will be imported

### Step 4: Import the Data
1. After selecting your folder or file, the path will be displayed
2. Click the **"Import Data"** button
3. Wait for the import process to complete
4. You'll see a success/failure message with details:
   - Number of records imported
   - Number of files processed
   - Details for each file processed

## Data Processing

### How the Import Works

1. **File Discovery**: The app finds all Excel files in the selected location
2. **Header Analysis**: The first row of each sheet is analyzed to identify column types
3. **ADAS Detection**: Sheets are checked to see if they contain ADAS system data
4. **Data Parsing**: Each row is converted into a `CalibrationSystem` object
5. **Database Update**: Systems are either inserted (new) or updated (existing)

### Smart Column Mapping
The import service uses intelligent column mapping:
- Recognizes common variations of column names
- Handles multiple delimiters (commas, semicolons, pipes, newlines)
- Generates IDs automatically from system names
- Determines appropriate icons based on categories

### List Fields
For fields that contain multiple values (like keywords or pre-qualifications), you can use various delimiters:
- **Semicolon**: `item1;item2;item3`
- **Comma**: `item1,item2,item3`
- **Pipe**: `item1|item2|item3`
- **Newline**: Multi-line cells are supported

### Keyword Generation
The import service automatically generates comprehensive keywords from:
- Explicit keyword columns
- OEM name columns  
- System name variations
- Individual words from the system name

### Insert vs Update
- If a system with the same ID already exists, it will be **updated**
- If a system is new, it will be **inserted**
- System IDs are generated from the system name (lowercase, alphanumeric only)

## Example Workflow

### Syncing with NICC Database

1. **Export from NICC**: Export your ADAS systems to Excel
   - Include columns for system names, descriptions, pre-qualifications, SharePoint links, etc.
   
2. **Organize Files**: Put all Excel files in a single folder
   - Example: `C:\NICC Data\ADAS Systems\`

3. **Import to App**:
   - Open app → Update Database
   - Select Folder → Choose `C:\NICC Data\ADAS Systems\`
   - Click Import Data
   - Wait for completion

4. **Verify Import**:
   - Go to Systems Library
   - Check that systems have been updated
   - Verify pre-qualifications and hyperlinks are correct

## Troubleshooting

### No Records Imported
**Possible Causes:**
- Excel files don't contain recognizable ADAS column names
- First row is not a proper header
- All rows are empty

**Solution:**
- Ensure first row contains column headers like "System", "Name", "Keyword", etc.
- Make sure data rows aren't empty

### Missing Data Fields
**Possible Causes:**
- Column names don't match recognized patterns
- Cells are empty

**Solution:**
- Use column names from the "Supported Column Names" table above
- Ensure cells contain data

### Import Errors
**Possible Causes:**
- File permissions issues
- Corrupted Excel files
- Invalid file format

**Solution:**
- Ensure the app has read permissions for the folder/files
- Try opening the Excel file in Excel to verify it's not corrupted
- Make sure files have `.xlsx` or `.xls` extension

## Technical Details

### File Formats Supported
- `.xlsx` (Excel 2007+)
- `.xls` (Excel 97-2003)

### Database Schema
The import updates the `calibration_systems` table with these fields:
- `id` (TEXT) - Auto-generated from system name
- `name` (TEXT) - System name
- `description` (TEXT) - Description or calibration type
- `category` (TEXT) - System category
- `required_for` (TEXT) - Comma-separated triggers
- `estimated_time` (TEXT) - Time estimate
- `estimated_cost` (TEXT) - Cost estimate
- `equipment_needed` (TEXT) - Comma-separated equipment list
- `icon_name` (TEXT) - Icon identifier
- `priority` (INTEGER) - 1 (high), 2 (medium), 3 (low)
- `pre_qualifications` (TEXT) - Comma-separated pre-qual list
- `hyperlink` (TEXT) - SharePoint or documentation URL
- `adas_keywords` (TEXT) - Comma-separated search keywords

### Performance
- Imports are processed asynchronously
- Large files (1000+ rows) may take several seconds
- Progress is shown via a loading overlay

## Best Practices

1. **Regular Updates**: Import updated data whenever your NICC database changes
2. **Backup First**: Consider backing up your database before large imports
3. **Test with Small Files**: Start with a single file to verify format compatibility
4. **Consistent Headers**: Use the same column names across all your Excel files
5. **Clean Data**: Remove empty rows and ensure data quality before importing

## Future Enhancements

Potential improvements for this feature:
- Progress bar showing percentage complete
- Preview mode to see data before importing
- Export current database to Excel
- Selective import (choose which systems to import)
- Import history/log
- Undo last import
- Validation warnings before import

---

**Feature Added**: November 2024  
**Version**: 2.1  
**Compatible with**: Excel 2007+ (.xlsx), Excel 97-2003 (.xls)


