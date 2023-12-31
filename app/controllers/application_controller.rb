class ApplicationController < ActionController::Base
  include Pagy::Backend

  rescue_from CanCan::AccessDenied do |exception|
    redirect_to request.referer || root_path, alert: exception.message
  end

  def default_url_options
    { host: ENV["DOMAIN"] || "localhost:3000" }
  end

end
