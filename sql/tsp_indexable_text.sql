/*
Function: TSP_INDEXABLE_TEXT

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

The effect of the `TSP_INDEXABLE_TEXT` function can be reversed by 
applying the ``TSP_PRESENT_TEXT` function. One should be careful 
as applying these two functions is intended for fast recall of search results 
and applying these 2 functions consecutively is NOT an idempotent transformation. 
Specifically, applying the two functions will remove all sequences of exclusively 
special characters and eliminate consecutive whitespace.

How to harvest special characters:
Use the following query to determine the blank characters used by each of the 
installed PGSQL Text Search Language configurations. Note, we range from 2 to 
the unicode limit of 55295, and interpret each of the characters in each of 
the installed languages. We omit character 0001 as that is a bell character 
used in computed string and thus omitted. The following query SHOULD return 217 
rows (representing each of the 64 space characters, plus the character that, 
when UNACCENTed, create space characters in pgsql ts lexizing), each with a 
count of 29 (representing the number of default languages in the system).
Use:
-------------------------------------------------------------------------------
SELECT 
alias, seqno, chr(seqno), count(*), '\u' || lpad(to_hex(seqno)::TEXT, 4, '0') as unicode_char
FROM (SELECT cfgname::REGCONFIG AS lang  FROM pg_ts_config) AS tlang,
     -- The important part is to unaccent the characters BEFORE ts_debug!!!
	 (SELECT (SELECT STRING_AGG(alias, '') as alias FROM ts_debug(UNACCENT(chr(seqno)))) AS alias, 
	         chr(seqno) AS char, 
	         seqno 
      FROM generate_series(2, 55295) as seqno) as a1
WHERE substring(alias, 'blank') IS NOT NULL
-- omit the actual space character
AND seqno <> 32
GROUP BY seqno, alias;
-------------------------------------------------------------------------------
At the time of writing, in pgsql14, all 217 rows should return a count of 29.
This will be a prime assertion in testing. 

In order to actually aggregate the collection of unicode characters used below, run:
-------------------------------------------------------------------------------
WITH blanks AS 
(SELECT alias, seqno, chr(seqno), count(*), '\u' || lpad(to_hex(seqno)::TEXT, 4, '0') as unicode_char
FROM (SELECT cfgname::REGCONFIG AS lang  FROM pg_ts_config) AS tlang,
	 (SELECT (SELECT STRING_AGG(alias, '') as alias FROM ts_debug(UNACCENT(chr(seqno)))) AS alias, 
	         chr(seqno) AS char, 
	         seqno 
      FROM generate_series(2, 55295) as seqno) as a1
WHERE substring(alias, 'blank') IS NOT NULL
-- omit the actual space character
AND seqno <> 32
GROUP BY seqno, alias)
SELECT STRING_AGG(unicode_char, '|') from blanks;
-------------------------------------------------------------------------------
*/

CREATE OR REPLACE FUNCTION TSP_INDEXABLE_TEXT(result_string text)
RETURNS text AS
$$
DECLARE
    -- All Unicode Characters that, when processed with UNACCENT will be treated
	-- in TS_Vector/Query lexiing, as blanks OR characters and blanks 
    space_making_chars TEXT = '\u24a5|\u24a4|\u000c|\u00bb|\u0002|\u02dc|' || 
	'\u3002|\u24a6|\u003d|\u02bc|\u2033|\u0008|\u301a|\u00a9|\u2477|\u203c|' || 
	'\u0021|\u0004|\u2212|\u2489|\u301d|\u2a75|\u249a|\u0149|\u2215|\u2480|' || 
	'\u300b|\u2986|\u2046|\u003a|\u24a8|\u3009|\u2499|\u2493|\u007e|\u0025|' || 
	'\u02c8|\u02c2|\u247b|\u2225|\u2026|\u001b|\u249c|\u2496|\u2011|\u247e|' || 
	'\u20a4|\u0040|\u2047|\u2a76|\u226b|\u007d|\u24b0|\u2490|\u2486|\u249f|' || 
	'\u00a1|\u001a|\u0012|\u2216|\u2018|\u201e|\u2483|\u005e|\u33d8|\u002d|' || 
	'\u02d7|\u301e|\u0014|\u24ad|\u002a|\u002e|\u0007|\u0028|\u005c|\u2015|' || 
	'\u0029|\u00ab|\u2048|\u02bb|\u24a7|\u3014|\u2482|\u0023|\u24b5|\u24ac|' || 
	'\u201b|\u301b|\u2013|\u0009|\u002f|\u2485|\u2039|\u003c|\u24a2|\u00f7|' || 
	'\u00b1|\u24aa|\u3015|\u2044|\u2487|\u248f|\u005b|\u20a3|\u0019|\u249e|' || 
	'\u0011|\u001e|\u2045|\u2478|\u24b2|\u2484|\u02cb|\u000e|\u24b1|\u2494|' || 
	'\u2476|\u02c6|\u24a9|\u02d0|\u2492|\u248d|\u001c|\u2016|\u007c|\u24af|' || 
	'\u2012|\u0026|\u2014|\u2985|\u249d|\u003f|\u00bf|\u204e|\u02b9|\u0005|' || 
	'\u24a0|\u2498|\u2481|\u002b|\u2479|\u2488|\u33c7|\u24b3|\u203a|\u007f|' || 
	'\u2497|\u3019|\u24b4|\u0017|\u247d|\u001d|\u0018|\u0015|\u003e|\u007b|' || 
	'\u0016|\u000f|\u000b|\u2024|\u247f|\u2049|\u2010|\u005f|\u3018|\u2491|' || 
	'\u2223|\u201c|\u201a|\u226a|\u24a1|\u2032|\u2019|\u24a3|\u248b|\u0060|' || 
	'\u3008|\u02ba|\u215f|\u003b|\u0003|\u247c|\u0022|\u0010|\u24ae|\u2475|' || 
	'\u248a|\u201d|\u0027|\u0013|\u2a74|\u000d|\u005d|\u0024|\u3001|\u2474|' || 
	'\u02c4|\u33c2|\u000a|\u00d7|\u249b|\u00ad|\u24ab|\u2117|\u00ae|\u300a|' || 
	'\u02bd|\u02d6|\u002c|\u201f|\u248e|\u248c|\u02c3|\u001f|\u0006|\u2495|' || 
	'\u247a';
BEGIN
    -- Any word-breaking character is treated, in its raw (NOT UNACCENTED) form,
	-- by inserting a bell character + space after the character, forcing separate
	-- tokenization of deliniated terms
	result_string := regexp_replace(result_string, 
	                                '(['|| space_making_chars ||']+)', 
	                                E'\\1\u0001 ', 'g');
 	
 	result_string := regexp_replace(result_string, '(\s[^[:alnum:]|\s]+)\s(\w+)', E'\\1\\2', 'g');
 	
 	
 	-- removes all non-word token sequences
 	result_string := regexp_replace(result_string, '(\s)([^\w|\s]+)(\s)', E' ', 'g');
	-- removes redundant spaces
 	result_string := regexp_replace(result_string, E'[\\s]+', ' ', 'g');
	-- Trim the result and return the string
	RETURN TRIM(result_string);
END;
$$
STABLE
LANGUAGE plpgsql;