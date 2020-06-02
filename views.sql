GRANT SELECT ON TABLE osm.hamburg_line TO b4_lesend;
GRANT SELECT ON TABLE osm.hamburg_nodes TO b4_lesend;
GRANT SELECT ON TABLE osm.hamburg_point TO b4_lesend;
GRANT SELECT ON TABLE osm.hamburg_polygon TO b4_lesend;
GRANT SELECT ON TABLE osm.hamburg_rels TO b4_lesend;
GRANT SELECT ON TABLE osm.hamburg_roads TO b4_lesend;
GRANT SELECT ON TABLE osm.hamburg_ways TO b4_lesend;

drop view if exists strassen;
create view strassen as
select
osm_id,
highway,
ref,
name,
lanes, 
surface,
maxspeed,
tags->'zone:maxspeed' as zone,
oneway,
"oneway:bicycle" as oneway_bicycle,
CASE 
WHEN tunnel = 'yes' THEN 'tunnel'
WHEN bridge = 'yes' THEN 'bridge'
END tunnel_bridge,
CONCAT('https://www.openstreetmap.org/way/',osm_id) link,
tags,
tags->'osm_timestamp' osm_timestamp,
way
from osm.hamburg_line where (access is null or access not in ('no','private')) and highway in
('living_street','motorway','motorway_link','primary','primary_link','residential','road','secondary','secondary_link','service','services','tertiary','tertiary_link','track','trunk','trunk_link','unclassified','yes');
GRANT SELECT ON TABLE osm.strassen TO b4_lesend;

drop view if exists wege;
create view wege as
select
osm_id,
highway,
name strassenname,
surface,
bicycle,
foot,
tags->'segregated' segregated,
oneway,
"oneway:bicycle" as oneway_bicycle,
CASE 
WHEN tags->'tunnel' = 'yes' THEN 'tunnel'
WHEN tags->'bridge' = 'yes' THEN 'bridge'
END tunnel_bridge,
CONCAT('https://www.openstreetmap.org/way/',osm_id) link,
tags,
tags->'osm_timestamp' osm_timestamp,
way
from osm.hamburg_line where highway is not null and (access is null or access not in ('no','private')) and highway not in
('living_street','motorway','motorway_link','primary','primary_link','residential','road','secondary','secondary_link','service','services','tertiary','tertiary_link','track','trunk','trunk_link','unclassified','yes');
GRANT SELECT ON TABLE osm.wege TO b4_lesend;


drop materialized view if exists osm.fahrrad;
create materialized view osm.fahrrad as
((select
osm_id,
highway,
name strassenname,
case when tags->'cycleway:surface' is not null then tags->'cycleway:surface'
else surface end surface,
bicycle,
foot,
tags->'segregated' segregated,
oneway,
"oneway:bicycle" as oneway_bicycle,
CASE 
WHEN tunnel = 'yes' THEN 'tunnel'
WHEN bridge = 'yes' THEN 'bridge'
END tunnel_bridge,
CONCAT('https://www.openstreetmap.org/way/',osm_id) link,
tags,
tags->'osm_timestamp' osm_timestamp,
way
from osm.hamburg_line where highway is not null and 
  (access is null or access not in ('no','private')) and 
  highway not in ('motorway','motorway_link','trunk','trunk_link') and 
  (bicycle is null or bicycle in ('yes','designated', 'permissive'))
)
union
(
--links
select
20000000000 + osm_id osm_id,
case
when tags->'cycleway:left' is not null then tags->'cycleway:left'
when tags->'cycleway' is not null then tags->'cycleway' END highway,
name strassenname,
case
when tags->'cycleway:surface:left' is not null then tags->'cycleway:surface:left'
when tags->'cycleway:surface' is not null then tags->'cycleway:surface' END surface,
'(yes)' bicycle,
case
when tags->'cycleway:foot:left' is not null then tags->'cycleway:foot:left'
when tags->'cycleway:foot' is not null then tags->'cycleway:foot' END foot,
null segregated,
oneway,
"oneway:bicycle" as oneway_bicycle,
CASE 
WHEN tunnel = 'yes' THEN 'tunnel'
WHEN bridge = 'yes' THEN 'bridge'
END tunnel_bridge,
CONCAT('https://www.openstreetmap.org/way/',osm_id) link,
tags,
tags->'osm_timestamp' osm_timestamp,
ST_OffsetCurve(way,  -5, 'quad_segs=4 join=round')
from osm.hamburg_line where highway is not null and (access is null or access not in ('no','private')) and 
(tags->'cycleway' is not null and tags->'cycleway' not in ('no','none', 'opposite') or
tags->'cycleway:left' is not null and tags->'cycleway:left' not in ('no','none'))
)
union
(
--rechts
select
10000000000 + osm_id osm_id,
case
when tags->'cycleway:left' is not null then tags->'cycleway:left'
when tags->'cycleway' is not null then tags->'cycleway' END highway,
name strassenname,
case
when tags->'cycleway:surface:right' is not null then tags->'cycleway:surface:right'
when tags->'cycleway:surface' is not null then tags->'cycleway:surface' END surface,
'(yes)' bicycle,
case
when tags->'cycleway:foot:right' is not null then tags->'cycleway:foot:right'
when tags->'cycleway:foot' is not null then tags->'cycleway:foot' END foot,
null segregated,
oneway oneway,
"oneway:bicycle" as oneway_bicycle,
CASE 
WHEN tunnel = 'yes' THEN 'tunnel'
WHEN bridge = 'yes' THEN 'bridge'
END tunnel_bridge,
CONCAT('https://www.openstreetmap.org/way/',osm_id) link,
tags,
tags->'osm_timestamp' osm_timestamp,
ST_OffsetCurve(way,  5, 'quad_segs=4 join=round')
from osm.hamburg_line where highway is not null and (access is null or access not in ('no','private')) and 
(tags->'cycleway' is not null and tags->'cycleway' not in ('no','none', 'opposite') or
tags->'cycleway:right' is not null and tags->'cycleway:right' not in ('no','none'))));

GRANT SELECT ON TABLE osm.fahrrad TO b4_lesend;

drop view if exists osm.einbahnfrei;
create view osm.einbahnfrei as select * from osm.strassen where oneway = 'yes' and oneway_bicycle = 'no';
GRANT SELECT ON TABLE osm.einbahnfrei TO b4_lesend;