/*
Function: TSQUERY_TO_TABLE

Accepts: 
- config      REGCONFIG - PGSQL Text Search Language Configuration
- input_query TEXT - the source text to be prepared, by having indexing tokens removed

Divides a TSQuery into phrases separated by logical operators. For each phrase, applies
TSQUERY_TO_TSVECTOR. For each resulting TSVector, we apply TSVECTOR_TO_TABLE.

Returns a table with each record representing a lexeme and position within a TSVector, 
and for posterity each row also contains a phrase_vector TSVECTOR and the corresponding 
phrase_query TSQUERY that produced the vector.

In effect, this divides the TSQuery into a series of equivalent lexeme patters in a TSVector.
*/

CREATE OR REPLACE FUNCTION TSQUERY_TO_TABLE(config REGCONFIG, input_query TSQUERY)
RETURNS TABLE(phrase_vector TSVECTOR, phrase_query TSQUERY, lexeme TEXT, pos SMALLINT) AS
$$
BEGIN
	RETURN QUERY 
	(WITH phrases AS (SELECT DISTINCT(phrase.phrase_vector), phrase.phrase_query 
	                  FROM TSQUERY_TO_TSVECTOR(config, input_query) AS phrase)
      SELECT phrases.phrase_vector, 
             phrases.phrase_query,
             word.lex, 
             word.pos
      FROM phrases, TSVECTOR_TO_TABLE(phrases.phrase_vector) AS word);
END;
$$
STABLE
LANGUAGE plpgsql;

-- OVERLOADS Arity-2 form, to infer the default_text_search_config for parsing
CREATE OR REPLACE FUNCTION TSQUERY_TO_TABLE(input_query TSQUERY)
RETURNS TABLE(phrase_vector TSVECTOR, phrase_query TSQUERY, lexeme TEXT, pos SMALLINT) AS
$$
BEGIN
	RETURN QUERY 
	(SELECT * FROM TSQUERY_TO_TABLE(current_setting('default_text_search_config')::REGCONFIG, 
                                       input_query));
END;
$$
STABLE
LANGUAGE plpgsql;