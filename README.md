# 1. Instalacja

Instalujemy PostGIS'a zgodnie z instrukcjami zawartymi na stronie: [http://postgis.net/install/](http://postgis.net/install/)

Następnie tworzymy nową bazę danych:

    =# CREATE DATABASE postgis_test;

PostGIS jest opcjonalnym rozszerzeniem dlatego konieczne będzie aktywowanie go dla naszej nowostworzonej bazy:

    =# \c postgis-test
    You are now connected to database "postgis_test"
    postgis-test=# CREATE EXTENSION postgis;
    CREATE EXTENSION

## 1.1 Integracja z Rails

Mimo że przykłady przedstawione w tym tutorialu będą dotyczyć jedynie Postgresa, to pewnie wiele osób jest zainteresowanych możliwością używania PostGIS'a z aplikacjami pisanymi w Ruby on Rails. Z pomoca przychodzi gem
`activerecord-postgis-adapter`, który pozwala na łatwą integrację PostGIS'owych typów danych z biblioteką `RGeo`.

Dodajemy gema do Gemfile:

    gem 'activerecord-postgis-adapter'

A następnie w `config/database.yml` ustawiamy:

    development:
      database:     postgis-test
      adapter:      postgis
      host:         localhost
      ...

# 2. Typy danych

To co najważniejsze w PostGISie to obsługa przestrzennych typów danych i operacje na nich. Zgodnie ze specyfikacją OpenGIS ich reprezentacje w bazie danych zapisane są wewnętrzenie w formacie WKB (well-known binary), i łatwo konwertowalne do "przyjaźniejszego" dla ludzi formatu WKT (well-known text).

Wyróżniamy podstawowe typy obiektów przestrzennych:

- **Punkt**: `POINT(0 0)`
- **Linia łamana**: `LINESTRING(0 0,1 1,1 2)`
- **Wielokąt**: `POLYGON((0 0,4 0,4 4,0 4,0 0),(1 1, 2 1, 2 2, 1 2,1 1))`
- Zbiór punktów: `MULTIPOINT(0 0,1 2)`
- Zbiór linii: `MULTILINESTRING((0 0,1 1,1 2),(2 3,3 2,5 4))`
- Zbiór wielkątów: `MULTIPOLYGON(((0 0,4 0,4 4,0 4,0 0)), ((-1 -1,-1 -2,-2 -2,-2 -1,-1 -1)))`
- Zbiór obiektów: `GEOMETRYCOLLECTION(POINT(2 3),LINESTRING(2 3,3 4))`

# 3. Funkcje

PostGIS udostępnia nam szereg funkcji pozwalających na operacje, analizę i wylicznia na przestrzennych typach danych. Pełną ich listę można oczywiście znaleźć w [dokumentacji](http://postgis.net/docs/manual-1.3/ch06.html), ale chciałbym teraz przedstawić klika podstawowych i najczęściej używanych.

## 3.1 Konstruktory

- `ST_GeomFromText(text,[<srid>])`
- `ST_MakePoint(<x>, <y>, [<z>], [<m>])`
- `ST_MakeLine(geometry, geometry)   ST_MakeLine(geometry set)`
- `ST_MakePolygon(linestring, [linestring[]])`

## 3.2 Obliczenia

- `ST_Distance(geometry, geometry, use_spheroid)`
- `ST_length(geometry, use_spheroid)`
- `ST_Area(geometry, use_spheroid)`

## 3.2 Predykaty

- `ST_Intersects(geometry, geometry)`
- `ST_Crosses(geometry, geometry)`
- `ST_Within(geometry A, geometry B)`
- `ST_DWithin(geometry, geometry, float, use_spheroid)`

## 3.1 Konwersje i reprezentacje danych

- `ST_AsText(geometry)`
- `ST_SRID(geometry)`
- `ST_X(geometry)  ST_Y(geometry)`
- `ST_AsGeoJson([version], geometry, [precision], [options])`

# 4. Let's write some SQL!

Na potrzeby tego kursu przygotowałem kilka paczek danych które pozwolą nam pobawić się podstawowymi funkcjami PostGIS'a w praktyce.

## 4.1 Dzielnice

Pierwsza z nich to dane dzielnic Warszawy *(nazwy i obrys ich granic w formacie WKT)* wyeksportowane z bazy OpenStreetMaps `data/insert_neighbourhoods.sql`

    CREATE TABLE neighbourhoods (
      id SERIAL PRIMARY KEY,
      name VARCHAR(128),
      population INTEGER,
      geom GEOMETRY(Polygon,4326)
    );

Tworzymy tabelę według powyższego schematu (zwróćmy uwagę na użycie typu danych GEOMETRY z parametrem Polygon i SRID 4326) i ładujemy dane z pliku `data/insert_neighbourhoods.sql`

    postgis-test=# \i /foo/bar/data/insert_neighbourhoods.sql

### Ćwiczenia

1. Posortuj dzielnice według powierzchni (nazwa + powierzchnia[km2])
2. Lista dzielnic, które graniczą ze śródmieściem
3. W jakiej dzielnicy jestem? (lat: `52.2320838793046`, lon: `20.983845407157453`)

## 4.2 Linie tramawajowe

Tworzymy 3 tabele według poniższego schematu:

    CREATE TABLE routes (
      id integer NOT NULL,
      geom geometry(LineString,4326)
    );

    CREATE TABLE lines (
      id integer NOT NULL,
      name character varying(256)
    );

    CREATE TABLE lines_routes (
      route_id integer,
      line_id integer
    );

Ładujemy dane:

    postgis-test=# \i /foo/bar/data/insert_routes.sql
    postgis-test=# \i /foo/bar/data/insert_lines.sql
    postgis-test=# \i /foo/bar/data/insert_lines_routes.sql

### Ćwiczenia

4. Długość wszystkich linii tramwajowych w Warszawie w km
5. Tramwaj który przejeżdża przez największą ilość dzielnic
6. Linie tramwajowe które przejeżdząją przez Wolę i Żoliborz

## 4.3 Pokemony :D

Ostatnią paczką danych są super tajne lokalizacje pokemonów na mapie Warszawy.
Potrzebujemy tabeli przechowującej ich typy:

    CREATE TABLE pokemon_types (
      id SERIAL PRIMARY KEY,
      name VARCHAR(256)
    );

I lokalizacje zapisane jako współrzędne gograficzne `lat`, `lon` w strukturze `Point`:

    CREATE TABLE pokemons (
      id SERIAL PRIMARY KEY,
      geom GEOMETRY(Point, 4326),
      pokemon_type_id int
    );

Tak jak we wcześniejszych przykładach ładujemy dane z pliku:

    postgis-test=# \i /foo/bar/data/insert_pokemon_types.sql
    postgis-test=# \i /foo/bar/data/insert_pokemons.sql

### Ćwiczenia *(tylko dla prawdziwych trenerów)*

7. Wyświetl 5 najbliższych pokemonów *(nazwa i odległość)*
8. Ilość pokemonów na dzielnicy / km2
9. **[FINAL TEST]** Tramwaj z Woli na Żoliborz z największą ilością pokemonów po drodze *(w odległości <= 300m od linii tramwajowej)*




(*rozwiązania wszystkich ćwiczeń na branchu `solutions`*)
