class CreatePriceReportRankedlinesView < ActiveRecord::Migration
  def up
    execute <<-SQL
      CREATE OR REPLACE VIEW price_report_rankedlines AS
        WITH page_pulls_with_recency AS 
        (SELECT 
          page_pulls.id,
          page_pulls.trust,
          page_pulls.location,
          page_pulls.url,
          page_pulls.html,
          page_pulls.created_at,
          page_pulls.updated_at,
          rank() OVER 
            (PARTITION BY 
              page_pulls.location 
            ORDER BY 
              page_pulls.created_at DESC) AS daterank
        FROM page_pulls),

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
          CASE
            WHEN pp.daterank = 1 THEN 1
            ELSE 0
          END AS current
        FROM apartment_listings al
        LEFT JOIN page_pulls_with_recency pp 
          ON al.page_pull_id = pp.id
        LEFT JOIN floor_plans_ranked fp 
          ON pp.trust::text = fp.trust::text 
          AND pp.location::text = fp.location::text 
          AND al.unitname::text = fp.name::text
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
              joined.fetched_at::date
            ORDER BY
              joined.fetched_at,
              uuid_generate_v4()) AS earlydaterank,
          rank() OVER 
            (PARTITION BY 
              joined.trust,
              joined.location,
              joined.unitname,
              joined.unitnum,
              joined.fetched_at::date
            ORDER BY 
              joined.fetched_at DESC,
              uuid_generate_v4()) AS latedaterank
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
          ranked.earlydaterank,
          ranked.latedaterank
        FROM ranked
        ORDER BY 
          ranked.location,
          ranked.unitname,
          ranked.unitnum,
          ranked.fetched_at
    SQL
  end
  def down
    execute <<-SQL
      --DROP VIEW price_report_rankedlines;
    SQL
  end
end
