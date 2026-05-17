const fs = require('fs');

const REPLACING = [
  "600019","600029","600044","600045","600050","600053",
  "600056","600058","600064","600073","600099","600118"
];

const main_path = 'rakshak-dashboard/public/chennai-zones-osm.geojson';
const missing_path = 'rakshak-dashboard/scripts/missing-zones.geojson';

const main = JSON.parse(fs.readFileSync(main_path));
const missing = JSON.parse(fs.readFileSync(missing_path));

const kept = main.features.filter(f => !REPLACING.includes(String(f.properties.pincode)));
const merged = { type: "FeatureCollection", features: [...kept, ...missing.features] };

fs.writeFileSync(main_path, JSON.stringify(merged, null, 2));

console.log(`Total zones: ${merged.features.length}/44`);
console.log('Replaced hexagonal approximations with real/improved boundaries');

// Report sources
const sources = {};
for (const f of missing.features) {
  const src = (f.properties.source || 'unknown').split(':')[0];
  sources[src] = (sources[src] || 0) + 1;
}
console.log('Boundary sources:', sources);

// Check for any remaining hexagons (7-point polygons)
const hexagons = merged.features.filter(f => {
  const geo = f.geometry;
  if (geo.type === 'Polygon') return geo.coordinates[0].length === 7;
  return false;
});
if (hexagons.length === 0) {
  console.log('✅ No hexagonal approximations remaining');
} else {
  console.log('⚠️  Still hexagonal:', hexagons.map(f => f.properties.pincode).join(', '));
}
