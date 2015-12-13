require 'open-uri'
require 'pry'
require 'zlib'
require 'base64'
require 'capybara/poltergeist'

class JobsController < ApplicationController
  def util
    pagepulls = PagePull.all
    binding.pry
  end

  def updateprices
    pullcamden
    parselistings
    updatefloorplans

    render :text => "done"
  end

  def pullcamden
    sites = {
      :camdencreekstone => 'https://www.camdenliving.com/atlanta-ga-apartments/camden-creekstone/apartments?bedrooms[]=12&bedrooms[]=9',
      :camdendunwoody => 'https://www.camdenliving.com/dunwoody-ga-apartments/camden-dunwoody/apartments?bedrooms[]=12&bedrooms[]=9&bedrooms[]=3'}

    #capybara/poultergeist/phantomjs is a headless javascript enabled browser!!!
    session = Capybara::Session.new(:poltergeist, {:timeout => 180})

    sites.each_pair do |loc,url|
      session.visit(url)
      page = session.html

      PagePull.create(
        location: loc, 
        url: url, 
        html: Base64.encode64(Zlib::Deflate.deflate(page.gsub("\u0000", ''))))
    end
  end

  def parselistings
    unparsed_pagepull_sql = 
      'select * ' +
      'from page_pulls ' +
      'where id not in (select page_pull_id from apartment_listings)'
    unparsed_pagepulls = PagePull.find_by_sql(unparsed_pagepull_sql)

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

    ActiveRecord::Base.transaction do
      new_listings.each do |l| l.save end
    end
  end

  def updatefloorplans
    unparsed_pagepulls_sql = 
      "with created_ats as " +
      "(select updated_at as latestdate from floor_plans " +
      "union " +
      "select to_date('1900-01-01','YYYY-MM-DD') as latestdate) " +

      "select * " +
      "from page_pulls " +
      "where created_at > (select latestdate from created_ats order by latestdate desc limit 1);"
    unparsed_pagepulls = PagePull.find_by_sql(unparsed_pagepulls_sql)

    existing_floorplans = FloorPlan.all
    current_floorplans = unparsed_pagepulls.map {|upp|
      Nokogiri::HTML(upp.dhtml).css("div[class='available-apartment-card default-gutter']").
        map {|div|
          FloorPlan.new do |fp|
            fp.location = upp.location
            fp.name = div.css("h3 span[class='floorplan-name']").text
            fp.sqft = div.css("div[class='card unit-info']").css('span')[1].text.gsub(/SqFt /,'')
            fp.beds = div.css("div[class='card unit-info']").css('span')[2].text.gsub(/Beds /,'')
            fp.baths = div.css("div[class='card unit-info']").css('span')[3].text.gsub(/Baths /,'')
          end
        }
    }.flatten

    insert_floorplans = current_floorplans.
      select {|cfp| not existing_floorplans.map{|efp| efp.name}.include? cfp.name }
    update_floorplans = existing_floorplans.
      select {|efp| current_floorplans.map{|cfp| cfp.name}.include? efp.name }

    ActiveRecord::Base.transaction do 
      #insert new records
      current_floorplans.each do |fp| fp.save end 
      #update updated_at on floorplans (so that unprocessed page pulls will all be after latest updated_at)
      #TODO rewrite this the right way
      updatetime = Time.zone.now
      FloorPlan.all.each do |fp| fp.updated_at = updatetime; fp.save end 
      #TODO fix dups getting inserted
    end
  end

  def pullcamdentest
    pullcamden
    render nothing: true
  end
  def parselistingstest
    parselistings
    render nothing: true
  end
  def updatefloorplanstest
    updatefloorplans 
    render nothing: true
  end
end
