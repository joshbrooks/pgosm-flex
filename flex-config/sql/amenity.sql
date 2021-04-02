COMMENT ON TABLE osm.amenity_point IS 'OpenStreetMap amenity points - all points with an amenity tag.  Some amenity tags are pulled into other tables (e.g. infrastructure, shop, and traffic layers) and duplicated again here. This is currently intentional but may change in the future. Generated by osm2pgsql Flex output using pgosm-flex/flex-config/amenity.lua';
COMMENT ON TABLE osm.amenity_line IS 'OpenStreetMap amenity lines - all lines with an amenity tag.  Some amenity tags are pulled into other tables (e.g. infrastructure, shop, and traffic layers) and duplicated again here. This is currently intentional but may change in the future. Generated by osm2pgsql Flex output using pgosm-flex/flex-config/amenity.lua';
COMMENT ON TABLE osm.amenity_polygon IS 'OpenStreetMap amenity polygons - all polygons with an amenity tag.  Some amenity tags are pulled into other tables (e.g. infrastructure, shop, and traffic layers) and duplicated again here. This is currently intentional but may change in the future. Generated by osm2pgsql Flex output using pgosm-flex/flex-config/amenity.lua';


ALTER TABLE osm.amenity_point
    ADD CONSTRAINT pk_osm_amenity_point_osm_id
    PRIMARY KEY (osm_id)
;
ALTER TABLE osm.amenity_line
    ADD CONSTRAINT pk_osm_amenity_line_osm_id
    PRIMARY KEY (osm_id)
;
ALTER TABLE osm.amenity_polygon
    ADD CONSTRAINT pk_osm_amenity_polygon_osm_id
    PRIMARY KEY (osm_id)
;


CREATE INDEX ix_osm_amenity_point_type ON osm.amenity_point (osm_type);
CREATE INDEX ix_osm_amenity_line_type ON osm.amenity_line (osm_type);
CREATE INDEX ix_osm_amenity_polygon_type ON osm.amenity_polygon (osm_type);


COMMENT ON COLUMN osm.amenity_point.osm_id IS 'OpenStreetMap ID. Unique along with geometry type.';
COMMENT ON COLUMN osm.amenity_line.osm_id IS 'OpenStreetMap ID. Unique along with geometry type.';
COMMENT ON COLUMN osm.amenity_polygon.osm_id IS 'OpenStreetMap ID. Unique along with geometry type.';

COMMENT ON COLUMN osm.amenity_point.housenumber IS 'Value from addr:housenumber tag';
COMMENT ON COLUMN osm.amenity_point.street IS 'Value from addr:street tag';
COMMENT ON COLUMN osm.amenity_point.city IS 'Value from addr:city tag';
COMMENT ON COLUMN osm.amenity_point.state IS 'Value from addr:state tag';

COMMENT ON COLUMN osm.amenity_line.housenumber IS 'Value from addr:housenumber tag';
COMMENT ON COLUMN osm.amenity_line.street IS 'Value from addr:street tag';
COMMENT ON COLUMN osm.amenity_line.city IS 'Value from addr:city tag';
COMMENT ON COLUMN osm.amenity_line.state IS 'Value from addr:state tag';

COMMENT ON COLUMN osm.amenity_polygon.housenumber IS 'Value from addr:housenumber tag';
COMMENT ON COLUMN osm.amenity_polygon.street IS 'Value from addr:street tag';
COMMENT ON COLUMN osm.amenity_polygon.city IS 'Value from addr:city tag';
COMMENT ON COLUMN osm.amenity_polygon.state IS 'Value from addr:state tag';

COMMENT ON COLUMN osm.amenity_point.name IS 'Best name option determined by helpers.get_name(). Keys with priority are: name, short_name, alt_name and loc_name.  See pgosm-flex/flex-config/helpers.lua for full logic of selection.';
COMMENT ON COLUMN osm.amenity_line.name IS 'Best name option determined by helpers.get_name(). Keys with priority are: name, short_name, alt_name and loc_name.  See pgosm-flex/flex-config/helpers.lua for full logic of selection.';
COMMENT ON COLUMN osm.amenity_polygon.name IS 'Best name option determined by helpers.get_name(). Keys with priority are: name, short_name, alt_name and loc_name.  See pgosm-flex/flex-config/helpers.lua for full logic of selection.';

COMMENT ON COLUMN osm.amenity_point.geom IS 'Geometry loaded by osm2pgsql.';
COMMENT ON COLUMN osm.amenity_line.geom IS 'Geometry loaded by osm2pgsql.';
COMMENT ON COLUMN osm.amenity_polygon.geom IS 'Geometry loaded by osm2pgsql.';

COMMENT ON COLUMN osm.amenity_point.address IS 'Address combined from address parts in helpers.get_address().';
COMMENT ON COLUMN osm.amenity_line.address IS 'Address combined from address parts in helpers.get_address().';
COMMENT ON COLUMN osm.amenity_polygon.address IS 'Address combined from address parts in helpers.get_address().';
