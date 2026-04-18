# Data Files

This folder contains data files used by the Rakshak application.

## chennai-pincodes.kml

**Description**: KML (Keyhole Markup Language) file containing Chennai pincode boundaries and metadata.

**Source**: All India Pincode Boundary dataset

**Usage**: 
- Used for mapping user locations to specific Chennai pincodes
- Helps encode geographic areas for ML model input
- Contains pincode polygons for visualization on maps

**Schema**:
- `Pincode`: 6-digit postal code (e.g., 600001)
- `Office_Name`: Post office name (e.g., "Chennai G.P.O.")
- `Division`: Postal division
- `Region`: Geographic region (e.g., "Chennai City")
- `Circle`: State circle (e.g., "Tamilnadu")

**Format**: XML-based KML 2.2 standard

**Coverage**: All Chennai pincodes (600001 - 600119)

---

## Future Data Files

Additional data files that may be added:
- `chennai-crime-data.csv` - Historical crime records (if publicly available)
- `police-stations.json` - Chennai police station locations and contact info
- `safe-zones.geojson` - Designated safe zones (hospitals, police stations, etc.)
