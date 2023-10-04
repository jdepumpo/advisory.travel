require 'rss'
require 'open-uri'
require 'yaml'
require 'json'
require 'countries'
require 'nokogiri'

User.delete_all
User.create!(
  name: "Admin",
  email: "admin@admin.com",
  password: ENV['ADMIN_PASSWD'],
  admin: true,
)

## Get countries
Advisory.delete_all
#Country.delete_all

def fetch_countries
  def fetch_country_data(alpha2)
    info_hash = { }
    url = "https://restcountries.com/v3.1/alpha/#{alpha2}"
    begin
      country_json = URI.open(url).read
      country_info = JSON.parse(country_json)
      capital = country_info[0]["capital"][0]
      drives_on = country_info[0]["car"]["side"]
      population = country_info[0]["population"]
      landlocked = country_info[0]["landlocked"]
      info_hash = { capital: capital, drives_on: drives_on, population: population, landlocked: landlocked }
      return info_hash
    rescue
      return info_hash = { capital: "-", drives_on: "-", population: 0, landlocked: "-" }
    end
  end

  excluded_countries = %W[MO AX AS BQ IO CX CC CK FK FO TF GI GL GP GU MQ YT NF MP PN RE BL SH MF PM SM GS SJ TK WF NU HM BV]
  pluck_array = ISO3166::Country.pluck(:alpha2, :region, :subregion)
  fields = [:alpha2, :region, :subregion]
  country_array = pluck_array.map {|row| fields.zip(row).to_h }
  countries = country_array.delete_if { |i| excluded_countries.include? i[:alpha2] }
  countries.each do |info|
    if info[:alpha2].present?
      common_name = ISO3166::Country[info[:alpha2]].common_name
      puts "Trying to fetch addl data about (#{common_name})"
      hash = fetch_country_data(info[:alpha2])
      Country.create!(
      alpha2: info[:alpha2],
      name: common_name,
      region: info[:region],
      subregion: info[:subregion],
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
end

#fetch_countries

Issuer.delete_all
Issuer.create!(
  name: "US"
)
Issuer.create!(
  name: "CA"
)


## Get US advisories

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

## Get CA Advisories

def get_CA_advisories

  url = "https://travel.gc.ca/travelling/advisories"

  html_file = URI.open(url).read
  html_doc = Nokogiri::HTML.parse(html_file)

  country_array = [ ]

  html_doc.search("main table tbody tr").each do |element|
    puts "_______FROM CA____________"
    country_data = element.search("td a")
    country = country_data.text.strip
    puts "Country: #{country}"

    date_data = element.css("td[4]").children
    date = date_data.text.strip
    puts "Last updated: #{date}"

    advisory_data = element.search("td div")
    advisory = advisory_data.text.strip
    puts "Advisory: #{advisory}"

    country_hash = { country: country, date: date, advisory_text: advisory }
    country_array.push(country_hash)
  end

  puts "################################"
  puts "Moving to matching ------------>"
  puts "################################"

  country_array.each do |country|

    level_1 = Proc.new { |x| x.start_with?("Take normal security precautions") }
    level_2 = Proc.new { |x| x.start_with?("Exercise a high degree of caution") }
    level_3 = Proc.new { |x| x.start_with?("Avoid non-essential travel") }
    level_4 = Proc.new { |x| x.start_with?("Avoid all travel") }

    case country[:advisory_text]
      when level_1
        level = 1
      when level_2
        level = 2
      when level_3
        level = 3
      when level_4
        level = 4
      else
        level = 0
    end

    if country_find = ISO3166::Country.find_country_by_any_name(country[:country]) && Country.find_by(alpha2: ISO3166::Country.find_country_by_any_name(country[:country]).alpha2)
      puts "Matched #{country[:country]}!"
      Advisory.create!(
        country: Country.find_by(alpha2: country_find.alpha2),
        level: level,
        issuer: Issuer.find_by(name: "CA"),
        pub_date: country[:date]
      )
      puts "created #{country_find.alpha2}"
    else
      puts "skipping!!!"
      next
    end
  end
end

get_CA_advisories
