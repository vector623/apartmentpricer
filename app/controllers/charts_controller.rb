class ChartsController < ApplicationController 
  def util
    binding.pry
  end

  def prices
    prices = PriceReport.all
    current_prices = prices.select {|p| p.current == 1}
    old_prices = prices.select {|p| p.current == 1}

    rooms = {
      :current_onebr => [1,1],
      :current_twobr => [1,2],
      :current_threebr => [1,3],
      :old_onebr => [0,1],
      :old_twobr => [0,2],
      :old_threebr => [0,3],
    }

    datahash = rooms.collect {|k,v|
      {
        k.to_sym => prices.
          sort_by {|s| s.fetched_at }.
          select {|s| s.current.eql? v[0] }.
          select {|s| s.beds.eql? v[1] }.
          collect {|s|
            {
              :trust => s.trust,
              :location => s.location,
              :unitname => s.unitname,
              :unitnum => s.unitnum,
              :floor => s.floor,
              :beds => s.beds,
              :baths => s.baths,
              :movein => s.movein,
              :movein_dateutc => "Date.UTC(#{s.movein.strftime('%C%y,%m,%e')})",
              :fetched_at => s.fetched_at,
              :fetched_at_dateutc => "Date.UTC(#{s.fetched_at.strftime('%C%y,%m,%e')})",
              :rent => s.rent,
              :sqft => s.sqft,
              :sqft_per_dollar => s.sqft_per_dollar.round(4),
              :current => s.current
            }
          },
      }
    }
    datahash = Hash[*datahash.collect {|i| i.collect{|k,v| [k,v]}.flatten(1)}.flatten(1)]

    datahash = {
      :rooms => rooms,
      :prices => datahash,
      :options =>
      {
        :current_onebr => { :color => 'rgba(255, 0, 0, 1)', :visible => 'false'},
        :current_twobr => { :color => 'rgba(0, 255, 0, 1)', :visible => 'true'},
        :current_threebr => { :color => 'rgba(0, 0, 255, 1)', :visible => 'false'},
        :old_onebr => { :color => 'rgba(123, 0, 0, 1)', :visible => 'false'},
        :old_twobr => { :color => 'rgba(0, 123, 0, 1)', :visible => 'true'},
        :old_threebr => { :color => 'rgba(0, 0, 123, 1)', :visible => 'false'},
      },
      :last_post => prices.
        sort_by {|s| s.fetched_at}.
        last.
        fetched_at.
        in_time_zone('Eastern Time (US & Canada)').
        strftime('%I:%M%P %Y-%m-%d')
    }

    @prices = datahash
  end
end
