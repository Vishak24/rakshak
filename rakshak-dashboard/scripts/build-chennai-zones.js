import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

const PINCODE_NAMES = {
  "600001":"Park Town","600002":"Sowcarpet","600003":"Royapuram",
  "600004":"Chintadripet","600005":"Royapettah","600006":"Triplicane",
  "600007":"Egmore","600008":"Nungambakkam","600009":"Kilpauk",
  "600010":"Aminjikarai","600011":"Kodambakkam","600012":"Ashok Nagar",
  "600013":"Tiruvottiyur","600014":"Perambur","600015":"Pattabiram",
  "600017":"T. Nagar","600018":"Abiramapuram","600019":"Vyasarpadi",
  "600020":"Saidapet","600024":"Pallavaram","600028":"Adyar",
  "600029":"Besant Nagar","600032":"Alwarpet","600033":"Valasaravakkam",
  "600034":"Anna Nagar West","600035":"Anna Nagar East","600036":"Arumbakkam",
  "600040":"Nanganallur","600042":"Velachery","600044":"Perungudi",
  "600045":"Thoraipakkam","600050":"Mogappair","600053":"Villivakkam",
  "600056":"Kolathur","600058":"Royapuram","600061":"Mugalivakkam",
  "600064":"Medavakkam","600073":"Selaiyur","600078":"Ambattur",
  "600081":"Manali","600082":"Puzhal","600083":"Madhavaram",
  "600099":"Kundrathur","600118":"Perumbakkam"
};

const RISK = {
  "600001":"HIGH","600006":"HIGH","600007":"HIGH","600058":"HIGH","600081":"HIGH",
  "600002":"MEDIUM","600003":"MEDIUM","600004":"MEDIUM","600005":"MEDIUM",
  "600008":"MEDIUM","600009":"MEDIUM","600010":"MEDIUM","600011":"MEDIUM",
  "600012":"MEDIUM","600013":"MEDIUM",
};

// Accurate centroids (lat, lon) for the 12 pincodes NOT in the KML
const MISSING_CENTROIDS = {
  "600019": [13.1021, 80.2498],  // Vyasarpadi
  "600029": [12.9992, 80.2703],  // Besant Nagar
  "600044": [12.9568, 80.2440],  // Perungudi
  "600045": [12.9437, 80.2356],  // Thoraipakkam
  "600050": [13.0837, 80.1743],  // Mogappair
  "600053": [13.1176, 80.2175],  // Villivakkam
  "600056": [13.1118, 80.2296],  // Kolathur
  "600058": [13.1127, 80.2966],  // Royapuram (Harbour)
  "600064": [12.9307, 80.1978],  // Medavakkam
  "600073": [12.9057, 80.1612],  // Selaiyur
  "600099": [13.0308, 80.1050],  // Kundrathur
  "600118": [12.9029, 80.2148],  // Perumbakkam
};
const APPROX_RADIUS_DEG = 0.022; // ~2.4 km

function hexPolygon(lat, lon, r) {
  const pts = [];
  for (let i = 0; i <= 6; i++) {
    const angle = (Math.PI / 3) * i;
    pts.push([lon + r * Math.cos(angle), lat + r * 0.85 * Math.sin(angle)]);
  }
  return pts;
}

// --- Parse KML ---
const kmlPath = path.join(__dirname, '../public/Final_Chennai_Pincode.kml');
const kml = fs.readFileSync(kmlPath, 'utf8');

const TARGET = new Set(Object.keys(PINCODE_NAMES));
const features = [];
const found = new Set();

const pmRe = /<Placemark[\s\S]*?<\/Placemark>/g;
let pm;
while ((pm = pmRe.exec(kml)) !== null) {
  const block = pm[0];
  const pcM = block.match(/<SimpleData name="Pincode">(.*?)<\/SimpleData>/);
  if (!pcM) continue;
  const pincode = pcM[1].trim();
  if (!TARGET.has(pincode) || found.has(pincode)) continue;

  const coordsM = block.match(/<outerBoundaryIs>[\s\S]*?<coordinates>([\s\S]*?)<\/coordinates>/);
  if (!coordsM) continue;

  const coords = coordsM[1].trim().split(/\s+/)
    .filter(c => c.includes(','))
    .map(c => {
      const [lng, lat] = c.split(',').map(Number);
      return [lng, lat];
    })
    .filter(p => !isNaN(p[0]) && !isNaN(p[1]));

  if (coords.length < 3) continue;
  if (coords[0][0] !== coords[coords.length - 1][0] || coords[0][1] !== coords[coords.length - 1][1]) {
    coords.push(coords[0]);
  }

  found.add(pincode);
  features.push({
    type: "Feature",
    properties: {
      pincode,
      name: PINCODE_NAMES[pincode] || pincode,
      risk_level: RISK[pincode] || "LOW",
      source: "india_post_kml"
    },
    geometry: { type: "Polygon", coordinates: [coords] }
  });
}

console.log(`KML: extracted ${found.size} of ${TARGET.size} pincodes`);

// --- Add missing pincodes as hex approximations ---
let approxCount = 0;
for (const pincode of TARGET) {
  if (found.has(pincode)) continue;
  const centroid = MISSING_CENTROIDS[pincode];
  if (!centroid) { console.log(`  ⚠️  No centroid for ${pincode}`); continue; }
  const [lat, lon] = centroid;
  const coords = hexPolygon(lat, lon, APPROX_RADIUS_DEG);
  features.push({
    type: "Feature",
    properties: {
      pincode,
      name: PINCODE_NAMES[pincode],
      risk_level: RISK[pincode] || "LOW",
      source: "approximate"
    },
    geometry: { type: "Polygon", coordinates: [coords] }
  });
  approxCount++;
  console.log(`  ≈ ${pincode} ${PINCODE_NAMES[pincode]} (hex approximation)`);
}

// Sort by pincode
features.sort((a, b) => a.properties.pincode.localeCompare(b.properties.pincode));

const geojson = { type: "FeatureCollection", features };
const outPath = path.join(__dirname, '../public/chennai-zones-osm.geojson');
fs.writeFileSync(outPath, JSON.stringify(geojson, null, 2));

console.log(`\nTotal: ${features.length} zones`);
console.log(`  - ${found.size} from India Post KML (no coordinate offset)`);
console.log(`  - ${approxCount} hexagonal approximations`);
console.log(`Saved to public/chennai-zones-osm.geojson`);
