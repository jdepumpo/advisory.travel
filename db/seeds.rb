require 'rss'
require 'open-uri'
require 'yaml'
require 'countries'

if User.none?
  10.times do
    User.create!(
      name: Faker::Name.name,
      email: Faker::Internet.email,
      password: "1234asdf"
    )
  end
end

if Country.none?
  country_array = []
  ISO3166::Country.pluck(:alpha2, :region).each do |info|
    common_name = ISO3166::Country[info[0]].common_name
    Country.create!(
      alpha2: info[0],
      name: common_name,
      region: info[1]
    )
    puts common_name
  end
end

if Issuer.none?
  Issuer.create!(
    name: "US"
  )
end

Advisory.delete_all

state_to_iso_yml = YAML.load_file("#{Rails.root.to_s}/static_data/state_to_iso.yml")

url = "https://travel.state.gov/_res/rss/TAsTWs.xml"

URI.open(url) do |rss|
  feed = RSS::Parser.parse(rss, validate: false)
  feed.items.each do |item|
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
        body: item.description
        )
      puts iso_code
    end
  end
end
