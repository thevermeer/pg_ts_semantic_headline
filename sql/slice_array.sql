/* Function: SLICE_ARRAY
For a whole_array ARRAY[], performs whole_array[start_pos:end_pos] without the syntactic sugar.
Very helpful is quickly moving through honeysql notation issue in clojure :)
*/

CREATE OR REPLACE FUNCTION SLICE_ARRAY 
(whole_array TEXT[], start_pos BIGINT, end_pos BIGINT)
RETURNS text[] AS
$$
BEGIN
    RETURN (whole_array)[start_pos:end_pos];
END;
$$
STABLE
LANGUAGE plpgsql;
