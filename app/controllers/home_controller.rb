class HomeController < ApplicationController
  def index
    @countries = Country.all
  end
end
