/*
Function: tsp_to_text_array

Simple wrapper function to ensure we split text arrays the same time, every time.
This is very much a convenience wrapper.
*/

CREATE OR REPLACE FUNCTION tsp_to_text_array(string TEXT)
RETURNS TEXT[] AS
$$
BEGIN
	RETURN REGEXP_SPLIT_TO_ARRAY(tsp_indexable_text(string), '[\s]+');
END;
$$
STABLE
LANGUAGE plpgsql;