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

  def pullcamden
    sites = {
      :camdencreekstone => 'https://www.camdenliving.com/atlanta-ga-apartments/camden-creekstone/apartments?bedrooms[]=12&bedrooms[]=9',
      :camdendunwoody => 'https://www.camdenliving.com/dunwoody-ga-apartments/camden-dunwoody/apartments?bedrooms[]=12&bedrooms[]=9&bedrooms[]=3'}

    #mechanize is old
    #mechanize = Mechanize.new
    #capybara/poultergeist/phantomjs is a headless javascript enabled browser!!!
    session = Capybara::Session.new(:poltergeist)

    sites.each_pair do |loc,url|
      #page = mechanize.get(url)
      session.visit(url)
      page = session.html

      PagePull.create(
        location: loc, 
        url: url, 
        html: Base64.encode64(Zlib::Deflate.deflate(page.gsub("\u0000", ''))))

      #sleep rand(45...75)
    end

    render :inline => "done"
  end

  def parselistings
    unparsed_pagepull_sql = 
      'select * ' +
      'from page_pulls ' +
      'where id not in (select page_pull_id from apartment_listings)'
    unparsed_pagepulls = PagePull.find_by_sql(unparsed_pagepull_sql)

    div_classes = 'card-switch card-region-overlay pos-top pos-left pos-bottom inverted face-back'
    ActiveRecord::Base.transaction do
      new_listings = unparsed_pagepulls.collect {|upp|
        Nokogiri::HTML(PagePull.first.dhtml).css('div').
        select {|div| not div.attributes.nil? }.
        select {|div| not div.attributes['class'].nil? }.
        select {|div| div.attributes['class'].value.eql? div_classes }.
        collect {|div|
          div.css('tr').
            select {|tr| tr.css('th').count == 0 }.
            collect {|tr|
              ApartmentListing.create(
                page_pull_id: upp.id,
                unitname: div.css('h3').css('span')[0].text,
                unitnum: tr.css('td')[0].text,
                floor: tr.css('td')[1].text,
                rent: tr.css('td')[2].text.gsub(/\$/,''),
                movein: tr.css('td')[3].text)
            }.flatten(1)#end of div.collect
        }.flatten(1)#end of Nokogiri.collect
      }.flatten(1)#end of unparsed_pagepulls.collect
    end#end of ActiveRecord::Basee.transaction

    render :inline => "done"
  end

  def updatefloorplans
    unparsed_pagepulls_sql = 
      "with created_ats as " +
      "(select updated_at as latestdate from floor_plans " +
      "union " +
      "select to_date('1900-01-01','YYYY-MM-DD') as latestdate) " +

      "select * " +
      "from page_pulls " +
      "where created_at > (select latestdate from created_ats order by latestdate desc limit 1) " +
      "and location = 'camdendunwoody'"
    pagepulls = PagePull.find_by_sql(unparsed_pagepulls_sql)

    existing_floorplans = FloorPlan.all

    current_floorplans = pagepulls.collect {|upp|
      Nokogiri::HTML(upp.dhtml).css("div[class='available-apartment-card default-gutter']").
        collect {|div|
          FloorPlan.new do |fp|
            fp.name = div.css("div[class='panel-pane pane-entity-field pane-node-field-title-display inverted pos-left pos-bottom']").text.strip,
            fp.sqft = div.css("div[class='card unit-info']").css('span')[1].text.gsub(/SqFt /,''),
            fp.beds = div.css("div[class='card unit-info']").css('span')[2].text.gsub(/Beds /,''),
            fp.baths = div.css("div[class='card unit-info']").css('span')[3].text.gsub(/Baths /,'')
          end
        }
    }.flatten(1)

    #current_floorplans not in existing_floorplans
    insert_floorplans = nil
    #existing_floorplans in current_floorplans
    update_floorplans = nil

    binding.pry

    render :inline => "done"
  end
end
