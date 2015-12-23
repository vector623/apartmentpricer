with al as 
(select 
  pp.trust,
  pp.location,
  a.page_pull_id,
  a.unitname,
  a.unitnum,
  a.floor,
  a.rent,
  a.movein,
  rank() over (partition by pp.trust,pp.location,a.unitname,a.unitnum,a.rent order by a.created_at desc) r 
from apartment_listings a
left outer join page_pulls pp on a.page_pull_id = pp.id
order by pp.created_at)

select 
  al.trust,
  al.location,
  al.unitname,
  fp.sqft,
  al.unitnum,
  al.floor,
  al.rent,
  al.movein,
  pp.created_at
from al
left outer join floor_plans fp on al.page_pull_id = fp.page_pull_id and al.location = fp.location and al.unitname = fp.name
left outer join page_pulls pp on al.page_pull_id = pp.id
where al.r = 1 
order by al.trust,al.location,al.unitname,al.unitnum,pp.created_at
