class ApplicationController < ActionController::Base
  include Pagy::Method

  # Every page is public and changes once a day, when advisories:refresh runs.
  # Browsers always revalidate; Cloudflare keeps a copy for a day and the
  # daily refresh workflow purges it, so visitors never see stale data and
  # most requests never wake the Fly machine.
  EDGE_TTL = 1.day.to_i

  after_action :allow_edge_caching, if: -> { request.get? && (response.successful? || response.not_modified?) }

  def default_url_options
    { host: ENV["DOMAIN"] || "localhost:3000" }
  end

  private

  def allow_edge_caching
    response.cache_control.replace(max_age: 0, public: true, extras: ["s-maxage=#{EDGE_TTL}"])
  end

end
