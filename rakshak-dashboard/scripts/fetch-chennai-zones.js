import fs from 'fs';

const PINCODES = [
  "600001","600002","600003","600004","600005","600006","600007","600008",
  "600009","600010","600011","600012","600013","600014","600015","600017",
  "600018","600019","600020","600024","600028","600029","600032","600033",
  "600034","600035","600036","600040","600042","600044","600045","600050",
  "600053","600056","600058","600061","600064","600073","600078","600081",
  "600082","600083","600099","600118"
];

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

async function fetchPincodePolygon(pincode) {
  const query = `
    [out:json];
    relation["boundary"="postal_code"]["postal_code"="${pincode}"]["addr:country"="IN"];
    out geom;
  `;
  const url = 'https://overpass-api.de/api/interpreter';
  const resp = await fetch(url, {
    method: 'POST',
    body: 'data=' + encodeURIComponent(query),
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' }
  });
  const json = await resp.json();
  return json.elements;
}

function buildPolygonFromOSM(element) {
  if (!element.members) return null;
  const outer = element.members.find(m => m.role === 'outer' && m.geometry);
  if (!outer) return null;
  const coords = outer.geometry.map(p => [p.lon, p.lat]);
  if (coords[0] !== coords[coords.length-1]) coords.push(coords[0]);
  return coords;
}

async function main() {
  const features = [];
  const missing = [];

  for (const pincode of PINCODES) {
    console.log(`Fetching ${pincode} - ${PINCODE_NAMES[pincode]}...`);
    try {
      await new Promise(r => setTimeout(r, 1000)); // rate limit
      const elements = await fetchPincodePolygon(pincode);
      if (elements && elements.length > 0) {
        const coords = buildPolygonFromOSM(elements[0]);
        if (coords) {
          features.push({
            type: "Feature",
            properties: {
              pincode,
              name: PINCODE_NAMES[pincode],
              risk_score: 50,
              risk_level: "MEDIUM"
            },
            geometry: { type: "Polygon", coordinates: [coords] }
          });
          console.log(`  ✅ ${pincode} done (${coords.length} points)`);
        } else {
          console.log(`  ⚠️  ${pincode} no outer geometry`);
          missing.push(pincode);
        }
      } else {
        console.log(`  ❌ ${pincode} not found in OSM`);
        missing.push(pincode);
      }
    } catch(e) {
      console.log(`  ❌ ${pincode} error: ${e.message}`);
      missing.push(pincode);
    }
  }

  const geojson = { type: "FeatureCollection", features };
  fs.writeFileSync(
    'public/chennai-zones-osm.geojson',
    JSON.stringify(geojson, null, 2)
  );
  console.log(`\nDone. ${features.length}/${PINCODES.length} zones fetched from OSM.`);
  if (missing.length > 0) {
    console.log(`Missing pincodes: ${missing.join(', ')}`);
  }
  console.log('Saved to public/chennai-zones-osm.geojson');
}

main();
