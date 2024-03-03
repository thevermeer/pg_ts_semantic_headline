CREATE DOMAIN TSPQuery AS TSQuery 
NOT NULL CHECK (value::TEXT !~ '[\w+][\W+][\w]' AND UNACCENT(value::TEXT) = value::TEXT);

CREATE DOMAIN TSPVector AS TSVector 
NOT NULL CHECK (SELECT COUNT(*)=0 FROM UNNEST(TSVECTOR_TO_ARRAY(value)) AS lex, regexp_matches(lex, '\W', 'g'));