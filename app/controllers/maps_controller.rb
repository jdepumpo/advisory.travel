class MapsController < ApplicationController

  def index
    @country = Country.find_by(alpha2: (params[:country]))
    @country_info = ISO3166::Country[params[:country]]
    @advisories = Advisory.where(country: @country).order(pub_date: :desc)
  end

end

def user_params
  params.require(:maps).permit(:country)
end
