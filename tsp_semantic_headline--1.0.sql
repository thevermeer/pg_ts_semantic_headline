CREATE OR REPLACE FUNCTION replace_multiple_strings(source_text text, find_array text[], replace_array text[])
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
/*
Function: tsp_indexable_text

Accepts: 
- result_text TEXT - the source text to be prepared, by having indexing tokens removed

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

Use with caution!
*/

CREATE OR REPLACE FUNCTION tsp_indexable_text(result_string text)
RETURNS text AS
$$
BEGIN
     -- We perform the chararacter substitution twice to catch any terms with 
	-- multiple character-delimiter substrings
	result_string := regexp_replace(result_string, '(\w)([\u0002|\u0003|\u0004|' ||
	'\u0005|\u0006|\u0007|\u0008|\u0009|\u000a|\u000b|\u000c|\u000d|\u000e|\u000f|' ||
	'\u0010|\u0011|\u0012|\u0013|\u0014|\u0015|\u0016|\u0017|\u0018|\u0019|\u001a|' || 
	'\u001b|\u001c|\u001d|\u001e|\u001f|\u0021|\u0022|\u0023|\u0024|\u0025|\u0026|' || 
	'\u0027|\u0028|\u0029|\u002a|\u002b|\u002c|\u002d|\u002e|\u002f|\u003a|\u003b|' ||
	'\u003c|\u003d|\u003e|\u003f|\u0040|\u005b|\u005c|\u005d|\u005e|\u005f|\u0060|' ||
	'\u007b|\u007c|\u007d|\u007e|\u007f]+)(\w)', E'\\1\\2\u0001 \\3', 'g');
	
	--result_string := regexp_replace(result_string, '(\w)([\u0002|\u0003|\u0004|\u0005|\u0006|\u0007|\u0008|\u0009|\u000a|\u000b|\u000c|\u000d|\u000e|\u000f|\u0010|\u0011|\u0012|\u0013|\u0014|\u0015|\u0016|\u0017|\u0018|\u0019|\u001a|\u001b|\u001c|\u001d|\u001e|\u001f|\u0021|\u0022|\u0023|\u0024|\u0025|\u0026|\u0027|\u0028|\u0029|\u002a|\u002b|\u002c|\u002d|\u002e|\u002f|\u003a|\u003b|\u003c|\u003d|\u003e|\u003f|\u0040|\u005b|\u005c|\u005d|\u005e|\u005f|\u0060|\u007b|\u007c|\u007d|\u007e|\u007f]+)(\w)', E'\\1\\2\u0001 \\3', 'g');

	-- Use ts_debug to decompose and recompose string - computationally expensive
	--result_string := (SELECT TRIM(STRING_AGG(CASE WHEN alias='blank' THEN E'\u0001' ELSE ' ' END || token, '')) 
    --                  FROM (SELECT * FROM ts_debug('simple', result_string)) AS terms
    --                  WHERE NOT(token IN (' ') AND token IS NOT NULL)); 
	-- 	 result_string := regexp_replace(result_string, '(\(|\)) ', E'\\1', 'g');
 	result_string := regexp_replace(result_string, '(\s)([^\w|\s]+)(\s)', E' ', 'g');	 	


	RETURN TRIM(result_string);
END;
$$
STABLE
LANGUAGE plpgsql;/*
Function: tsp_phraseto_tsquery

1:1 replacement for the built-in PHRASETO_TSQuery function:

Accepts 
- config       REGCONFIG - PGSQL Text Search Language Configuration
- query_string TEXT - a common language string as a phrase, or ordered 
                      combination of multiple words.

Returns a TSQuery that represents the query phrase after its treament with 
tsp_indexable_text. This is done to attain positional alignment between raw text
and the rendered TSVector. As we are searching on a treated vector, we need to treat
the phrase used to render a TSQuery in the same way
*/

CREATE OR REPLACE FUNCTION tsp_phraseto_tsquery(config REGCONFIG, query_string TEXT)
RETURNS TSQUERY AS
$$
BEGIN
	RETURN PHRASETO_TSQUERY(config, tsp_indexable_text(query_string));
