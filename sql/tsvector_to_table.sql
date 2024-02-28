/*
Function: tsvector_to_table

Accepts: 
- input_vector TSVECTOR - a TSVector containing BOTH lexemes and positions 

Returns a table of the lexemes and positions of the TSVector, ordered by
position ASC. In effect, this function UNNESTs a TSVector into a table.
*/

CREATE OR REPLACE FUNCTION tsvector_to_table(input_vector TSVECTOR)
RETURNS TABLE(lex TEXT, pos SMALLINT) AS
$$
BEGIN
	RETURN QUERY (SELECT lexeme, UNNEST(positions) AS position 
		          FROM UNNEST(input_vector)  
		          ORDER BY position);
END;
$$
STABLE
LANGUAGE plpgsql;