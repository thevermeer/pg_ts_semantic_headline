/*
Function: TO_TSP_TEXT_ARRAY

Simple wrapper function to ensure we split text arrays the same time, every time.
This is very much a convenience wrapper.
*/

CREATE OR REPLACE FUNCTION TO_TSP_TEXT_ARRAY(string TEXT)
RETURNS TEXT[] AS
$$
BEGIN
	RETURN REGEXP_SPLIT_TO_ARRAY(TSP_INDEXABLE_TEXT(string), '[\s]+');
END;
$$
STABLE
LANGUAGE plpgsql;