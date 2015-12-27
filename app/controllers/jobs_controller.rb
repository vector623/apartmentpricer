require 'open-uri'
require 'pry'
require 'zlib'
require 'base64'
require 'capybara/poltergeist'

class JobsController < ApplicationController
  def util
    unit_prices = ApartmentListing.find_by_sql(File.read('sqls/unit_prices.sql'))

    binding.pry

    render :text => 'dd'
  end

  def updateprices
    pullpages
    parselistings_camden
    updatefloorplans_camden

    render :text => "done"
  end

  def pullpages
    sites = [
      ['camden','creekstone','https://www.camdenliving.com/atlanta-ga-apartments/camden-creekstone/apartments?bedrooms[]=12&bedrooms[]=9'],
      ['camden','dunwoody','https://www.camdenliving.com/dunwoody-ga-apartments/camden-dunwoody/apartments?bedrooms[]=12&bedrooms[]=9&bedrooms[]=3'],
      ['tenperimeterpark',
       'perimeter',
       'https://living10perimeterpark.securecafe.com/onlineleasing/10-perimeter-park/oleapplication.aspx?stepname=Apartments&myOlePropertyId=171003']]

    #capybara/poultergeist/phantomjs is a headless javascript enabled browser!!!
    session = Capybara::Session.new(:poltergeist, {:timeout => 3600})

    sites.each do |site|
      begin
        session.visit(site[2])
        page = session.html

        PagePull.create(
          trust: site[0],
          location: site[1], 
          url: site[2], 
          html: Base64.encode64(Zlib::Deflate.deflate(page.gsub("\u0000", ''))))
      end
    end

    session.driver.quit
  end

  def parselistings_camden
    unparsed_pagepull_sql = 
      'select * ' +
      'from page_pulls ' +
      "where trust = 'camden' " +
      'and id not in (select page_pull_id from apartment_listings)'
    unparsed_pagepulls = PagePull.find_by_sql(unparsed_pagepull_sql)

    #target "x other units available >" link
    div_classes = 'card-switch card-region-overlay pos-top pos-left pos-bottom inverted face-back'
    new_listings = unparsed_pagepulls.collect {|upp|
      Nokogiri::HTML(upp.dhtml).css("div[class='#{div_classes}']").
      collect {|div|
        div.css('tr').
          select {|tr| tr.css('th').count == 0 }.
          collect {|tr|
            ApartmentListing.new do |a|
              a.page_pull_id = upp.id
              a.unitname = div.css('h3').css('span')[0].text
              a.unitnum = tr.css('td')[0].text
              a.floor = tr.css('td')[1].text
              a.rent = tr.css('td')[2].text.gsub(/\$/,'')
              a.movein = tr.css('td')[3].text
            end
          }.flatten(1)#end of div.collect
      }.flatten(1)#end of Nokogiri.collect
    }.flatten(1)#end of unparsed_pagepulls.collect

    #TODO: target apartment listings missing the "x other units available >" link

    ActiveRecord::Base.transaction do
      new_listings.each do |l| l.save end
    end
  end

  def updatefloorplans_camden
    unparsed_pagepulls_sql = 
      "with created_ats as " +
      "(select updated_at as latestdate from floor_plans " +
      "union " +
      "select to_date('1900-01-01','YYYY-MM-DD') as latestdate) " +

      "select * " +
      "from page_pulls " +
      "where trust = 'camden' " +
      "and id not in (select page_pull_id from floor_plans);"
    unparsed_pagepulls = PagePull.find_by_sql(unparsed_pagepulls_sql)

    current_floorplans = unparsed_pagepulls.map {|upp|
      Nokogiri::HTML(upp.dhtml).css("div[class='available-apartment-card default-gutter']").
        map {|div|
          FloorPlan.new do |fp|
            fp.page_pull_id = upp.id
            fp.location = upp.location
            fp.name = div.css("h3 span[class='floorplan-name']").text
            fp.sqft = div.css("div[class='card unit-info']").css('span')[1].text.gsub(/SqFt /,'')
            fp.beds = div.css("div[class='card unit-info']").css('span')[2].text.gsub(/Beds /,'')
            fp.baths = div.css("div[class='card unit-info']").css('span')[3].text.gsub(/Baths /,'')
          end
        }
    }.flatten

    ActiveRecord::Base.transaction do 
      current_floorplans.each do |fp| fp.save end 
    end
  end

  def pullcamdentest
    pullcamden
    render nothing: true
  end
  def parselistings_camdentest
    parselistings_camden
    render nothing: true
  end
  def updatefloorplans_camdentest
    updatefloorplans_camden
    render nothing: true
  end
end
