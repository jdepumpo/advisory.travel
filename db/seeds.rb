require 'rss'
require 'open-uri'
require 'yaml'
require 'json'
require 'countries'

User.delete_all
User.create!(
  name: "Admin",
  email: "admin@admin.com",
  password: ENV['ADMIN_PASSWD'],
  admin: true,
)

## Get countries
Advisory.delete_all
Country.delete_all

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

if Issuer.none?
  Issuer.create!(
    name: "US"
  )
end

GetUsAdvisoriesJob.perform_now
