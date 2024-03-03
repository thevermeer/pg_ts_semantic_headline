CREATE OR REPLACE FUNCTION REPLACE_MULTIPLE_STRINGS(source_text text, find_array text[], replace_array text[])
RETURNS text AS
$$
DECLARE
    i integer;
BEGIN
	IF (find_array IS NULL) THEN RETURN source_text; END IF;
    FOR i IN 1..array_length(find_array, 1)
    LOOP
        source_text := replace(source_text, find_array[i], replace_array[i]);
    END LOOP;

    RETURN source_text;
END;
$$
LANGUAGE plpgsql;
