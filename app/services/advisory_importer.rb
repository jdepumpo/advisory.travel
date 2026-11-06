require "rss"
require "open-uri"
require "yaml"
require "json"
require "nokogiri"

# Refreshes countries and advisories. Advisories come from the US and Canadian
# governments; country details come from static_data/country_details.json
# (regenerate with `rails countries:update_details`).
#
# All network fetching happens first; the database is only touched at the end,
# inside a single transaction. If a source returns nothing (e.g. its page layout
# changed) the import aborts and the existing data is left in place.
class AdvisoryImporter
  class ImportError < StandardError; end

  # Territories with no advisory from either source
  EXCLUDED_COUNTRIES = %w[AX IO CX CC FO TF NF PN SH GS SJ WF HM BV].freeze

  OVERRIDES = YAML.load_file(Rails.root.join("static_data/advisory_overrides.yml")).freeze
  COUNTRY_DETAILS = JSON.parse(File.read(Rails.root.join("static_data/country_details.json")))["countries"].freeze

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
          country = by_alpha2[attrs[:alpha2]]
          unless country
            log "#{issuer_name}: advisory for #{attrs[:alpha2]}, which is not in the countries table"
            next
          end
          attrs = attrs.except(:alpha2)
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

      details = COUNTRY_DETAILS[alpha2] || {}
      log "No country details for #{alpha2}" if details.empty?

      {
        alpha2: alpha2, name: ISO3166::Country[alpha2].common_name, region: region, subregion: subregion,
        capital: details["capital"], drives_on: details["drives_on"],
        population: details["population"], landlocked: details["landlocked"]
      }.compact
    end
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
    # First entry wins if a tag appears twice
    state_to_iso = YAML.load_file(Rails.root.join("static_data/state_to_iso.yml"))
      .each_with_object({}) { |x, h| h[x["Tag"]] ||= [x["ISO"]] }
    tag_to_iso = state_to_iso.merge(OVERRIDES["us_tags"])
    by_title = OVERRIDES["us_titles"]
    skipped = OVERRIDES.dig("skip", "us_tags").keys

    URI.open(US_FEED_URL) do |rss|
      RSS::Parser.parse(rss, validate: false).items.flat_map do |item|
        level = item.categories[0]&.content.to_s[/\p{Digit}/]&.to_i or next []
        tag = item.categories[1]&.content
        next [] if skipped.include?(tag)

        title = item.title.to_s.squish
        codes = by_title.find { |prefix, _| title.start_with?(prefix) }&.last || tag_to_iso[tag]
        unless codes
          log "US: no country for tag #{tag.inspect} (#{title})"
          next []
        end

        codes.map { |iso| { alpha2: iso, level: level, summary: title, body: item.description, pub_date: item.pubDate&.to_date, source: item.link } }
      end
    end.uniq { |a| [a[:alpha2], a[:summary]] } # the feed sometimes lists a country twice (e.g. Tonga)
  end

  # ---- Government of Canada ----

  def fetch_ca_advisories
    doc = Nokogiri::HTML.parse(URI.open(CA_URL).read)

    rows = doc.search("main table tbody tr")
    unknown = []

    skipped = OVERRIDES.dig("skip", "ca_names").keys

    advisories = rows.flat_map do |row|
      link = row.at_css("td a") or next []
      name = link.text.strip
      next [] if skipped.include?(name)

      level = ca_level(row)
      unless level
        unknown << "#{name}: #{row.at_css('td div')&.text.to_s.squish.inspect}"
        next []
      end

      codes = OVERRIDES["ca_names"][name] || Array(ISO3166::Country.find_country_by_any_name(name)&.alpha2)
      if codes.empty?
        log "CA: no country for #{name.inspect}"
        next []
      end

      # Prefer the semantic class; fall back to the last cell
      date_text = (row.at_css("td.timestamp") || row.css("td").last)&.text.to_s.strip

      codes.map do |iso|
        {
          alpha2: iso,
          level: level,
          pub_date: (Date.parse(date_text) rescue nil),
          source: URI.join("https://travel.gc.ca", link["href"].to_s).to_s
        }
      end
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
