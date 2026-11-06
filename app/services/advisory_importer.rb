require "rss"
require "open-uri"
require "yaml"
require "json"
require "nokogiri"

# Refreshes countries and advisories from external sources.
#
# All network fetching happens first; the database is only touched at the end,
# inside a single transaction. If a source returns nothing (e.g. its page layout
# changed) the import aborts and the existing data is left in place.
class AdvisoryImporter
  class ImportError < StandardError; end

  EXCLUDED_COUNTRIES = %w[MO AX AS BQ IO CX CC CK FK FO TF GI GL GP GU MQ YT NF MP PN RE BL SH MF PM SM GS SJ TK WF NU HM BV].freeze

  US_FEED_URL = "https://travel.state.gov/_res/rss/TAsTWs.xml".freeze
  CA_URL = "https://travel.gc.ca/travelling/advisories".freeze

  # Matched as prefixes, since the text may carry "(with regional advisories)"
  CA_LEVEL_TEXT = {
    "Exercise normal security precautions" => 1,
    "Take normal security precautions" => 1, # wording used before 2026
    "Exercise a high degree of caution" => 2,
    "Avoid non-essential travel" => 3,
    "Avoid all travel" => 4
  }.freeze

  # Fallback: the risk icon's filename, e.g. /images/icons/increased-caution.svg
  CA_LEVEL_ICONS = {
    "normal-precautions" => 1,
    "increased-caution" => 2,
    "reconsider-travel" => 3,
    "do-not-travel" => 4
  }.freeze

  # Abort if more than this share of CA rows can't be classified
  MAX_UNKNOWN_LEVEL_SHARE = 0.1

  def self.run = new.run

  def run
    countries = fetch_countries
    us = fetch_us_advisories
    ca = fetch_ca_advisories

    raise ImportError, "No US advisories parsed - feed format may have changed" if us.empty?
    raise ImportError, "No CA advisories parsed - page layout may have changed" if ca.empty?

    ActiveRecord::Base.transaction do
      upsert_countries(countries)
      issuers = { "US" => Issuer.find_or_create_by!(name: "US"), "CA" => Issuer.find_or_create_by!(name: "CA") }
      by_alpha2 = Country.all.index_by(&:alpha2)

      Advisory.delete_all
      { "US" => us, "CA" => ca }.each do |issuer_name, advisories|
        advisories.each do |attrs|
          country = by_alpha2[attrs.delete(:alpha2)] or next
          Advisory.create!(attrs.merge(country: country, issuer: issuers[issuer_name]))
        end
      end
    end

    log "Import complete: #{Country.count} countries, #{Advisory.count} advisories (US #{us.size}, CA #{ca.size} parsed)"
  end

  private

  def log(msg)
    puts msg
  end

  # ---- Countries ----

  def fetch_countries
    ISO3166::Country.pluck(:alpha2, :region, :subregion).filter_map do |alpha2, region, subregion|
      next if alpha2.blank? || EXCLUDED_COUNTRIES.include?(alpha2)

      { alpha2: alpha2, name: ISO3166::Country[alpha2].common_name, region: region, subregion: subregion }
        .merge(fetch_country_details(alpha2))
    end
  end

  # Returns {} on failure so existing values in the database are kept.
  def fetch_country_details(alpha2)
    info = JSON.parse(URI.open("https://restcountries.com/v3.1/alpha/#{alpha2}", read_timeout: 15).read)[0]
    {
      capital: info.dig("capital", 0),
      drives_on: info.dig("car", "side"),
      population: info["population"],
      landlocked: info["landlocked"]
    }
  rescue StandardError => e
    log "Could not fetch details for #{alpha2}: #{e.message}"
    {}
  end

  def upsert_countries(countries)
    countries.each do |attrs|
      country = Country.find_or_initialize_by(alpha2: attrs[:alpha2])
      country.assign_attributes(attrs.except(:alpha2))
      # New countries with no details yet get placeholders the views can render
      country.capital ||= "-"
      country.drives_on ||= "-"
      country.population ||= 0
      country.save!
    end
  end

  # ---- US State Department ----

  def fetch_us_advisories
    state_to_iso = YAML.load_file(Rails.root.join("static_data/state_to_iso.yml"))

    URI.open(US_FEED_URL) do |rss|
      RSS::Parser.parse(rss, validate: false).items.filter_map do |item|
        level = item.categories[0]&.content.to_s[/\p{Digit}/]&.to_i or next
        tag = item.categories[1]&.content
        iso = state_to_iso.find { |x| x["Tag"] == tag }&.fetch("ISO") or next

        { alpha2: iso, level: level, body: item.description, pub_date: item.pubDate&.to_date, source: item.link }
      end
    end
  end

  # ---- Government of Canada ----

  def fetch_ca_advisories
    doc = Nokogiri::HTML.parse(URI.open(CA_URL).read)

    rows = doc.search("main table tbody tr")
    unknown = []

    advisories = rows.filter_map do |row|
      link = row.at_css("td a") or next
      name = link.text.strip

      level = ca_level(row)
      unless level
        unknown << "#{name}: #{row.at_css('td div')&.text.to_s.squish.inspect}"
        next
      end

      iso = ISO3166::Country.find_country_by_any_name(name)
      unless iso
        log "CA: no ISO match for #{name.inspect}"
        next
      end

      # Prefer the semantic class; fall back to the last cell
      date_text = (row.at_css("td.timestamp") || row.css("td").last)&.text.to_s.strip

      {
        alpha2: iso.alpha2,
        level: level,
        pub_date: (Date.parse(date_text) rescue nil),
        source: URI.join("https://travel.gc.ca", link["href"].to_s).to_s
      }
    end

    if unknown.any?
      log "CA: #{unknown.size} rows with unrecognized risk level:\n  #{unknown.join("\n  ")}"
      if unknown.size > rows.size * MAX_UNKNOWN_LEVEL_SHARE
        raise ImportError, "#{unknown.size}/#{rows.size} CA rows have an unrecognized risk level - wording may have changed"
      end
    end

    advisories
  end

  def ca_level(row)
    text = row.at_css("td div")&.text.to_s.squish
    CA_LEVEL_TEXT.each { |prefix, level| return level if text.start_with?(prefix) }

    icon = row.at_css("td img")&.[]("src").to_s[%r{/([\w-]+)\.svg\z}, 1]
    CA_LEVEL_ICONS[icon]
  end
end
