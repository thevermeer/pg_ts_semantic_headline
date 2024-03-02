/*
Function: tsp_text_to_array

Simple wrapper function to ensure we split text arrays the same time, every time.
This is very much a convenience wrapper.
*/

CREATE OR REPLACE FUNCTION tsp_text_to_array(string TEXT)
RETURNS TEXT[] AS
$$
BEGIN
	RETURN REGEXP_SPLIT_TO_ARRAY(string, '[\s]+');
END;
$$
STABLE
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION tsp_index_array(string TEXT)
RETURNS TEXT[] AS
$$
BEGIN
	RETURN tsp_text_to_array(tsp_indexable_text(string));
END;
$$
STABLE
LANGUAGE plpgsql;

