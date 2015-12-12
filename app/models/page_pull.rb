require 'zlib'

class PagePull < ActiveRecord::Base
  def dhtml
    Zlib::Inflate.inflate(Base64.decode64(html))
  end
end
