# Rakshak - Screenshots & ML Explainability

This document contains visual documentation of the Rakshak platform, including ML model explainability using SHAP values.

---

## ML Model Explainability (SHAP)

### 1. SHAP Force Plot - Why is this location HIGH RISK at 11 PM?

**Prediction**: `f(x) = 0.651` (High Risk)

**Key Contributing Factors**:
- `reporting_delay_minutes = 45` → **+0.13** (increases risk)
- `area_encoded = 3` → **-0.12** (decreases risk)
- `neighborhood_encoded = 7` → **-0.11** (decreases risk)
- `latitude = 13.083` → **+0.11** (increases risk)
- `pincode = 600001` → **+0.09** (increases risk)
- `response_time_minutes = 18` → **+0.08** (increases risk)
- `signal_count_last_30d = 28` → **-0.04** (decreases risk)
- `is_night = 1` → **+0.02** (increases risk)

**Interpretation**: This location is classified as HIGH RISK primarily due to:
1. Long reporting delays (45 minutes) - victims take longer to report crimes here
2. Slower police response times (18 minutes)
3. Geographic factors (latitude, pincode) indicating a historically high-crime area
4. Nighttime hour (11 PM)

Despite some protective factors (area encoding, neighborhood encoding), the combination of delayed reporting and slow response times pushes the risk score above the HIGH threshold.

---

### 2. SHAP Feature Importance - What Drives Risk Predictions?

**Top Features by Impact**:

1. **latitude** (0.35 mean SHAP value)
   - Highest impact on model predictions
   - Certain latitudes in Chennai correlate strongly with crime hotspots

2. **response_time_minutes** (0.20)
   - Longer police response times → Higher risk
   - Areas with faster response are safer

3. **pincode** (0.20)
   - Postal codes capture neighborhood-level crime patterns
   - Some pincodes have consistently higher crime rates

4. **reporting_delay_minutes** (0.18)
   - Longer delays between crime occurrence and reporting → Higher risk
   - Indicates areas where victims feel unsafe reporting immediately

5. **area_encoded** (0.15)
   - Categorical encoding of Chennai administrative areas
   - Some areas (e.g., industrial zones) have higher crime rates

6. **signal_count_last_30d** (0.12)
   - Recent crime frequency in the area
   - More incidents in past 30 days → Higher current risk

7. **neighborhood_encoded** (0.11)
   - Finer-grained location encoding than area
   - Captures micro-level crime patterns

8. **is_night** (0.05)
   - Nighttime hours (10 PM - 6 AM) have higher risk
   - But less impactful than location and response factors

**Risk Level Color Coding**:
- 🔴 **High Risk** (red bars) - Features pushing prediction toward HIGH
- 🟣 **Medium Risk** (pink bars) - Features pushing toward MEDIUM
- 🟢 **Low Risk** (olive bars) - Features pushing toward LOW

---

### 3. SHAP Dependence Plot - What Drives HIGH RISK Predictions?

**X-axis**: SHAP value (impact on model output)
**Y-axis**: Feature values
**Color**: Feature value magnitude (blue = low, red = high)

**Key Insights**:

1. **latitude**: 
   - Certain latitudes (around 13.08-13.10) have strong positive SHAP values → HIGH RISK
   - Other latitudes (around 13.05-13.07) have negative SHAP values → LOW RISK

2. **response_time_minutes**:
   - Response times > 15 minutes → Positive SHAP (increases risk)
   - Response times < 10 minutes → Negative SHAP (decreases risk)

3. **reporting_delay_minutes**:
   - Delays > 30 minutes → Strong positive SHAP (HIGH RISK)
   - Delays < 15 minutes → Negative SHAP (LOW RISK)

4. **area_encoded**:
   - Some encoded areas (e.g., 3, 5) → Positive SHAP (HIGH RISK)
   - Other areas (e.g., 1, 2) → Negative SHAP (LOW RISK)

5. **signal_count_last_30d**:
   - More than 20 incidents in past 30 days → Positive SHAP
   - Fewer than 10 incidents → Negative SHAP

6. **pincode**:
   - Certain pincodes (600001, 600002) → Positive SHAP (HIGH RISK)
   - Other pincodes (600020, 600028) → Negative SHAP (LOW RISK)

