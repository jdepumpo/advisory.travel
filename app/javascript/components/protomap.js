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
      zoom: 2,
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
    map.addSource('countries', {
      'type': 'geojson',
      'data':
          '/map_data/countries.geojson'
    });
    console.log("geojson loaded")
    // The feature-state dependent fill-opacity expression will render the hover effect
    // when a feature's hover state is set to true.
    const spinnerEl = document.getElementById('spinner');
    const backgroundEl = document.getElementById('loading-background');

    map.addLayer({
        'id': 'country-fills',
        'type': 'fill',
        'source': 'countries',
        'layout': {},
        'paint': {
          'fill-color': [
              'let',
              'density',
              ['get', 'level'],
              [
                'interpolate',
                ['linear'],
                ['var', 'density'],
                0,
                ['to-color', '#e2e2e2'],
                1,
                ['to-color', '#228b22'],
                2,
                ['to-color', '#ffd800'],
                3,
                ['to-color', '#ff8c00'],
                4,
                ['to-color', '#ae0c00']
              ]
          ],
          'fill-opacity': 0.5
        }
    });

    map.on('click', 'country-fills', (e) => {
      const frame = document.getElementById('country_info');
      frame.src=`/map?country=${e.features[0].properties["iso_a2"]}`;
      frame.reload();
      const grid = document.getElementById('map_container');
      grid.classList.replace("sidebar_closed", "sidebar_open")
    });

    // Change the cursor to a pointer when the mouse is over the states layer.
    map.on('mouseenter', 'country-fills', () => {
        map.getCanvas().style.cursor = 'pointer';
    });

    // Change it back to a pointer when it leaves.
    map.on('mouseleave', 'country-fills', () => {
        map.getCanvas().style.cursor = '';
    });

    map.on('data', (e) => {
      if (e.sourceId !== 'countries' || !e.isSourceLoaded) return;

      spinnerEl.remove();
      backgroundEl.remove();
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
