/*
Function: TO_TSPQUERY

Accepts:
- config       REGCONFIG - PGSQL Text Search Language Configuration
- query_string TEXT      - String of search terms connected with TSQuery
                           operators.

Akin to the builtin function `to_tsquery`, this function converts text to a 
tsquery, normalizing words according to the specified or default configuration. 
The words must be combined by valid tsquery operators.

TO_TSPQUERY('english', 'The & Fat & Rats') → 'fat' & 'rat'

For the purposes of a TSQuery, this function is the treatment for TSQueries for
index-friendly positioning and is paralleled with TSP_INDEXABLE_TEXT in TSVectors
*/

CREATE OR REPLACE FUNCTION TO_TSPVECTOR(config REGCONFIG, string TEXT)
RETURNS TSPVECTOR AS
$$
BEGIN
	RETURN TO_TSVECTOR(config, TSP_INDEXABLE_TEXT(unaccent(string)))::TSPVECTOR;
END;
$$
STABLE
LANGUAGE plpgsql;

-- OVERLOAD Arity-2 form, to infer the default_text_search_config for parsing
CREATE OR REPLACE FUNCTION TO_TSPVECTOR(string TEXT)
RETURNS TSPVECTOR AS
$$
BEGIN    
    RETURN TO_TSPVECTOR(current_setting('default_text_search_config')::REGCONFIG, 
	                       string);
END;
$$
STABLE
LANGUAGE plpgsql;
