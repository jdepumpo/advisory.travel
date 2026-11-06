ISO3166.configuration.enable_currency_extension!

# Kosovo has no official ISO 3166 code, so the countries gem doesn't include it.
# XK is the code in common use (EU, IMF, both advisory sources, Natural Earth).
ISO3166::Data.register(
  alpha2: "XK",
  alpha3: "XKX",
  iso_short_name: "Kosovo",
  iso_long_name: "The Republic of Kosovo",
  common_name: "Kosovo",
  continent: "Europe",
  region: "Europe",
  subregion: "Southern Europe",
  world_region: "EMEA",
  country_code: "383",
  currency_code: "EUR",
  languages_official: %w[sq sr],
  unofficial_names: %w[Kosovo Kosova],
  geo: {
    latitude: 42.6026,
    longitude: 20.903,
    min_latitude: 41.8565,
    max_latitude: 43.2689,
    min_longitude: 20.0141,
    max_longitude: 21.7899,
    bounds: {
      northeast: { lat: 43.2689, lng: 21.7899 },
      southwest: { lat: 41.8565, lng: 20.0141 }
    }
  },
  translations: { en: "Kosovo" }
)