**Interpretation**: The model learns non-linear relationships between features and risk. For example:
- A location at latitude 13.083 with 18-minute response time and 45-minute reporting delay is HIGH RISK
- The same latitude with 8-minute response time and 10-minute reporting delay would be MEDIUM or LOW RISK

---

## Mobile App Screenshots

### Home Screen
- Location card showing current GPS coordinates
- Animated pulsing shield with "ONLINE" status
- "SCAN AREA" button to initiate risk check
- Real-time clock display

### Scan Animation Screen
- 5-second progress bar
- 4-step status updates:
  1. "Analyzing location data..."
  2. "Checking crime patterns..."
  3. "Calculating risk score..."
  4. "Generating report..."

### Result Screen
- Large color-coded risk badge (🟢 Low / 🟠 Moderate / 🔴 High)
- Risk score percentage
- Estimated police response time
- "HOLD FOR SOS" button (3-second hold with circular progress)
- "Report Incident" button

---

## Web Dashboard Screenshots

### Risk Map Page
- **Stats Cards** (top row):
  - 🆘 SOS Signals Today: 142 | ↑18% today
  - 🔴 High Risk Zones: 6 | ↑2
  - ⏱ Avg Response Time: 14.3 min | ↓6%
- **Live Heatmap**: Chennai map with color-coded risk overlay
- **Area Chips**: Dismissible chips for high-risk areas (T. Nagar, Anna Nagar, etc.)
- **Zoom Controls**: +/- buttons for map navigation

### Analytics Page
- **7-Day SOS Trend**: Line chart showing daily SOS signal counts
- **Incident Type Breakdown**: Donut chart (Harassment 45%, Theft 30%, Assault 15%, Other 10%)
- **Risk by Area**: Bar chart comparing risk scores across 6 Chennai zones

### Incidents Page
- **DataTable** with columns:
  - ID | Type | Location | Time | Status | Assigned Officer | Actions
- **Status Chips**: 🟢 Resolved | 🔴 Open
- **Actions**: View Details | Assign Officer | Mark Resolved

### Areas Page
- **6 Chennai Zones**:
  - T. Nagar: Risk Score 87/100 (red bar)
  - Anna Nagar: Risk Score 72/100 (orange bar)
  - Adyar: Risk Score 45/100 (green bar)
  - Velachery: Risk Score 68/100 (orange bar)
  - Mylapore: Risk Score 53/100 (yellow bar)
  - Guindy: Risk Score 61/100 (orange bar)
- **Last Incident Time**: "2 hours ago", "5 hours ago", etc.
- **Enable/Disable Toggles**: Turn monitoring on/off for each area

---

## Design System

### Colors
- **Background**: `#0A0E1A` (dark navy)
- **Surface**: `#111827` (card background)
- **Primary**: `#3B82F6` (blue)
- **Success**: `#4CAF50` (green - Low Risk)
- **Warning**: `#FF9800` (orange - Moderate Risk)
- **Danger**: `#F44336` (red - High Risk)

### Typography
- **Font Family**: Inter (via Google Fonts)
- **Headings**: 600 weight
- **Body**: 400 weight
- **Captions**: 300 weight

### Animations
- **Duration**: 300-600ms
- **Easing**: easeInOut
- **Pulsing Shield**: Continuous scale animation (1.0 → 1.1 → 1.0)
- **SOS Button**: Circular progress indicator during 3-second hold

---

## Technical Implementation Notes

### SHAP Integration
- SHAP values are computed server-side in AWS Lambda
- Returned in API response for transparency
- Displayed in web dashboard for police analysts
- Not shown to end users (to avoid confusion)

### Risk Thresholds
- **Low Risk**: `risk_score < 0.4`
- **Moderate Risk**: `0.4 ≤ risk_score < 0.7`
- **High Risk**: `risk_score ≥ 0.7`

### Heatmap Generation
- Grid-based sampling of Chennai (100x100 grid)
- Each cell gets a risk prediction from ML model
- Color interpolation based on risk scores
- Updated every 5 minutes

---

**Note**: Actual screenshots should be added to this repository in a `screenshots/` folder and linked here using relative paths:

```markdown
![Home Screen](screenshots/mobile-home.png)
![Risk Map](screenshots/web-risk-map.png)
![SHAP Force Plot](screenshots/shap-force-plot.png)
```
