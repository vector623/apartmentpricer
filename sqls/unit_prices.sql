with fp as
(select
  name,
  sqft,
  rank() over (partition by name,sqft order by created_at desc) r
from floor_plans),

a as 
(select 
  a.page_pull_id,
  a.unitname,
  a.unitnum,
  a.floor,
  fp.sqft,
  a.rent,
  a.movein,
  rank() over (partition by a.unitname,a.unitnum,a.rent order by a.created_at desc) r 
from apartment_listings a
join fp on a.unitname = fp.name and fp.r = 1
order by created_at) 

select 
  pp.trust,
  pp.location,
  a.unitname,
  a.unitnum,
  a.floor,
  a.sqft,
  a.rent,
  a.movein,
  pp.created_at
from a
join page_pulls pp on a.page_pull_id = pp.id
where a.r = 1 
order by a.unitname,a.unitnum;