END;
$$
STABLE
LANGUAGE plpgsql;

-- OVERLOAD Arity-2 form, to infer the default_text_search_config for parsing
CREATE OR REPLACE FUNCTION tsp_phraseto_tsquery(query_string TEXT)
RETURNS TSQUERY AS
$$
BEGIN    
    RETURN tsp_to_tsquery(current_setting('default_text_search_config')::REGCONFIG, 
	                      query_string);
END;
$$
STABLE
LANGUAGE plpgsql;
/*
Function: tsp_present_text
Accepts: 
- input_text    TEXT - the source text to be prepared, by having indexing tokens 
                       removed
- end_delimiter TEXT - the StopSel parameter provided as part of TS_HEADLINE 
                       options, and the closing tag of a headline. Defaults 
                       to '</b>'

Returns a string with the indexing tokens of Bell Character (u0001) + SPACE removed, 
including those sequences which are divided by a specified end_delimiter. Reverses 
the effect of `tsp_indexable_text` function.
*/

CREATE OR REPLACE FUNCTION tsp_present_text (input_text TEXT, end_delimiter TEXT DEFAULT '</b>')
RETURNS TEXT AS
$$
BEGIN
    -- Removes Bell Char + SPACE sequences
    input_text := regexp_replace(input_text, 
                                 E'\u0001 ', 
                                 '', 
                                 'g');
    -- Removes Bell Char + end_delimiter + SPACE sequences
    input_text := regexp_replace(input_text, 
                                 E'\u0001(' || end_delimiter || ') ', 
                                 E'\\2\\1', 
                                 'g');
    -- Trim string and return
	RETURN TRIM(input_text);
END;
$$
STABLE
LANGUAGE plpgsql;
/*
Function: tsp_query_matches
Accepts: 
- config       REGCONFIG - PGSQL Text Search Language Configuration
- haystack_arr TEXT[]    - Ordered array of words, as they appear in the source
                           document, delimited by spaces. Assumes text is preprocessed
                           by tsp_indexable text function
- content_tsv  TSVECTOR  - TSVector representation of the source document. Assumes text 
                           is preprocessed by tsp_indexable text function to maintain
                           the correct positionality of lexemes.
- search_query TSQUERY   - TSQuery representation of a user-inputted search.
- match_limit  INTEGER   - Number of matches to return from the start of the document.
                           Defaults to 5.

Returns a table of exact matches returned from the fuzzy TSQuery search, Each row contains:
- words     TEXT     - the exact string found in the text
- ts_query  TSQUERY  - the TSQuery phrase pattern that matches `words` text. A given TSQuery 
                       can contain multiple phrase patterns
- start_pos SMALLINT - the first word position of the found term within the document.
- end_pos   SMALLINT - the last word position of the found term within the document.
*/

CREATE OR REPLACE FUNCTION tsp_query_matches
(config REGCONFIG, haystack_arr TEXT[], content_tsv TSVECTOR, search_query TSQUERY, match_limit INTEGER DEFAULT 5)
RETURNS TABLE(words TEXT, 
              ts_query TSQUERY, 
              start_pos SMALLINT, 
              end_pos SMALLINT) AS
$$    
BEGIN
    content_tsv := (SELECT ts_filter(setweight(content_tsv, 'A', ARRAY_AGG(lexes)), '{a}')
                    FROM (SELECT UNNEST(tsvector_to_array(vec.phrase_vector)) AS lexes
                          FROM tsquery_to_tsvector(config, search_query) AS vec) AS query2vec);
    RETURN QUERY
    (   SELECT array_to_string(haystack_arr[first:last], ' '),           
               query,
               first, 
               last
        FROM (SELECT MIN(pos) AS first, 
                     MAX(pos) AS last, 
                     range_start AS range_start, 
                     MAX(lex) as lex,
                     phrase_query as query
              FROM (SELECT phrase_vector,
                           query_vec.phrase_query,
                           haystack.lex,
                           haystack.pos AS pos, 
                           haystack.pos - query_vec.pos 
                           + (SELECT MIN(pos) 
                              FROM tsvector_to_table(query_vec.phrase_vector)) as range_start
                    FROM tsquery_to_table(config, search_query) AS query_vec 
                    INNER JOIN tsvector_to_table(content_tsv) AS haystack 
                    ON haystack.lex = query_vec.lexeme) AS joined_terms
              GROUP BY range_start, query, phrase_vector 
              HAVING COUNT(*) = length(phrase_vector)) AS phrase_agg
        WHERE (last - first) = (SELECT MAX(pos) - MIN(pos) 
                                FROM tsquery_to_table(config, query::TSQUERY))
        AND TO_TSVECTOR(config, array_to_string(haystack_arr[first:last], ' ')) @@ query::TSQUERY
        LIMIT match_limit);
