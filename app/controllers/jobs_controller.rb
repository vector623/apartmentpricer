require 'pry'
class JobsController < ApplicationController
  def util
    pagepulls = PagePull.all
    binding.pry
  end

  def pullcamden
    sites = {
      :creekstone => 'https://www.camdenliving.com/atlanta-ga-apartments/camden-creekstone/apartments?bedrooms[]=12&bedrooms[]=9',
      :dunwoody => 'https://www.camdenliving.com/dunwoody-ga-apartments/camden-dunwoody/apartments?bedrooms[]=12&bedrooms[]=9&bedrooms[]=3'}
  end
end
