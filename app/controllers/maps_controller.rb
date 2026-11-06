class MapsController < ApplicationController

  def index
    @country = Country.find_by(alpha2: (params[:country]))
    @country_info = ISO3166::Country[params[:country]]
    @advisories = Advisory.where(country: @country).order(pub_date: :desc)
  end

  # Country shapes with each country's current average advisory level merged in.
  def countries
    # Always revalidate: unchanged data costs a 304, and new levels show up
    # right after the daily refresh instead of after a cache expiry.
    expires_now
    return unless stale?(etag: Advisory.maximum(:updated_at), public: true)

    levels = Country.joins(:advisories).group(:alpha2).average(:level)
    geojson = self.class.base_geojson.deep_dup
    geojson["features"].each do |feature|
      feature["properties"] ||= {}
      feature["properties"]["level"] = levels[feature["properties"]["iso_a2"]].to_i
    end

    render json: geojson, content_type: "application/geo+json"
  end

  def self.base_geojson
    @base_geojson ||= JSON.parse(File.read(Rails.root.join("static_data/countries.geojson")))
  end

end
