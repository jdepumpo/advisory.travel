class ApplicationController < ActionController::Base
  include Pagy::Method

  def default_url_options
    { host: ENV["DOMAIN"] || "localhost:3000" }
  end

end
