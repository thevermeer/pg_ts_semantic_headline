/*
Function: ts_prepare_text_for_tsvector

Accepts: 
- result_text TEXT - the source text to be prepared, by having indexing tokens removed

Returns a string with the words delimited by special characters broken apart 
by inserting indexing tokens of a Bell Character (u0001) + SPACE.
The purpose of this function is to break apart character-delimiter terms into 
individual tokens for rendering a TSVector. Performing this preparation results 
in a TSVector (for english-stem, so far) that maintains lexeme positions that 
will match the source text word postions, provided that both the TSVector and 
the source text are prepared with this function.

The effect of the `ts_prepare_text_for_tsvector` function can be reversed by 
applying the ``ts_prepare_text_for_presentation` function. One should be careful 
as applying these two functions is intended for fast recall of search results 
and applying these 2 functions consecutively is NOT an idempotent transformation. 
Specifically, applying the two functions will remove all sequences of exclusively 
special characters and eliminate consecutive whitespace.

Use with caution!
*/

CREATE OR REPLACE FUNCTION ts_prepare_text_for_tsvector(result_string text)
RETURNS text AS
$$
BEGIN
    -- We perform the chararacter substitution twice to catch any terms with 
	-- multiple character-delimiter substrings
	result_string := regexp_replace(result_string, 
	                                '(\w)([^[:alnum:]|\s]+)(\w)', 
									E'\\1\\2\u0001 \\3', 
									'g');
	result_string := regexp_replace(result_string, 
	                                '(\w)([^[:alnum:]|\s]+)(\w)', 
									E'\\1\\2\u0001 \\3', 
									'g');
	-- Removes strings that do not contain character
	result_string := regexp_replace(result_string, 
	                                '(\s)([^[:alnum:]|\s]+)(\s)', 
									E' ', 
									'g');
	-- Deduplicates whitespace into a single space
	result_string := regexp_replace(result_string, 
	                                E'[\\s]+', 
									' ', 
									'g');		    

    RETURN result_string;
END;
$$
STABLE
LANGUAGE plpgsql;