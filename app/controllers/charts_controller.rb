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
        :current_onebr => { :color => 'rgba(255, 0, 0, 1)', :visible => 'true'},
        :current_twobr => { :color => 'rgba(0, 255, 0, 1)', :visible => 'true'},
        :current_threebr => { :color => 'rgba(0, 0, 255, 1)', :visible => 'true'},
        :old_onebr => { :color => 'rgba(123, 0, 0, 1)', :visible => 'false'},
        :old_twobr => { :color => 'rgba(0, 123, 0, 1)', :visible => 'false'},
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

    @unit_price_report =  UnitPriceReport.all.
      select {|row| row.priceupdated }.
      sort_by {|row| [row.unitnum, row.date] }
  end

  def unit
    unit_data =  UnitPriceReport.
      select {|row| row.trust.downcase.eql? params[:trust].downcase }.
      select {|row| row.location.downcase.eql? params[:location].downcase }.
      select {|row| row.unitname.downcase.eql? params[:unitname].downcase }.
      select {|row| row.unitnum.eql? params[:unitnum] }.
      collect {|row| {
        :date => row.attributes['date'],
        :trust => row.attributes['trust'],
        :location => row.attributes['location'],
        :unitname => row.attributes['unitname'],
        :unitnum => row.attributes['unitnum'],
        :rent => row.attributes['rent'],
        :movein => row.attributes['movein'],}}.
      sort_by {|row| row[:date]}

    @data = {
      :trust => unit_data.last[:trust],
      :location => unit_data.last[:location],
      :unitnum => unit_data.last[:unitnum],
      :unitname => unit_data.last[:unitname],
      :dates => "'" + unit_data.collect {|up| up[:date].strftime('%Y-%m-%d') }.join("','") + "'",
      :rents => unit_data.collect {|up| up[:rent] }.join(","),
      :movein => unit_data.collect {|up| up[:movein] },
    }

  end
end
