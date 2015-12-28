class UpdatePriceReportView3 < ActiveRecord::Migration
  def up
    execute <<-SQL
      DROP VIEW unit_price_report;

      DROP VIEW price_report;

      CREATE OR REPLACE VIEW price_report AS 
        WITH page_pulls_with_recency as
        (select 
          id,
          trust,
          location,
          url,
          html,
          created_at,
          updated_at,
          rank() over (partition by location order by created_at desc) daterank
        from page_pulls),

        floor_plans_ranked AS 
        (SELECT 
          floor_plans.trust,
          floor_plans.location,
          floor_plans.name,
          floor_plans.beds,
          floor_plans.baths,
          floor_plans.sqft,
          floor_plans.created_at,
          rank() OVER 
            (PARTITION BY 
              floor_plans.trust,
              floor_plans.location,
              floor_plans.name,
              floor_plans.beds,
              floor_plans.baths,
              floor_plans.sqft 
            ORDER BY
              floor_plans.created_at) AS daterank
        FROM floor_plans),

        joined AS 
        (SELECT 
          pp.trust,
          pp.location,
          al.unitname,
          al.unitnum,
          al.floor,
          al.rent,
          fp.sqft,
          fp.beds,
          fp.sqft::numeric / al.rent AS sqft_per_dollar,
          fp.baths,
          al.movein,
          pp.created_at AS fetched_at,
          case when pp.daterank = 1 then 1 else 0 end AS current
        FROM apartment_listings al
        LEFT JOIN page_pulls_with_recency pp ON al.page_pull_id = pp.id
        LEFT JOIN floor_plans_ranked fp ON pp.trust::text = fp.trust::text AND pp.location::text = fp.location::text AND al.unitname::text = fp.name::text
        WHERE fp.daterank = 1),

        ranked AS 
        (SELECT 
          joined.trust,
          joined.location,
          joined.unitname,
          joined.unitnum,
          joined.floor,
          joined.rent,
          joined.sqft,
          joined.beds,
          joined.sqft_per_dollar,
          joined.baths,
          joined.movein,
          joined.fetched_at,
          joined.current,
          rank() OVER 
            (PARTITION BY 
              joined.trust,
              joined.location,
              joined.unitname,
              joined.unitnum,
              joined.rent,
              joined.movein
            ORDER BY 
              joined.fetched_at DESC,
              joined.sqft_per_dollar desc,
              uuid_generate_v4()) AS drank
        FROM joined)

        SELECT 
          ranked.trust,
          ranked.location,
          ranked.unitname,
          ranked.unitnum,
          ranked.floor,
          ranked.rent,
          ranked.sqft,
          ranked.beds,
          ranked.sqft_per_dollar,
          ranked.baths,
          ranked.movein,
          ranked.fetched_at,
          ranked.current,
          ranked.drank
        FROM ranked
        WHERE ranked.drank = 1
        ORDER BY ranked.location, ranked.unitname, ranked.unitnum, ranked.rent;

      CREATE VIEW unit_price_report as
      with pricereport as 
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
      from price_report),

      begindates as (select * from pricereport where bdaterank = 1),

      enddates as (select * from pricereport where edaterank = 1),

      dates as
      (select i::date date
      from generate_series((select fetched_on from pricereport order by fetched_on limit 1),(select fetched_on from pricereport order by fetched_on desc limit 1),'1 day'::interval) i),

      pricereport_datedelimited as
      (select
        p.trust,
        p.location,
        p.unitname,
        p.unitnum,
        b.fetched_on as begindate,
        e.fetched_on as enddate
      from pricereport p
      join begindates b on p.trust = b.trust and p.location = b.location and p.unitname = b.unitname and p.unitnum = b.unitnum
      join enddates e on p.trust = e.trust and p.location = b.location and p.unitname = e.unitname and p.unitnum = e.unitnum
      group by p.trust,p.location,p.unitname,p.unitnum,b.fetched_on,e.fetched_on),

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
        rank() over (partition by i.trust, i.location, i.unitname, i.unitnum, i.date order by p.fetched_at desc) daterank,
        p.fetched_at,
        i.date = p.fetched_on priceupdated
      from idx i
      left outer join pricereport p 
      on i.trust = p.trust
      and i.location = p.location
      and i.unitname = p.unitname
      and i.unitnum = p.unitnum
      and i.date >= p.fetched_on
      order by i.trust,i.location,i.unitname,i.unitnum,i.date)

      select
        trust,
        location,
        unitname,
        unitnum,
        date,
        rent,
        movein,
        priceupdated
      from idx_ranked_joined
      where daterank = 1;
    SQL
  end
  def down
    execute <<-SQL
      DROP VIEW unit_price_report;
      DROP VIEW price_report;

      CREATE OR REPLACE VIEW price_report AS 
      WITH page_pulls_with_recency as
      (select 
        id,
        trust,
        location,
        url,
        html,
        created_at,
        updated_at,
        rank() over (partition by location order by created_at desc) daterank
      from page_pulls),

      floor_plans_ranked AS 
      (SELECT 
        floor_plans.trust,
        floor_plans.location,
        floor_plans.name,
        floor_plans.beds,
        floor_plans.baths,
        floor_plans.sqft,
        floor_plans.created_at,
        rank() OVER 
          (PARTITION BY 
            floor_plans.trust,
            floor_plans.location,
            floor_plans.name,
            floor_plans.beds,
            floor_plans.baths,
            floor_plans.sqft 
          ORDER BY
            floor_plans.created_at) AS daterank
      FROM floor_plans),

      joined AS 
      (SELECT 
        pp.trust,
        pp.location,
        al.unitname,
        al.unitnum,
        al.floor,
        al.rent,
        fp.sqft,
        fp.beds,
        fp.sqft::numeric / al.rent AS sqft_per_dollar,
        fp.baths,
        al.movein,
        pp.created_at AS fetched_at,
        case when pp.daterank = 1 then 1 else 0 end AS current
      FROM apartment_listings al
      LEFT JOIN page_pulls_with_recency pp ON al.page_pull_id = pp.id
      LEFT JOIN floor_plans_ranked fp ON pp.trust::text = fp.trust::text AND pp.location::text = fp.location::text AND al.unitname::text = fp.name::text
      WHERE fp.daterank = 1),

      ranked AS 
      (SELECT 
        joined.trust,
        joined.location,
        joined.unitname,
        joined.unitnum,
        joined.floor,
        joined.rent,
        joined.sqft,
        joined.beds,
        joined.sqft_per_dollar,
        joined.baths,
        joined.movein,
        joined.fetched_at,
        joined.current,
        rank() OVER 
          (PARTITION BY 
            joined.trust,
            joined.location,
            joined.unitname,
            joined.rent,
            joined.movein
          ORDER BY 
            joined.fetched_at DESC,
            joined.sqft_per_dollar desc,
            uuid_generate_v4()) AS drank
      FROM joined)

      SELECT 
        ranked.trust,
        ranked.location,
        ranked.unitname,
        ranked.unitnum,
        ranked.floor,
        ranked.rent,
        ranked.sqft,
        ranked.beds,
        ranked.sqft_per_dollar,
        ranked.baths,
        ranked.movein,
        ranked.fetched_at,
        ranked.current,
        ranked.drank
      FROM ranked
      WHERE ranked.drank = 1
      ORDER BY ranked.location, ranked.unitname, ranked.unitnum, ranked.rent;

      CREATE VIEW unit_price_report as
      with pricereport as 
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
      from price_report),

      begindates as (select * from pricereport where bdaterank = 1),

      enddates as (select * from pricereport where edaterank = 1),

      dates as
      (select i::date date
      from generate_series((select fetched_on from pricereport order by fetched_on limit 1),(select fetched_on from pricereport order by fetched_on desc limit 1),'1 day'::interval) i),

      pricereport_datedelimited as
      (select
        p.trust,
        p.location,
        p.unitname,
        p.unitnum,
        b.fetched_on as begindate,
        e.fetched_on as enddate
      from pricereport p
      join begindates b on p.trust = b.trust and p.location = b.location and p.unitname = b.unitname and p.unitnum = b.unitnum
      join enddates e on p.trust = e.trust and p.location = b.location and p.unitname = e.unitname and p.unitnum = e.unitnum
      group by p.trust,p.location,p.unitname,p.unitnum,b.fetched_on,e.fetched_on),

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
        rank() over (partition by i.trust, i.location, i.unitname, i.unitnum, i.date order by p.fetched_at desc) daterank,
        p.fetched_at,
        i.date = p.fetched_on priceupdated
      from idx i
      left outer join pricereport p 
      on i.trust = p.trust
      and i.location = p.location
      and i.unitname = p.unitname
      and i.unitnum = p.unitnum
      and i.date >= p.fetched_on
      order by i.trust,i.location,i.unitname,i.unitnum,i.date)

      select
        trust,
        location,
        unitname,
        unitnum,
        date,
        rent,
        movein,
        priceupdated
      from idx_ranked_joined
      where daterank = 1;
    SQL
  end
end
