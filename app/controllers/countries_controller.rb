class CountriesController < ApplicationController
  before_action :set_country, only: :show

 # authorize_resource

  def index
    @q = Country.ransack(params[:q])
    @pagy, @countries = pagy(@q.result.order(name: :asc), items: 30)
    @country_info = ISO3166::Country[@country]
  end

  def show
    @country_info = ISO3166::Country[@country.alpha2]
    @advisories = Advisory.where(country: @country)
  end

  private

  def set_country
    @country = Country.find_by(alpha2: params[:id])
  end

end
