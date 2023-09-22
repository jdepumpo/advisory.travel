require 'rss'
require 'open-uri'
require 'yaml'
require 'json'
require 'countries'

## Get countries
Advisory.delete_all
Country.delete_all

def fetch_country_data(alpha2)
  info_hash = { }
  url = "https://restcountries.com/v3.1/alpha/#{alpha2}"
  country_json = URI.open(url).read
  country_info = JSON.parse(country_json)
  capital = country_info[0]["capital"][0] || "-"
  drives_on = country_info[0]["car"]["side"] || "-"
  population = country_info[0]["population"] || 0
  landlocked = country_info[0]["landlocked"] || "-"
  info_hash = { capital: capital, drives_on: drives_on, population: population, landlocked: landlocked }
end

country_array = []
ISO3166::Country.pluck(:alpha2, :region, :subregion).each do |info|
  if info[0].present? && info[1].present? && info[2].present? && info[0] != "MO"
    common_name = ISO3166::Country[info[0]].common_name
    puts "Trying to fetch addl data about #{common_name} (#{info[0]})"
    hash = fetch_country_data(info[0])
    Country.create!(
    alpha2: info[0],
    name: common_name,
    region: info[1],
    subregion: info[2],
    capital: hash[:capital],
    drives_on: hash[:drives_on],
    population: hash[:population],
    landlocked: hash[:landlocked]
    )
    puts "Created: #{common_name}"
    puts "------------------------"
  else
    puts "skipping..."
    next
  end
end

if Issuer.none?
  Issuer.create!(
    name: "US"
  )
end

def get_US_advisories
  state_to_iso_yml = YAML.load_file("#{Rails.root.to_s}/static_data/state_to_iso.yml")

  url = "https://travel.state.gov/_res/rss/TAsTWs.xml"

  URI.open(url) do |rss|
    feed = RSS::Parser.parse(rss, validate: false)
    feed.items.each do |item|
      pub_date = item.pubDate.to_date
      level_content = item.categories[0].content
      level_match = level_content.match(/\p{Digit}/)
      level_match ? level = level_match[0].to_i : next
      cc = item.categories[1].content
      state_code = state_to_iso_yml.find { |x| x["Tag"] == cc }
      next if state_code.nil?
      iso_code = state_code["ISO"]
      if Country.find_by(alpha2: iso_code)
        Advisory.create!(
          country: Country.find_by(alpha2: iso_code),
          level: level,
          issuer: Issuer.find_by(name: "US"),
          body: item.description,
          pub_date: pub_date
          )
        puts iso_code
      end
    end
  end
end

get_US_advisories