END;
$$
STABLE
LANGUAGE plpgsql;


-- OVERLOAD Arity-5 form, to infer the default_text_search_config for parsing
CREATE OR REPLACE FUNCTION tsp_query_matches
(haystack_arr TEXT[], content_tsv TSVECTOR, search_query TSQUERY, match_limit INTEGER DEFAULT 5)
RETURNS TABLE(words TEXT, 
              ts_query TSQUERY, 
              start_pos SMALLINT, 
              end_pos SMALLINT) AS
$$    
BEGIN
   RETURN QUERY
    (SELECT *
     FROM   tsp_query_matches(current_setting('default_text_search_config')::REGCONFIG,
                             haystack_arr, 
                             content_tsv, 
                             search_query, 
                             match_limit));
END;
$$
STABLE
LANGUAGE plpgsql;
/*
Function: tsp_semantic_headline
Accepts: 
- config       REGCONFIG - PGSQL Text Search Language Configuration
- haystack_arr TEXT[]    - Ordered array of words, as they appear in the source
                           document, delimited by spaces. Assumes text is 
						   preprocessed by tsp_indexable text function
- content_tsv  TSVECTOR  - TSVector representation of the source document. 
                           Assumes text is preprocessed by tsp_indexable text 
						   function to maintain the correct positionality of 
						   lexemes.
- search_query TSQUERY   - TSQuery representation of a user-inputted search.
- options      TEXT      - Configuration options in the same form as the 
                           TS_HEADLINE options, with some semantic difference 
						   in interpretting parameters.

Internally, this function calls tsp_query_matches, aggregates ranges based on 
frequency in range (akin to cover density), and returns results from the start 
of the document forward. This diverges from the implementation of cover density 
in ts_headline, and in making these sacrifices in order to better performance.

As the internals of this function guarantee that each fragment will semantically 
abide the TSQuery and its phrase semantics, in whole or in part, the goal is to
return evidence of the search match, and thus we make concessions on headline 
robustness, for speed of recall.

Returns a string of 1 or more passages of text, with content matching one or more 
phrase patterns in the TSQuery highlighted, meaning wrapped by the StartSel and 
StopSel options.

Options:
* `MaxWords`, `MinWords` (integers): these numbers determine the number of words, 
   beyond the length of a phrase in TSQuery, to return in each headline. For instance, 
   a value of MinWords=4 will put min. 2 words on either side of a phrase headline.
* `ShortWord` (integer): NOT IMPLEMENTED: The system does not use precisely the same 
   `rank_cd` ordering to return the most cover-dense headline segments first, but rather 
   find the FIRST find n matching passages within the document. See `tsp_exact_matches` 
   function for more.
* `HighlightAll` (boolean): TODO: Implement this option.
* `MaxFragments` (integer): maximum number of text fragments to display. The default 
  value of zero selects a non-fragment-based headline generation method. A value 
  greater than zero selects fragment-based headline generation (see below).
* `StartSel`, `StopSel` (strings): the strings with which to delimit query words 
   appearing in the document, to distinguish them from other excerpted words. The 
   default values are “<b>” and “</b>”, which can be suitable for HTML output.
* `FragmentDelimiter` (string): When more than one fragment is displayed, the fragments 
   will be separated by this string. The default is “ ... ”.
*/

