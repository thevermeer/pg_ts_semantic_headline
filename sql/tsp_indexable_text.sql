/*
Function: tsp_indexable_text

Accepts: 
- result_text TEXT - the source text to be prepared, by having indexing tokens 
                     removed

Returns a string with the words delimited by special characters broken apart 
by inserting indexing tokens of a Bell Character (u0001) + SPACE.
The purpose of this function is to break apart character-delimiter terms into 
individual tokens for rendering a TSVector. Performing this preparation results 
in a TSVector (for english-stem, so far) that maintains lexeme positions that 
will match the source text word postions, provided that both the TSVector and 
the source text are prepared with this function.

The effect of the `tsp_indexable_text` function can be reversed by 
applying the ``tsp_present_text` function. One should be careful 
as applying these two functions is intended for fast recall of search results 
and applying these 2 functions consecutively is NOT an idempotent transformation. 
Specifically, applying the two functions will remove all sequences of exclusively 
special characters and eliminate consecutive whitespace.

How to harvest special characters:
Use the following query to determine the blank characters used by each of the 
installed PGSQL Text Search Language configurations. Note, we range from 2 to 
the unicode limit of 55295, and interpret each of the characters in each of 
the installed languages. We omit character 0001 as that is a bell character 
used in computed string and thus omitted. The following query SHOULD return 64 
rows (representing each of the 64 space characters), each with a count of 29 
(representing the number of default languages in the system).

SELECT 
seqno, chr(seqno), count(*), '\u' || lpad(to_hex(seqno)::TEXT, 4, '0') as unicode_char
FROM (SELECT cfgname::REGCONFIG AS lang  FROM pg_ts_config) AS tlang,
	 (SELECT (SELECT alias FROM ts_debug(chr(seqno))) AS alias, 
	         chr(seqno) AS char, 
	         seqno 
      FROM generate_series(2, 55295) as seqno) as a1
WHERE alias = 'blank' 
-- omit the actual space character
AND seqno <> 32
GROUP BY seqno;

In order to actually aggregate the collection of unicode characters used below, run:
WITH blanks AS (SELECT 
seqno, chr(seqno), count(*), '\u' || lpad(to_hex(seqno)::TEXT, 4, '0') as unicode_char
FROM (SELECT cfgname::REGCONFIG AS lang  FROM pg_ts_config) AS tlang,
	 (SELECT (SELECT alias FROM ts_debug(chr(seqno))) AS alias, 
	         chr(seqno) AS char, 
	         seqno 
      FROM generate_series(2, 55295) as seqno) as a1
WHERE alias = 'blank'
GROUP BY seqno)
SELECT STRING_AGG(unicode_char, '|') from blanks;
*/

CREATE OR REPLACE FUNCTION tsp_indexable_text(result_string text)
RETURNS text AS
$$
BEGIN
     -- TODO: Should we perform the chararacter substitution twice to catch any terms with 
	--        multiple character-delimiter substrings?
	--result_string := regexp_replace(result_string, '(\(|\))', '\\' || E'\\1', 'g');
		 	

	-- We perform the chararacter substitution twice to catch any terms with 
	-- multiple character-delimiter substrings
	result_string := regexp_replace(result_string, '(\w)([^\w+|\s]+)(\w)', E'\\1\\2\u0001 \\3', 'g');
	result_string := regexp_replace(result_string, '(\w)([^\w+|\s]+)(\w)', E'\\1\\2\u0001 \\3', 'g');

	result_string := regexp_replace(result_string, 
	                                '(\w)([\u0002|\u0003|\u0004|' ||
	'\u0005|\u0006|\u0007|\u0008|\u0009|\u000a|\u000b|\u000c|\u000d|\u000e|\u000f|' ||
	'\u0010|\u0011|\u0012|\u0013|\u0014|\u0015|\u0016|\u0017|\u0018|\u0019|\u001a|' || 
	'\u001b|\u001c|\u001d|\u001e|\u001f|\u0021|\u0022|\u0023|\u0024|\u0025|\u0026|' || 
	'\u0027|\u0028|\u0029|\u002a|\u002b|\u002c|\u002d|\u002e|\u002f|\u003a|\u003b|' ||	
	'\u003c|\u003d|\u003e|\u003f|\u0040|\u005b|\u005c|\u005d|\u005e|\u005f|\u0060|' ||
	'\u007b|\u007c|\u007d|\u007e|\u007f]+)(\w)', 
	                                E'\\1\\2\u0001\\3', 'g');
	-- As a more rigorous, but 100x slower alternative:
	-- Use ts_debug to decompose and recompose string - computationally expensive
	--result_string := (SELECT TRIM(STRING_AGG(CASE WHEN alias='blank' THEN E'\u0001' ELSE ' ' END || token, '')) 
    --                  FROM (SELECT * FROM ts_debug('simple', result_string)) AS terms
    --                  WHERE NOT(token IN (' ') AND token IS NOT NULL)); 
	--result_string := regexp_replace(result_string, '(\(|\)) ', E'\\1', 'g');
 	result_string := regexp_replace(result_string, '(\s)([^\w|\s]+)(\s)', E' ', 'g');


	RETURN TRIM(result_string);
END;
$$
STABLE
LANGUAGE plpgsql;