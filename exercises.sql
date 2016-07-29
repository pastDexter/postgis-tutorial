---------------------------
 --   NEIGHBOURHOODS
---------------------------

-- 1. Dzielnice według powierzchni
SELECT name, ST_AREA(n.geom, true) AS area
FROM neighbourhoods n
ORDER BY area DESC;

-- 2. Dzielnice które graniczą ze śródmieściem
SELECT name
FROM neighbourhoods n
WHERE ST_Intersects(
  n.geom,
  (SELECT geom FROM neighbourhoods WHERE name='Śródmieście')
)
AND name!='Śródmieście';

-- 3. W jakiej dzielnicy jestem?
SELECT name
FROM neighbourhoods n
WHERE ST_Within(
  ST_SetSRID(ST_MakePoint(20.983845407157453, 52.2320838793046), 4326),
  n.geom
);

-----------------
--   TRAMS
-----------------

-- 4. Długość wszystkich linii tramwajowych w Warszawie w km
SELECT ST_length(ST_union(geom), true) / 1000 FROM routes;

-- 5. Tramwaj który przejeżdża przez największą ilość dzielnic
SELECT
  l.name,
  COUNT(DISTINCT n.id) as count FROM lines l
JOIN lines_routes lr ON lr.line_id = l.id
JOIN routes r ON r.id = lr.route_id
JOIN neighbourhoods n ON ST_INTERSECTS(n.geom, r.geom)
GROUP BY l.name
ORDER BY count DESC
LIMIT 1;

-- 6. Linie tramwajowe które przejeżdząją przez Wolę i Żoliborz
SELECT
  l.id,
  string_agg(DISTINCT n.name, ', ')
FROM lines l
JOIN lines_routes lr ON lr.line_id = l.id
JOIN routes r ON r.id = lr.route_id
JOIN neighbourhoods n ON ST_INTERSECTS(n.geom, r.geom)
GROUP BY l.id
HAVING array_agg(n.name) @> '{Wola, Żoliborz}'::varchar[];

------------------
--     POKI
------------------

-- 7. 5 najbliższych pokemonów (nazwa i odległość)
SELECT
  pt.name,
  ST_distance(
    p.geom,
    ST_SetSRID(ST_MakePoint(20.983845407157453, 52.2320838793046), 4326),
    true
  ) as distance
FROM pokemons p
JOIN pokemon_types pt ON pt.id = p.pokemon_type_id
ORDER BY distance ASC
LIMIT 5;

-- 8. Ilość poków na dzielnicy / km2
SELECT
  n.name,
  (COUNT(p.id) / (ST_Area(n.geom, true) / 1000000)) as density
from neighbourhoods n
join pokemons p on st_within(p.geom, n.geom)
group by n.name, n.geom order by density desc;

-- 9.
SELECT
  l.id,
  COUNT(DISTINCT p.id)
FROM lines l
JOIN lines_routes lr ON lr.line_id = l.id
JOIN routes r ON r.id = lr.route_id
JOIN neighbourhoods n ON ST_INTERSECTS(n.geom, r.geom)
JOIN pokemons p ON ST_DWithin(p.geom, r.geom, 300, true)
GROUP BY l.id
HAVING array_agg(n.name) @> '{Wola, Żoliborz}'::varchar[]
ORDER BY count DESC
LIMIT 1;
