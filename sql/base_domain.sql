CREATE DOMAIN TSPQuery AS TSQuery 
NOT NULL CHECK (value::TEXT !~ '[\w+][\W+][\w]' AND UNACCENT(value::TEXT) = value::TEXT);
