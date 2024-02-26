CREATE OR REPLACE FUNCTION ts_vector_to_table(input_vector TSVECTOR)
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