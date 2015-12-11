require 'mechanize'
require 'nokogiri'
require 'open-uri'
require 'pry'
require 'active_record'
load 'connections.rb'
load 'aliases.rb'

sites = {
  :creekstone => 'https://www.camdenliving.com/atlanta-ga-apartments/camden-creekstone/apartments?bedrooms[]=12&bedrooms[]=9',
  :dunwoody => 'https://www.camdenliving.com/dunwoody-ga-apartments/camden-dunwoody/apartments?bedrooms[]=12&bedrooms[]=9&bedrooms[]=3'}
mechanize = Mechanize.new

#STEPS
#1) pull pages from sites hash (every 10 min), store results into DB
#2) parse results into apartment_listings table
#3) parse floorplans (if any new ones detected) into floorplans table
#4) chart results

sites.each_pair do |loc,url|
  mechanize.user_agent = AGENT_ALIASES[AGENT_ALIASES.keys[rand(1...AGENT_ALIASES.count)]]
  page = mechanize.get(url)

  binding.pry
  PagePull.create(
    location: loc,
    url: url,
    fetched_at: Time.now,
    html: page.body.gsub("\u0000", '')) #get rid of postgres 'string contains null byte' error
end