-- Arity-5 Form of fast tsp_semantic_headline with pre-computed arr & tsv
CREATE OR REPLACE FUNCTION tsp_semantic_headline 
(config REGCONFIG, haystack_arr TEXT[], content_tsv TSVECTOR, search_query TSQUERY, options TEXT DEFAULT ' ')
RETURNS TEXT AS
$$
DECLARE
    -- Parse Options string to JSON map --
    opts          JSON    = (SELECT JSON_OBJECT_AGG(grp[1], COALESCE(grp[2], grp[3])) AS opt 
                             FROM REGEXP_MATCHES(options, 
                                                 '(\w+)=(?:"([^"]+)"|((?:(?![\s,]+\w+=).)+))', 
                                                 'g') as matches(grp));
    -- Options Map and Default Values --
    tag_range     TEXT    = COALESCE(opts->>'StartSel', '<b>') || 
	                        E'\\1' || 
							COALESCE(opts->>'StopSel', '</b>');
    min_words     INTEGER = COALESCE((opts->>'MinWords')::SMALLINT / 2, 10);
    max_words     INTEGER = COALESCE((opts->>'MaxWords')::SMALLINT, 30);
    max_offset    INTEGER = max_words / 2 + 1;
    max_fragments INTEGER = COALESCE((opts->>'MaxFragments')::INTEGER, 1);
BEGIN
    RETURN (
		SELECT tsp_present_text(STRING_AGG(highlighted_text,
		                                                   COALESCE(opts->>'FragmentDelimiter', '...')),
		                                        COALESCE(opts->>'StopSel', '</b>'))
		FROM (SELECT REGEXP_REPLACE(-- Aggregate the source text over a Range
		                            ' ' || ARRAY_TO_STRING(haystack_arr[MIN(start_pos) - GREATEST((max_offset - (MAX(end_pos) - MIN(start_pos) / 2 + 1)), min_words): 
		                                                                MAX(end_pos)   + GREATEST((max_offset - (MAX(end_pos) - MIN(start_pos) / 2 + 1)), min_words)], 
		                                                   ' ') || ' ', 
				                    -- Capture Exact Matches over Range
				                    E' (' || STRING_AGG(words, '|') || ') ', 
				                    -- Replace with Tags wrapping Content
				                    ' ' || tag_range || ' ', 
				                    'g') AS highlighted_text
		      FROM tsp_query_matches (config, haystack_arr, content_tsv, search_query, max_fragments + 3)
			  GROUP BY (start_pos / (max_words + 1)) * (max_words + 1)
			  ORDER BY COUNT(*) DESC, (start_pos / (max_words + 1)) * (max_words + 1)
			  LIMIT max_fragments) AS frags);
END;
$$
STABLE
LANGUAGE plpgsql;

-- OVERLOAD Arity-5 form, to infer the default_text_search_config for parsing
-- Arity-4 Form of fast tsp_semantic_headline with pre-computed arr & tsv
CREATE OR REPLACE FUNCTION tsp_semantic_headline 
(haystack_arr TEXT[], content_tsv TSVECTOR, search_query TSQUERY, options TEXT DEFAULT ' ')
RETURNS TEXT AS
$$
BEGIN
    RETURN tsp_semantic_headline(current_setting('default_text_search_config')::REGCONFIG,
	                          	 haystack_arr,
	                             content_tsv,
								 search_query, 
								 options);
END;
$$
STABLE
LANGUAGE plpgsql;
  
/*
Note: This form is the 1:1 replacement for ts_headline:

Likewise, this function uses TS_HEADLINE under the hood to handle content that 
does NOT use precomputed TEXT[] and TSVector columns. Rather, this implementation
calls ts_headline to return fragments, and then applies the arity-5 form of
tsp_semantic_headline to the results to achieve semantically accurate phrase
highlighting.
*/
-- Arity-4 Form of simplified tsp_semantic_headline 
CREATE OR REPLACE FUNCTION tsp_semantic_headline 
(config REGCONFIG, content TEXT, user_search TSQUERY, options TEXT DEFAULT '')
RETURNS TEXT AS
$$
DECLARE cleaned_content TEXT = ts_headline(config, 
                                           content, 
										   user_search, 
										   'StartSel="",StopSel="",' || options);
