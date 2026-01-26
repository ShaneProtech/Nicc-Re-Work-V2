# Excel Import - Quick Start Guide

## 🚀 Quick Start (3 Steps)

### 1. Create Your Excel File
Open Excel and create a file with this structure:

**Example (minimum required):**
```
| System Name                    | Description              | Keywords               |
|--------------------------------|--------------------------|------------------------|
| Adaptive Cruise Control        | ACC Calibration          | ACC,cruise,radar       |
| Lane Keep Assist               | LKA System Calibration   | LKA,lane,LKAS,camera   |
```

**Example (with all fields):**
```
| System Name | Description | Category | Pre-Qualifications | Hyperlink | Keywords | Required For | Time | Cost |
|-------------|-------------|----------|-------------------|-----------|----------|--------------|------|------|
| ACC | Static/Dynamic ACC | Radar | Alignment;Full tank | https://sharepoint... | ACC,cruise | bumper,radar | 1-2 hours | $150-$300 |
```

### 2. Import to App
1. Open **NICC Calibration App**
2. Click **"Update Database"** (green card on home screen)
3. Click **"Select Folder"** or **"Select File"**
4. Browse to your Excel file(s)
5. Click **"Import Data"**
6. Wait for success message

### 3. Verify
1. Go to **"Systems Library"**
2. Find your imported system
3. Expand it to verify data is correct

---

## 📋 Excel Format Reference

### Required Columns
At minimum, your Excel file needs:
- **System Name** - Name of the ADAS system

### Recommended Columns
For best results, include:
- **Description** - What the system does
- **Keywords** - Search terms (semicolon or comma-separated)
- **Pre-Qualifications** - Requirements (semicolon or comma-separated)
- **Hyperlink** - Link to calibration guide

### Optional Columns
- Category, Type, Component
- Time, Duration, Estimated Time
- Cost, Price, Estimated Cost
- Required, Trigger, Required For
- Equipment, Tool, Equipment Needed
- Priority (1=high, 2=medium, 3=low)

### Multiple Values (Lists)
Use these delimiters for list fields:
- **Semicolon**: `value1;value2;value3` ✅ Recommended
- **Comma**: `value1,value2,value3` ✅ Works well
- **Pipe**: `value1|value2|value3` ✅ Supported
- **Newline**: Use Alt+Enter in Excel cell ✅ Supported

---

## 💡 Pro Tips

1. **Multiple Files**: Put all your Excel files in one folder and use "Select Folder"
2. **Keep Headers Simple**: Use "Name" instead of "ADAS_System_Name_V2"
3. **Test First**: Import a single file with 2-3 systems to test format
4. **Keywords Matter**: More keywords = better search results (add OEM names, abbreviations)
5. **Pre-Quals Format**: Separate with semicolons for best display

---

## ⚠️ Common Issues & Fixes

| Issue | Fix |
|-------|-----|
| "No Excel files found" | Make sure files have `.xlsx` or `.xls` extension |
| "No records imported" | Check that first row has column headers like "Name", "System", etc. |
| Missing pre-qualifications | Make sure column is named "Pre-Qualification" or "Requirement" |
| Links not working | Column should be named "Hyperlink", "Link", or "URL" |
| Keywords not detected | Column should be named "Keyword", "Search", or "OEM" |

---

## 📁 File Path Examples

**Windows:**
- Folder: `C:\Users\YourName\Documents\NICC Data\`
- File: `C:\Users\YourName\Documents\ADAS_Systems.xlsx`

**Supported Extensions:**
- `.xlsx` ✅ (Excel 2007+)
- `.xls` ✅ (Excel 97-2003)
- `.csv` ❌ (Not supported - save as .xlsx instead)

---

## 🎯 Example Templates

### Template 1: Basic Import
```excel
System Name          | Keywords
---------------------|------------------
ACC                  | ACC,cruise,radar
AEB                  | AEB,braking,emergency
LKA                  | LKA,lane,LKAS
```

### Template 2: Complete Import
```excel
System Name | Description | Category | Pre-Qualifications | Hyperlink | Keywords
------------|-------------|----------|-------------------|-----------|----------
ACC | Adaptive Cruise Control | Radar | Alignment required;Full fuel tank;Cargo empty | https://sharepoint.com/acc | ACC,adaptive cruise,cruise control,front radar
AEB | Automatic Emergency Braking | Safety | Alignment required;Full fuel tank | https://sharepoint.com/aeb | AEB,emergency braking,collision mitigation,CMBS
```

---

## 🔄 Update Existing Systems

The import will **update** existing systems if they have the same name:
- Old: "ACC" → New: "ACC" ✅ **Updates existing**
- Old: "Adaptive Cruise Control" → New: "ACC" ❌ **Creates new** (different name)

**Tip**: Keep system names consistent for updates!

---

## ✅ Success Checklist

After importing, verify:
- [ ] System appears in Systems Library
- [ ] Name is correct
- [ ] Description is showing
- [ ] Pre-Qualifications are visible (green section)
- [ ] Hyperlink button is present (blue section)
- [ ] Keywords work in search
- [ ] All expected systems imported (check count in result message)

---

**Need Help?** Check `DATABASE_UPDATE_FEATURE.md` for detailed documentation.





