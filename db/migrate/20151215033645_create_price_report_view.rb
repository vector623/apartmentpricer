class CreatePriceReportView < ActiveRecord::Migration
  def up
    execute <<-SQL
      CREATE OR REPLACE VIEW price_report AS 
        WITH floor_plans_ranked AS 
        (SELECT 
          floor_plans.location,
          floor_plans.name,
          floor_plans.beds,
          floor_plans.baths,
          floor_plans.sqft,
          floor_plans.created_at,
          rank() OVER 
            (PARTITION BY 
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
          CASE
            WHEN rank() OVER (PARTITION BY pp.location, al.unitname ORDER BY pp.created_at DESC) = 1 THEN 1
            ELSE 0
          END AS current
        FROM apartment_listings al
        LEFT JOIN page_pulls pp ON al.page_pull_id = pp.id
        LEFT JOIN floor_plans_ranked fp ON pp.location::text = fp.location::text AND al.unitname::text = fp.name::text
        WHERE fp.daterank = 1),

        ranked AS 
        (SELECT 
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
              joined.location,
              joined.unitname,
              joined.rent,
              joined.movein
            ORDER BY 
              joined.fetched_at DESC,
              uuid_generate_v4()) AS drank
        FROM joined)

        SELECT 
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
    SQL
  end

  def down
    execute "DROP VIEW price_report;"
  end
end
