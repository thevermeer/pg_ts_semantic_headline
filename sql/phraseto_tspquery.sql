/*
Function: PHRASETO_TSPQUERY

1:1 replacement for the built-in PHRASETO_TSQuery function:

Accepts 
- config       REGCONFIG - PGSQL Text Search Language Configuration
- query_string TEXT - a common language string as a phrase, or ordered 
                      combination of multiple words.

Returns a TSPQuery that represents the query phrase after its treament with 
TSP_INDEXABLE_TEXT. This is done to attain positional alignment between raw text
and the rendered TSVector. As we are searching on a treated vector, we need to treat
the phrase used to render a TSPQuery in the same way
*/

CREATE OR REPLACE FUNCTION PHRASETO_TSPQUERY(config REGCONFIG, query_string TEXT)
RETURNS TSPQUERY AS
$$
BEGIN
	RETURN PHRASETO_TSQUERY(config, TSP_INDEXABLE_TEXT(UNACCENT(query_string)))::TSPQuery;
END;
$$
STABLE
LANGUAGE plpgsql;

-- OVERLOAD Arity-2 form, to infer the default_text_search_config for parsing
CREATE OR REPLACE FUNCTION PHRASETO_TSPQUERY(query_string TEXT)
RETURNS TSPQUERY AS
$$
BEGIN    
    RETURN PHRASETO_TSPQUERY(current_setting('default_text_search_config')::REGCONFIG, 
	                         query_string);
END;
$$
STABLE
LANGUAGE plpgsql;
