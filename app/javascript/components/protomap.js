import * as maplibregl from "maplibre-gl"
import layers from 'protomaps-themes-base'

export default class Protomap {
  static onload() {
    findAll('[data-show-map]').forEach(el => {
      this.show(data(el))
    })
  }

  static show(data) {

  const map = new maplibregl.Map({
    container: 'map',
    style: {
      version:8,
      glyphs:'https://cdn.protomaps.com/fonts/pbf/{fontstack}/{range}.pbf',
      sources: {
          "protomaps": {
              type: "vector",
              tiles: ["https://api.protomaps.com/tiles/v2/{z}/{x}/{y}.pbf?key=cfec896832ad2a2a"],
              minzoom: 0,
              maxzoom: 6,
              attribution: '<a href="https://protomaps.com">Protomaps</a> © <a href="https://openstreetmap.org">OpenStreetMap</a>'
          }
      },
      zoom: 0,
      layers: layers("protomaps","grayscale")
    }
  });

  // Add zoom and rotation controls to the map.
  map.addControl(new maplibregl.NavigationControl());

  map.on('load', async () => {
    const minLat = parseFloat(data.countryMinLat);
    const minLong = parseFloat(data.countryMinLong);
    const maxLat = parseFloat(data.countryMaxLat);
    const maxLong = parseFloat(data.countryMaxLong);
    map.setLayoutProperty('places_country', 'text-field', [
      'get',
      `name:en`
      ]);
    map.fitBounds([minLong, minLat, maxLong, maxLat], { padding: 30 });
  });
  }
}
