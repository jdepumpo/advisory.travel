class PagesController < ApplicationController
  def show
    render template: "pages/#{params[:page]}"
    @country = Country.find_by(alpha2: params[:country])
  rescue ActionView::MissingTemplate
    render "errors/not_found", status: 404
  end

end
