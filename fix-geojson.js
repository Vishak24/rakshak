const fs = require('fs')
const path = require('path')

const KML_FILE = path.join(__dirname, 'rakshak-dashboard/public/Final_Chennai_Pincode.kml')
const OUT_FILE = path.join(__dirname, 'rakshak-dashboard/public/chennai-zones-fixed.geojson')

// Offsets derived from Tondiarpet S.O. (600081) first vertex vs known centre
const LAT_OFFSET = -0.017923
const LNG_OFFSET = -0.006134

const kmlText = fs.readFileSync(KML_FILE, 'utf8')

// Minimal XML parser using regex — sufficient for this well-structured KML
function getTagContent(text, tag) {
  const re = new RegExp(`<${tag}[^>]*>([\\s\\S]*?)<\\/${tag}>`, 'g')
  const results = []
  let m
  while ((m = re.exec(text)) !== null) results.push(m[1])
  return results
}

function getAttrContent(text, tag, attr) {
  const re = new RegExp(`<${tag}[^>]*name=["']${attr}["'][^>]*>([\\s\\S]*?)<\\/${tag}>`)
  const m = re.exec(text)
  return m ? m[1].trim() : null
}

const placemarks = []
const pmRe = /<Placemark[\s\S]*?<\/Placemark>/g
let pm
while ((pm = pmRe.exec(kmlText)) !== null) {
  const block = pm[0]

  // Extract pincode from SimpleData name="Pincode"
  const pincodeMatch = block.match(/<SimpleData name="Pincode">(.*?)<\/SimpleData>/)
  const pincode = pincodeMatch ? pincodeMatch[1].trim() : null

  const officeMatch = block.match(/<SimpleData name="Office_Name">(.*?)<\/SimpleData>/)
  const officeName = officeMatch ? officeMatch[1].trim() : null

  // Extract outer boundary coordinates (skip holes for simplicity)
  const coordsMatch = block.match(/<outerBoundaryIs>[\s\S]*?<coordinates>([\s\S]*?)<\/coordinates>/)
  if (!coordsMatch || !pincode) continue

  const rawCoords = coordsMatch[1].trim().split(/\s+/).filter(c => c.includes(','))
  const coords = rawCoords.map(c => {
    const parts = c.split(',')
    const lng = parseFloat(parts[0]) + LNG_OFFSET
    const lat = parseFloat(parts[1]) + LAT_OFFSET
    return [lng, lat]
  }).filter(p => !isNaN(p[0]) && !isNaN(p[1]))

  if (coords.length < 3) continue

  // GeoJSON polygon rings must close
  if (coords[0][0] !== coords[coords.length - 1][0] || coords[0][1] !== coords[coords.length - 1][1]) {
    coords.push(coords[0])
  }

  placemarks.push({
    type: 'Feature',
    properties: { pincode, officeName },
    geometry: { type: 'Polygon', coordinates: [coords] },
  })
}

const geojson = { type: 'FeatureCollection', features: placemarks }
fs.writeFileSync(OUT_FILE, JSON.stringify(geojson))

console.log(`Converted ${placemarks.length} polygons`)
console.log(`LAT_OFFSET applied: ${LAT_OFFSET}`)
console.log(`LNG_OFFSET applied: ${LNG_OFFSET}`)
console.log(`Output: ${OUT_FILE}`)