BEGIN
	cleaned_content := tsp_indexable_text(cleaned_content);
	RETURN tsp_semantic_headline(config,
	                            regexp_split_to_array(cleaned_content, '[\s]+'), 
                                TO_TSVECTOR(config, cleaned_content),
                                user_search,
                                options);
END;
$$
STABLE
LANGUAGE plpgsql;

-- OVERLOAD Arity-4 form #2, to infer the default_text_search_config for parsing
-- Arity-3 Form of simplified tsp_semantic_headline 
CREATE OR REPLACE FUNCTION tsp_semantic_headline
(content TEXT, user_search TSQUERY, options TEXT DEFAULT '')
RETURNS TEXT AS
$$
BEGIN
	RETURN tsp_semantic_headline(current_setting('default_text_search_config')::REGCONFIG, 
	                            content, 
								user_search, 
								options);
END;
$$
STABLE
LANGUAGE plpgsql;
/*
Function: tsp_to_tsquery

Accepts:
- config       REGCONFIG - PGSQL Text Search Language Configuration
- query_string TEXT      - String of search terms connected with TSQuery
                           operators.

Akin to the builtin function `to_tsquery`, this function converts text to a 
tsquery, normalizing words according to the specified or default configuration. 
The words must be combined by valid tsquery operators.

tsp_to_tsquery('english', 'The & Fat & Rats') → 'fat' & 'rat'

For the purposes of a TSQuery, this function is the treatment for TSQueries for
index-friendly positioning and is paralleled with tsp_indexable_text in TSVectors
*/

CREATE OR REPLACE FUNCTION tsp_to_tsquery(config REGCONFIG, query_string TEXT)
RETURNS TSQUERY AS
$$
BEGIN
    -- We perform the chararacter substitution twice to catch any terms with 
	-- multiple character-delimiter substrings
	query_string := ' ' || query_string || ' ';
	query_string := regexp_replace(query_string, '(\w)([^[:alnum:]&^<>|\s]+)(\w)', E'\\1\\2\<1>\\3', 'g');
	query_string := regexp_replace(query_string, '(\w)([^[:alnum:]&^<>|\s]+)(\w)', E'\\1\\2\<1>\\3', 'g');	    
    
	RETURN TO_TSQUERY(config, query_string);
END;
$$
STABLE
LANGUAGE plpgsql;

-- OVERLOAD Arity-2 form, to infer the default_text_search_config for parsing
CREATE OR REPLACE FUNCTION tsp_to_tsquery(query_string TEXT)
RETURNS TSQUERY AS
$$
BEGIN    
    RETURN tsp_to_tsquery(current_setting('default_text_search_config')::REGCONFIG, 
	                        query_string);
END;
$$
STABLE
LANGUAGE plpgsql;
/*
Function: tsquery_to_table

Accepts: 
- config      REGCONFIG - PGSQL Text Search Language Configuration
- input_query TEXT - the source text to be prepared, by having indexing tokens removed

Divides a TSQuery into phrases separated by logical operators. For each phrase, applies
tsquery_to_tsvector. For each resulting TSVector, we apply tsvector_to_table.

Returns a table with each record representing a lexeme and position within a TSVector, 
and for posterity each row also contains a phrase_vector TSVECTOR and the corresponding 
phrase_query TSQUERY that produced the vector.

In effect, this divides the TSQuery into a series of equivalent lexeme patters in a TSVector.
*/

CREATE OR REPLACE FUNCTION tsquery_to_table(config REGCONFIG, input_query TSQUERY)
RETURNS TABLE(phrase_vector TSVECTOR, phrase_query TSQUERY, lexeme TEXT, pos SMALLINT) AS
$$
BEGIN
	RETURN QUERY 
	(WITH phrases AS (SELECT phrase.phrase_vector, phrase.phrase_query 
	                  FROM tsquery_to_tsvector(config, input_query) AS phrase)
      SELECT phrases.phrase_vector, 
             phrases.phrase_query,
             word.lex, 
             word.pos
      FROM phrases, tsvector_to_table(phrases.phrase_vector) AS word);
