/*
Function: tsp_to_tsquery

Accepts:
- config       REGCONFIG - PGSQL Text Search Language Configuration
- query_string TEXT      - String of search terms connected with TSQuery
                           operators.

Akin to the builtin function `to_tsquery`, this function converts text to a 
tsquery, normalizing words according to the specified or default configuration. 
The words must be combined by valid tsquery operators.

tsp_to_tsquery('english', 'The & Fat & Rats') → 'fat' & 'rat'

For the purposes of a TSQuery, this function is the treatment for TSQueries for
index-friendly positioning and is paralleled with tsp_indexable_text in TSVectors
*/

CREATE OR REPLACE FUNCTION tsp_to_tsvector(config REGCONFIG, string TEXT)
RETURNS TSVECTOR AS
$$
BEGIN
	RETURN TO_TSVECTOR(config, tsp_indexable_text(unaccent(string)));
END;
$$
STABLE
LANGUAGE plpgsql;

-- OVERLOAD Arity-2 form, to infer the default_text_search_config for parsing
CREATE OR REPLACE FUNCTION tsp_to_tsvector(string TEXT)
RETURNS TSVECTOR AS
$$
BEGIN    
    RETURN tsp_to_tsvector(current_setting('default_text_search_config')::REGCONFIG, 
	                       string);
END;
$$
STABLE
LANGUAGE plpgsql;
