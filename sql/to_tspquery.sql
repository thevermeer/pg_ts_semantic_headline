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
index-friendly positioning and is paralleled with tsp_indexable_text in TSVectors
*/

CREATE OR REPLACE FUNCTION TO_TSPQUERY(config REGCONFIG, query_string TEXT)
RETURNS TSPQuery AS
$$
BEGIN
    -- We perform the chararacter substitution twice to catch any terms with 
	-- multiple character-delimiter substrings
	query_string := ' ' || UNACCENT(query_string) || ' ';
	query_string := regexp_replace(query_string, '(\w)([^[:alnum:]&^<>|\s]+)(\w)', E'\\1\\2\<1>\\3', 'g');
	query_string := regexp_replace(query_string, '(\w)([^[:alnum:]&^<>|\s]+)(\w)', E'\\1\\2\<1>\\3', 'g');	    
    
	RETURN TO_TSQUERY(config, query_string);
END;
$$
STABLE
LANGUAGE plpgsql;

-- OVERLOAD Arity-2 form, to infer the default_text_search_config for parsing
CREATE OR REPLACE FUNCTION TO_TSPQUERY(query_string TEXT)
RETURNS TSPQuery AS
$$
BEGIN    
    RETURN TO_TSPQUERY(current_setting('default_text_search_config')::REGCONFIG, 
	                        query_string);
END;
$$
STABLE
LANGUAGE plpgsql;
