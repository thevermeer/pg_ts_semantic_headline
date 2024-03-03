/*
Function: TSP_PRESENT_TEXT
Accepts: 
- input_text    TEXT - the source text to be prepared, by having indexing tokens 
                       removed
- end_delimiter TEXT - the StopSel parameter provided as part of TS_HEADLINE 
                       options, and the closing tag of a headline. Defaults 
                       to '</b>'

Returns a string with the indexing tokens of Bell Character (u0001) + SPACE removed, 
including those sequences which are divided by a specified end_delimiter. Reverses 
the effect of `TSP_INDEXABLE_TEXT` function.
*/

CREATE OR REPLACE FUNCTION TSP_PRESENT_TEXT (input_text TEXT, end_delimiter TEXT DEFAULT '</b>')
RETURNS TEXT AS
$$
BEGIN
    -- Removes Bell Char + SPACE sequences
    input_text := regexp_replace(input_text, E'\u0001 ', '', 'g');
    -- Removes Bell Char + end_delimiter + SPACE sequences
    input_text := regexp_replace(input_text,  E'\u0001(' || end_delimiter || ') ', E'\\2\\1', 'g');
    -- Having cleaned the added spaces, now we removes all Bell Chars
    input_text := regexp_replace(input_text, E'\u0001', '', 'g');
    -- Trim string and return
	RETURN TRIM(input_text);
END;
$$
STABLE
LANGUAGE plpgsql;
