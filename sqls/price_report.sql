with floor_plans_ranked as
(select 
	location,
	name,
	beds,
	baths,
	sqft,
	created_at,
	rank() over (partition by location,name,beds,baths,sqft order by created_at,uuid_generate_v4()) daterank
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
where fp.daterank = 1)

select *
from joined
order by location,unitname,unitnum,fetched_at;

/*
I'm thinking of two scatterplots: x=moveindate, y=price and x=moveindate, y=$/sqft; make 3 different colors,
one for each bedroomtype (1, 2 or 3).  Then tooltip the rest of the data.

Double scatterplot sets by showing past entries against current ones (make sure to use a duller color for past
entries)

OR: bubble chart, with size of bubble as $/sqft (inverse this) -> I am a genius
*/
