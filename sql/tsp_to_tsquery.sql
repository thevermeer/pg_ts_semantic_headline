/*
Function: tsp_to_tsquery

Akin to the builtin function `to_tsquery`, this function converts text to a 
tsquery, normalizing words according to the specified or default configuration. 
The words must be combined by valid tsquery operators.

tsp_to_tsquery('english', 'The & Fat & Rats') → 'fat' & 'rat'

For the purposes of a TSQuery, this function is the treatment for TSQueries for
index-friendly positioning and is paralleled with tsp_indexable_text in TSVectors
*/

CREATE OR REPLACE FUNCTION tsp_to_tsquery(config REGCONFIG, query_string TEXT)
RETURNS TSQUERY AS
$$
BEGIN
    -- We perform the chararacter substitution twice to catch any terms with 
	-- multiple character-delimiter substrings
	query_string := ' ' || query_string || ' ';
	query_string := regexp_replace(query_string, '(\w)([^[:alnum:]&^<>|\s]+)(\w)', E'\\1\\2\<1>\\3', 'g');
	query_string := regexp_replace(query_string, '(\w)([^[:alnum:]&^<>|\s]+)(\w)', E'\\1\\2\<1>\\3', 'g');	    
    
	RETURN TO_TSQUERY(config, query_string);
END;
$$
STABLE
LANGUAGE plpgsql;

-- OVERLOAD Arity-2 form, to infer the default_text_search_config for parsing
CREATE OR REPLACE FUNCTION tsp_to_tsquery(query_string TEXT)
RETURNS TSQUERY AS
$$
BEGIN    
    RETURN tsp_to_tsquery(current_setting('default_text_search_config')::REGCONFIG, 
	                        query_string);
END;
$$
STABLE
LANGUAGE plpgsql;