END;
$$
STABLE
LANGUAGE plpgsql;

-- OVERLOADS Arity-2 form, to infer the default_text_search_config for parsing
CREATE OR REPLACE FUNCTION tsquery_to_table(input_query TSQUERY)
RETURNS TABLE(phrase_vector TSVECTOR, phrase_query TSQUERY, lexeme TEXT, pos SMALLINT) AS
$$
BEGIN
	RETURN QUERY 
	(SELECT * FROM tsquery_to_table(current_setting('default_text_search_config')::REGCONFIG, 
                                       input_query));
END;
$$
STABLE
LANGUAGE plpgsql;/*
Function: tsquery_to_tsvector

Accepts: 
- config      REGCONFIG - PGSQL Text Search Language Configuration
- input_query TSQuery - a well-formed TSQuery that is may be complex, containing 
  logical and phrase/distance operators

Returns a TABLE where each row contains:
- phrase_vector as a TSVector representation of a phrase
- phrase_query as a TSQuery representation of a phrase pattern

In effect, this function considers a TSQuery to contain a list of phrase queries 
separated by brackets and logical operators.

Though negated terms are removed from the resulting table, other logical operators 
and brackets are ignored, and the table is then a representation of a list of 
phrase patterns in the query
*/

CREATE OR REPLACE FUNCTION tsquery_to_tsvector(config REGCONFIG, input_query TSQUERY)
RETURNS TABLE(phrase_vector TSVECTOR, phrase_query TSQUERY) AS
$$
DECLARE
    input_text TEXT;
BEGIN
    -- Remove Negated query terms and replace <-> with the equivalent <1> distance term
    input_text := replace(querytree(input_query)::TEXT, '<->', '<1>');
    -- Strip Brackets
    input_text := regexp_replace(input_text, '\(|\)', '', 'g');

    RETURN QUERY 
    -- ts_filter + setweight is used to remove dummy lexeme from TSVector
    -- Set everything to weight A, set dummy word to D, filter for A, remove weights
    (SELECT setweight(ts_filter(setweight(setweight(phrase_vec, 'A'), 
                                          'D',
                                          ARRAY['xdummywordx']), 
                                '{a}'), 
                      'D') AS phrase_vector, 
            split_query AS phrase_query
     -- replace_multiple_strings will replace each of the <n> strings with n dummy word  entries
     FROM (SELECT to_tsvector(config,
                              (SELECT replace_multiple_strings(split_query, 
                                                               array_agg('<' || g[1] || '>'), 
                                                               array_agg(REPEAT(' xdummywordx ', g[1]::SMALLINT - 1)))
                               -- regexp for all of the <n> terms in a phrase segment
                               FROM regexp_matches(split_query, '<(\d+)>', 'g') AS matches(g))) as phrase_vec,
                  split_query::TSQUERY
           -- Splits Query as Text into a collection of phrases delimiter by AND/OR symbols
           FROM (SELECT regexp_split_to_table(input_text, '\&|\|') AS split_query) AS terms) AS termvec);
END;
$$
STABLE
LANGUAGE plpgsql;

-- OVERLOAD Arity-2 form, to infer the default_text_search_config for parsing
CREATE OR REPLACE FUNCTION tsquery_to_tsvector(input_query TSQUERY)
RETURNS TABLE(phrase_vector TSVECTOR, phrase_query TSQUERY) AS
$$
BEGIN
   RETURN QUERY 
   (SELECT * FROM tsquery_to_tsvector(current_setting('default_text_search_config')::REGCONFIG, input_query));
END;
$$
STABLE
LANGUAGE plpgsql;/*
Function: tsvector_to_table

Accepts: 
- input_vector TSVECTOR - a TSVector containing BOTH lexemes and positions 

Returns a table of the lexemes and positions of the TSVector, ordered by
position ASC. In effect, this function UNNESTs a TSVector into a table 
of lexemes and positions.

This function can be used on any TSVector that includes positions.
*/

CREATE OR REPLACE FUNCTION tsvector_to_table(input_vector TSVECTOR)
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