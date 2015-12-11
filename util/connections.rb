require 'active_record'

LOCAL_PS_SPEC = {
  :adapter => 'postgresql',
  :encoding => 'unicode',
  :pool => '5',
  :username => 'camdenpuller',
  :password => 'xuthiePhaeYa7ua0roh2eitha',
  :database => 'camdenpuller',
}

class LocalDB < ActiveRecord::Base
  self.abstract_class = true
  establish_connection(LOCAL_PS_SPEC)
end

class PagePull < LocalDB
  self.table_name = 'page_pulls'
end

class ApartmentListing < LocalDB
  self.table_name = 'apartment_listings'
end
