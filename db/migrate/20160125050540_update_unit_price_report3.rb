class UpdateUnitPriceReport3 < ActiveRecord::Migration
  def up
    execute <<-SQL
      drop view unit_price_report;
      CREATE OR REPLACE VIEW unit_price_report AS
        with pricereport_rankedlines as 
        (select
          trust,
          location,
          unitname,
          unitnum,
          floor,
          rent,
          sqft,
          beds,
          sqft_per_dollar,
          movein,
          fetched_at,
          fetched_at::timestamp::date fetched_on,	
          rank() over (partition by trust,location,unitname,unitnum order by fetched_at::timestamp::date) bdaterank,
          rank() over (partition by trust,location,unitname,unitnum order by fetched_at::timestamp::date desc) edaterank
        from price_report_rankedlines
        where latedaterank = 1),

        begindates as (select * from pricereport_rankedlines where bdaterank = 1),

        enddates as (select * from pricereport_rankedlines where edaterank = 1),

        dates as
        (select 
          i::date date
        from generate_series
          ((select fetched_on from pricereport_rankedlines order by fetched_on limit 1),
          (select fetched_on from pricereport_rankedlines 
          order by fetched_on 
          desc limit 1),
          '1 day'::interval) i),

        pricereport_datedelimited as
        (select
          p.trust,
          p.location,
          p.unitname,
          p.unitnum,
          b.fetched_on as begindate,
          e.fetched_on as enddate
        from pricereport_rankedlines p
        join begindates b 
          on p.trust = b.trust 
          and p.location = b.location
          and p.unitname = b.unitname 
          and p.unitnum = b.unitnum
        join enddates e 
          on p.trust = e.trust
          and p.location = b.location
          and p.unitname = e.unitname
          and p.unitnum = e.unitnum
        group by 
          p.trust,
          p.location,
          p.unitname,
          p.unitnum,
          b.fetched_on,
          e.fetched_on),

        idx as
        (select 
          p.trust,
          p.location,
          p.unitname,
          p.unitnum,
          d.date
        from dates d
        cross join pricereport_datedelimited p
        where d.date between p.begindate and p.enddate),

        idx_ranked_joined as
        (select
          i.trust,
          i.location,
          i.unitname,
          i.unitnum,
          i.date,
          p.rent,
          p.movein,
          rank() over 
            (partition by 
              i.trust, 
              i.location, 
              i.unitname, 
              i.unitnum, 
              i.date 
            order by 
              p.fetched_at desc) daterank,
          p.fetched_at,
          i.date = p.fetched_on priceupdated
        from idx i
        left outer join pricereport_rankedlines p 
          on i.trust = p.trust
          and i.location = p.location
          and i.unitname = p.unitname
          and i.unitnum = p.unitnum
          and i.date >= p.fetched_on
        order by i.trust,i.location,i.unitname,i.unitnum,i.date)

        select *
        from idx_ranked_joined
        where daterank = 1
        order by trust,location,unitname,unitnum,date
    SQL
  end
  def down
    execute <<-SQL
      drop view unit_price_report;
      CREATE OR REPLACE VIEW unit_price_report AS
        with pricereport_rankedlines as 
        (select
          trust,
          location,
          unitname,
          unitnum,
          floor,
          rent,
          sqft,
          beds,
          sqft_per_dollar,
          movein,
          fetched_at,
          fetched_at::timestamp::date fetched_on,	
          rank() over (partition by trust,location,unitname,unitnum order by fetched_at::timestamp::date) bdaterank,
          rank() over (partition by trust,location,unitname,unitnum order by fetched_at::timestamp::date desc) edaterank
        from price_report_rankedlines
        where latedaterank = 1),

        begindates as (select * from pricereport_rankedlines where bdaterank = 1),

        enddates as (select * from pricereport_rankedlines where edaterank = 1),

        dates as
        (select 
          i::date date
        from generate_series
          ((select fetched_on from pricereport_rankedlines order by fetched_on limit 1),
          (select fetched_on from pricereport_rankedlines 
          order by fetched_on 
          desc limit 1),
          '1 day'::interval) i),

        pricereport_datedelimited as
        (select
          p.trust,
          p.location,
          p.unitname,
          p.unitnum,
          b.fetched_on as begindate,
          e.fetched_on as enddate
        from pricereport_rankedlines p
        join begindates b 
          on p.trust = b.trust 
          and p.location = b.location
          and p.unitname = b.unitname 
          and p.unitnum = b.unitnum
        join enddates e 
          on p.trust = e.trust
          and p.location = b.location
          and p.unitname = e.unitname
          and p.unitnum = e.unitnum
        group by 
          p.trust,
          p.location,
          p.unitname,
          p.unitnum,
          b.fetched_on,
          e.fetched_on),

        idx as
        (select 
          p.trust,
          p.location,
          p.unitname,
          p.unitnum,
          d.date
        from dates d
        cross join pricereport_datedelimited p
        where d.date between p.begindate and p.enddate),

        idx_ranked_joined as
        (select
          i.trust,
          i.location,
          i.unitname,
          i.unitnum,
          i.date,
          p.rent,
          p.movein,
          rank() over 
            (partition by 
              i.trust, 
              i.location, 
              i.unitname, 
              i.unitnum, 
              i.date 
            order by 
              p.fetched_at desc) daterank,
          p.fetched_at,
          i.date = p.fetched_on priceupdated
        from idx i
        left outer join pricereport_rankedlines p 
          on i.trust = p.trust
          and i.location = p.location
          and i.unitname = p.unitname
          and i.unitnum = p.unitnum
          and i.date >= p.fetched_on
        order by i.trust,i.location,i.unitname,i.unitnum,i.date)

        select *
        from idx_ranked_joined
        where daterank = 1
        and unitnum = '6207'
        order by trust,location,unitname,unitnum,date
    SQL
  end
end
