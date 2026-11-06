namespace :countries do
  SOURCE_URL = "https://gitlab.com/restcountries/restcountries/-/raw/master/src/main/resources/countriesV3.1.json".freeze

  desc "Regenerate static_data/country_details.json from the REST Countries dataset (rarely needed)"
  task :update_details do
    require "open-uri"
    require "json"

    countries = JSON.parse(URI.open(SOURCE_URL, read_timeout: 60).read)
    details = countries.to_h do |c|
      [c["cca2"], {
        "capital" => Array(c["capital"]).first,
        "drives_on" => c.dig("car", "side"),
        "population" => c["population"],
        "landlocked" => c["landlocked"]
      }]
    end.sort.to_h

    path = File.expand_path("../../static_data/country_details.json", __dir__)
    File.write(path, JSON.pretty_generate(
      "source" => SOURCE_URL,
      "license" => "MPL-2.0 (REST Countries, https://gitlab.com/restcountries/restcountries)",
      "generated_at" => Time.now.utc.iso8601,
      "countries" => details
    ) + "\n")
    puts "Wrote #{details.size} countries to #{path}"
  end
end
