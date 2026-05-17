/**
 * Extracts and merges accurate boundaries for 12 hexagonal-approximated Chennai pincodes.
 * Sources: datameet/PincodeBoundary (7), OSM Ward 93 (1), 16-pt circle (4).
 */

const fs = require('fs');
const https = require('https');
const http = require('http');

const MISSING = ["600019","600029","600044","600045","600050","600053","600056","600058","600064","600073","600099","600118"];

const NAMES = {
  "600019":"Vyasarpadi","600029":"Besant Nagar","600044":"Perungudi",
  "600045":"Thoraipakkam","600050":"Mogappair","600053":"Villivakkam",
  "600056":"Kolathur","600058":"Royapuram","600064":"Medavakkam",
  "600073":"Selaiyur","600099":"Kundrathur","600118":"Perumbakkam"
};

// datameet pin → our pin (matched by geographic name)
const DATAMEET_MAP = {
  "600039": "600019",  // VYASARPADI SO → Vyasarpadi
  "600090": "600029",  // BESANT NAGAR  → Besant Nagar
  "600096": "600044",  // PERUNGUDI     → Perungudi
  "600097": "600045",  // OGGIAM THORAIPAKKAM → Thoraipakkam
  "600049": "600053",  // VILLIVAKKAM   → Villivakkam
  "600099": "600056",  // Kolathur      → Kolathur
  "600013": "600058",  // ROYAPURAM SO  → Royapuram
};

function circlePolygon(lat, lon, radiusKm, n = 16) {
  const latR = radiusKm / 111.32;
  const lonR = radiusKm / (111.32 * Math.cos((lat * Math.PI) / 180));
  const coords = [];
  for (let i = 0; i < n; i++) {
    const angle = (2 * Math.PI * i) / n;
    coords.push([
      parseFloat((lon + lonR * Math.cos(angle)).toFixed(6)),
      parseFloat((lat + latR * Math.sin(angle)).toFixed(6)),
    ]);
  }
  coords.push(coords[0]);
  return { type: "Polygon", coordinates: [coords] };
}

// 16-pt circle fallbacks for areas not in datameet or OSM ward data
const CIRCLE_FALLBACKS = {
  "600064": { lat: 12.9230, lon: 80.1883, r: 1.5 },
  "600073": { lat: 12.9187, lon: 80.1311, r: 1.5 },
  "600099": { lat: 12.9958, lon: 80.0973, r: 1.5 },
  "600118": { lat: 12.9050, lon: 80.1969, r: 1.5 },
};

// OSM Ward 93 polygon for Mogappair (fetched once, embedded here to avoid re-fetch)
const MOGAPPAIR_WARD93_URL = "https://overpass-api.de/api/interpreter";
const MOGAPPAIR_QUERY = `[out:json][timeout:30];relation(7888171);out geom;`;

async function fetchOverpass(query) {
  return new Promise((resolve, reject) => {
    const body = "data=" + encodeURIComponent(query);
    const opts = {
      hostname: "overpass-api.de",
      path: "/api/interpreter",
      method: "POST",
      headers: { "Content-Type": "application/x-www-form-urlencoded", "Content-Length": Buffer.byteLength(body) }
    };
    const req = https.request(opts, res => {
      let d = '';
      res.on('data', c => d += c);
      res.on('end', () => resolve(JSON.parse(d)));
    });
    req.on('error', reject);
    req.write(body);
    req.end();
  });
}

function relationToPolygon(rel) {
  const outerWays = rel.members.filter(m => m.type === 'way' && (m.role === 'outer' || m.role === ''));
  const coords = [];
  for (const way of outerWays) {
    const pts = (way.geometry || []).map(g => [g.lon, g.lat]);
    if (coords.length > 0 && pts.length > 0) {
      const last = coords[coords.length - 1];
      if (last[0] === pts[0][0] && last[1] === pts[0][1]) {
        coords.push(...pts.slice(1));
      } else {
        coords.push(...pts);
      }
    } else {
      coords.push(...pts);
    }
  }
  if (coords.length > 0 && (coords[0][0] !== coords[coords.length-1][0] || coords[0][1] !== coords[coords.length-1][1])) {
    coords.push(coords[0]);
  }
  return { type: "Polygon", coordinates: [coords] };
}

async function main() {
  const features = [];

  // ── Step 1: Extract from datameet Chennai boundary file ──
  const dmPath = '/tmp/india_pincodes.geojson';
  if (!fs.existsSync(dmPath)) {
    console.error('❌ Missing /tmp/india_pincodes.geojson — run the download step first');
    process.exit(1);
  }
  const dm = JSON.parse(fs.readFileSync(dmPath));
  for (const feat of dm.features) {
    const dmPin = String(feat.properties.pin || '');
    const ourPin = DATAMEET_MAP[dmPin];
    if (ourPin) {
      features.push({
        type: "Feature",
        geometry: feat.geometry,
        properties: { pincode: ourPin, name: NAMES[ourPin], risk_score: 50, risk_level: "MEDIUM", source: `datameet:${dmPin}` }
      });
      console.log(`✅ ${ourPin} (${NAMES[ourPin]}) — datameet:${dmPin} (${feat.properties.area_name || feat.properties.name})`);
    }
  }

  // ── Step 2: OSM Ward 93 for Mogappair ──
  console.log('\nFetching OSM Ward 93 for Mogappair...');
  try {
    const osm = await fetchOverpass(MOGAPPAIR_QUERY);
    const rel = osm.elements.find(e => e.type === 'relation');
    if (rel) {
      const geo = relationToPolygon(rel);
      features.push({
        type: "Feature",
        geometry: geo,
        properties: { pincode: "600050", name: "Mogappair", risk_score: 50, risk_level: "MEDIUM", source: "osm:ward93" }
      });
      console.log(`✅ 600050 (Mogappair) — OSM Ward 93 (${geo.coordinates[0].length} pts)`);
    } else {
      throw new Error('No relation found');
    }
  } catch (e) {
    console.log(`⚠️  Mogappair OSM fetch failed (${e.message}), using 16-pt circle`);
    const { lat, lon, r } = CIRCLE_FALLBACKS["600050"] || { lat: 13.0835, lon: 80.1840, r: 1.5 };
    features.push({
      type: "Feature",
      geometry: circlePolygon(lat, lon, r),
      properties: { pincode: "600050", name: "Mogappair", risk_score: 50, risk_level: "MEDIUM", source: "approx:circle" }
    });
  }

  // ── Step 3: 16-point circle approximations for remaining 4 ──
  for (const [pin, { lat, lon, r }] of Object.entries(CIRCLE_FALLBACKS)) {
    features.push({
      type: "Feature",
      geometry: circlePolygon(lat, lon, r),
      properties: { pincode: pin, name: NAMES[pin], risk_score: 50, risk_level: "MEDIUM", source: "approx:circle" }
    });
    console.log(`✅ ${pin} (${NAMES[pin]}) — 16-pt circle at ${lat},${lon}`);
  }

  const out = { type: "FeatureCollection", features };
  fs.writeFileSync('rakshak-dashboard/scripts/missing-zones.geojson', JSON.stringify(out, null, 2));
  console.log(`\nExtracted ${features.length}/12 missing zones → missing-zones.geojson`);

  const srcCounts = {};
  for (const f of features) {
    const s = f.properties.source.split(':')[0];
    srcCounts[s] = (srcCounts[s] || 0) + 1;
  }
  console.log('Sources:', srcCounts);
}

main().catch(e => { console.error(e); process.exit(1); });
