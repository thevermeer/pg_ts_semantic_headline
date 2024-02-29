CREATE OR REPLACE FUNCTION tsquery_to_table(config REGCONFIG, input_query TSQUERY)
RETURNS TABLE(phrase_vector TSVECTOR, phrase_query TSQUERY, lexeme TEXT, pos SMALLINT) AS
$$
BEGIN
	RETURN QUERY 
	(WITH phrases AS (SELECT phrase.phrase_vector, phrase.phrase_query 
	                  FROM tsquery_to_tsvector(config, input_query) AS phrase)
     SELECT phrases.phrase_vector, 
            phrases.phrase_query,
            word.lex, 
            word.pos
     FROM phrases, tsvector_to_table(phrases.phrase_vector) AS word);
END;
$$
STABLE
LANGUAGE plpgsql;

-- OVERLOAD Arity-2 form, to infer the default_text_search_config for parsing
CREATE OR REPLACE FUNCTION tsquery_to_table(input_query TSQUERY)
RETURNS TABLE(phrase_vector TSVECTOR, phrase_query TSQUERY, lexeme TEXT, pos SMALLINT) AS
$$
BEGIN
	RETURN QUERY 
	(SELECT * FROM tsquery_to_table(current_setting('default_text_search_config')::REGCONFIG, 
                                        input_query));
END;
$$
STABLE
LANGUAGE plpgsql;