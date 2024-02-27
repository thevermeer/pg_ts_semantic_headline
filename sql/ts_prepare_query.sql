/*
Function: ts_prepare_query

TODO :: Write me!
*/

CREATE OR REPLACE FUNCTION ts_prepare_query(config REGCONFIG, query_string TEXT)
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

CREATE OR REPLACE FUNCTION ts_prepare_query(query_string TEXT)
RETURNS TSQUERY AS
$$
BEGIN    
    RETURN ts_prepare_query(current_setting('default_text_search_config')::REGCONFIG, 
	                        query_string);
END;
$$
STABLE
LANGUAGE plpgsql;
