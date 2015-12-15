CREATE OR REPLACE VIEW public.price_report AS
with floor_plans_ranked as
(select 
	location,
	name,
	beds,
	baths,
	sqft,
	created_at,
	rank() over (partition by location,name,beds,baths,sqft order by created_at) daterank
from floor_plans),

joined as
(select
	pp.location,
	al.unitname,
	al.unitnum,
	al.floor,
	al.rent,
	fp.sqft,
	fp.beds,
	fp.sqft / al.rent as sqft_per_dollar,
	fp.baths,
	al.movein,
	pp.created_at as fetched_at,
	case
	  when rank() over (partition by pp.location,al.unitname order by pp.created_at desc) = 1 then 1
	  else 0
	end as current
from apartment_listings al
left outer join page_pulls pp on al.page_pull_id = pp.id
left outer join floor_plans_ranked fp on pp.location = fp.location and al.unitname = fp.name
where fp.daterank = 1),

ranked as
(select *,rank() over (partition by location,unitname,rent,movein order by fetched_at desc,uuid_generate_v4()) drank
from joined)

select *
from ranked
where drank = 1
order by location,unitname,unitnum,rent;

