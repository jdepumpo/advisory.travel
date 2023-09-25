import * as maplibregl from "maplibre-gl"
import layers from 'protomaps-themes-base'

export default class Protomap {
  static onload() {
    findAll('[data-show-map]').forEach(el => {
      this.show(data(el))
    })
  }

  //create map
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

  function mapToEnglish() {
    map.setLayoutProperty('places_country', 'text-field', [
      'get',
      `name:en`
      ]);
  }

  // If map is on country#show, zoom to country
  function countryShowMap() {
    const minLat = parseFloat(data.countryMinLat);
    const minLong = parseFloat(data.countryMinLong);
    const maxLat = parseFloat(data.countryMaxLat);
    const maxLong = parseFloat(data.countryMaxLong);
    map.setLayoutProperty('places_country', 'text-field', [
      'get',
      `name:en`
      ]);
    map.fitBounds([minLong, minLat, maxLong, maxLat], { padding: 30 });
  }

  // if world map,
  function worldAdvisoryMap() {
    const countryGeoData = data.countryGeoData;
    map.addSource('countries', {
      'type': 'geojson',
      'data':
          '/map_data/countries.geojson'
    });
    console.log("geojson loaded")
    // The feature-state dependent fill-opacity expression will render the hover effect
    // when a feature's hover state is set to true.
    map.addLayer({
        'id': 'state-fills',
        'type': 'fill',
        'source': 'countries',
        'layout': {},
        'paint': {
            'fill-color': '#627BC1',
            'fill-opacity': [
                'case',
                ['boolean', ['feature-state', 'hover'], false],
                1,
                0.5
            ]
        }
    });

    map.addLayer({
        'id': 'state-borders',
        'type': 'line',
        'source': 'countries',
        'layout': {},
        'paint': {
            'line-color': '#627BC1',
            'line-width': 2
        }
    });

    // When the user moves their mouse over the state-fill layer, we'll update the
    // feature state for the feature under the mouse.
    map.on('mousemove', 'state-fills', (e) => {
        if (e.features.length > 0) {
            if (hoveredStateId) {
                map.setFeatureState(
                    {source: 'countries', id: hoveredStateId},
                    {hover: false}
                );
            }
            hoveredStateId = e.features[0].properties["ISO_A2"];
            console.log(e.features["properties"]["ISO_A2"]);
            map.setFeatureState(
                {source: 'countries', id: hoveredStateId},
                {hover: true}
            );
        }
    });

    // When the mouse leaves the state-fill layer, update the feature state of the
    // previously hovered feature.
    map.on('mouseleave', 'state-fills', () => {
        if (hoveredStateId) {
            map.setFeatureState(
                {source: 'countries', id: hoveredStateId},
                {hover: false}
            );
        }
        hoveredStateId = null;
    });
  }

  map.on('load', async () => {
    if (data.worldAdvisoryMap == "true") {
      worldAdvisoryMap();
      mapToEnglish();
    } else {
      countryShowMap();
      mapToEnglish();
    }
  });
  }
}
