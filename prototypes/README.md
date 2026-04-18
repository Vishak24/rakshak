# Prototypes

This folder contains early prototypes and standalone implementations created during development.

## rakshak_dashboard.html

**Description**: Standalone HTML/CSS/JavaScript prototype of the police dashboard.

**Purpose**: 
- Early design exploration for the web dashboard UI
- Used to validate design concepts before Flutter implementation
- Demonstrates the visual design system and layout

**Technology**:
- Pure HTML/CSS/JavaScript (no framework)
- Leaflet.js for map visualization
- Google Fonts (Inter, Noto Sans Tamil)

**Features**:
- Fixed sidebar navigation
- Live IST clock
- Stats cards (SOS signals, high-risk zones, response time)
- Interactive map with heatmap overlay
- Broadcast alert system
- Export functionality

**Note**: This is a prototype. The production dashboard is built with Flutter (see `lib/presentation/web/`).

---

## How to View

Open `rakshak_dashboard.html` in a web browser:

```bash
open prototypes/rakshak_dashboard.html
# or
python3 -m http.server 8000
# Then visit http://localhost:8000/prototypes/rakshak_dashboard.html
```

---

## Differences from Production Dashboard

| Feature | Prototype (HTML) | Production (Flutter) |
|---------|------------------|----------------------|
| Framework | Vanilla JS | Flutter Web |
| State Management | None | Riverpod |
| API Integration | Mock data | Real AWS Lambda |
| Routing | Single page | GoRouter |
| Responsiveness | Fixed 1440px | Fully responsive |
| Performance | Basic | Optimized |
| Maintainability | Low | High |

The Flutter implementation provides better performance, maintainability, and integration with the mobile app codebase.
