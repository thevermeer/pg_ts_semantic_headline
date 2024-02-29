/*
Function: tsp_phraseto_tsquery

1:1 replacement for the built-in PHRASETO_TSQuery function:

Accepts a common language string as a phrase, or ordered combination of multiple 
words.

Returns a TSQuery that represents the query phrase after its treament with 
tsp_indexable_text. This is done to attain positional alignment between raw text
and the rendered TSVector. As we are searching on a treated vector, we need to treat
the phrase used to render a TSQuery in the same way
*/

CREATE OR REPLACE FUNCTION tsp_phraseto_tsquery(config REGCONFIG, query_string TEXT)
RETURNS TSQUERY AS
$$
BEGIN
	RETURN PHRASETO_TSQUERY(config, tsp_indexable_text(query_string));
END;
$$
STABLE
LANGUAGE plpgsql;

-- OVERLOAD Arity-2 form, to infer the default_text_search_config for parsing
CREATE OR REPLACE FUNCTION tsp_phraseto_tsquery(query_string TEXT)
RETURNS TSQUERY AS
$$
BEGIN    
    RETURN tsp_to_tsquery(current_setting('default_text_search_config')::REGCONFIG, 
	                      query_string);
END;
$$
STABLE
LANGUAGE plpgsql;
