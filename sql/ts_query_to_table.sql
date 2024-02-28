CREATE OR REPLACE FUNCTION ts_query_to_table(config REGCONFIG, input_query TSQUERY)
RETURNS TABLE(phrase_vector TSVECTOR, phrase_query TSQUERY, lexeme TEXT, pos SMALLINT) AS
$$
BEGIN
	RETURN QUERY 
	(WITH phrases AS (SELECT phrase.phrase_vector, phrase.phrase_query 
	                  FROM ts_query_to_ts_vector(config, input_query) AS phrase)
     SELECT phrases.phrase_vector, 
            phrases.phrase_query,
            word.lex, 
            word.pos
     FROM phrases, ts_vector_to_table(phrases.phrase_vector) AS word);
END;
$$
STABLE
LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION ts_query_to_table(input_query TSQUERY)
RETURNS TABLE(phrase_vector TSVECTOR, phrase_query TSQUERY, lexeme TEXT, pos SMALLINT) AS
$$
BEGIN
	RETURN QUERY 
	(SELECT * FROM ts_query_to_table(current_setting('default_text_search_config')::REGCONFIG, 
                                        input_query));
END;
$$
STABLE
LANGUAGE plpgsql;