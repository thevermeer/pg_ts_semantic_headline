/*
Function: tsquery_to_table

Accepts: 
- config      REGCONFIG - PGSQL Text Search Language Configuration
- input_query TEXT - the source text to be prepared, by having indexing tokens removed

Divides a TSQuery into phrases separated by logical operators. For each phrase, applies
tsquery_to_tsvector. For each resulting TSVector, we apply tsvector_to_table.

Returns a table with each record representing a lexeme and position within a TSVector, 
and for posterity each row also contains a phrase_vector TSVECTOR and the corresponding 
phrase_query TSQUERY that produced the vector.

In effect, this divides the TSQuery into a series of equivalent lexeme patters in a TSVector.
*/

CREATE OR REPLACE FUNCTION tsquery_to_table(config REGCONFIG, input_query TSQUERY)
RETURNS TABLE(phrase_vector TSVECTOR, phrase_query TSQUERY, lexeme TEXT, pos SMALLINT) AS
$$
BEGIN
	RETURN QUERY 
	(WITH phrases AS (SELECT DISTINCT(phrase.phrase_vector), phrase.phrase_query 
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

-- OVERLOADS Arity-2 form, to infer the default_text_search_config for parsing
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