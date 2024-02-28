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
Function: ts_prepare_query

TODO :: Write me!
*/

CREATE OR REPLACE FUNCTION ts_prepare_query(config REGCONFIG, query_string TEXT)
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

CREATE OR REPLACE FUNCTION ts_prepare_query(query_string TEXT)
RETURNS TSQUERY AS
$$
BEGIN    
    RETURN ts_prepare_query(current_setting('default_text_search_config')::REGCONFIG, 
	                        query_string);
END;
$$
STABLE
LANGUAGE plpgsql;
/*
Function: ts_prepare_text_for_presentation
Accepts: 
- input_text    TEXT - the source text to be prepared, by having indexing tokens 
                       removed
- end_delimiter TEXT - the StopSel parameter provided as part of TS_HEADLINE 
                       options, and the closing tag of a headline. Defaults 
                       to '</b>'

Returns a string with the indexing tokens of Bell Character (u0001) + SPACE removed, 
including those sequences which are divided by a specified end_delimiter. Reverses 
the effect of `ts_prepare_text_for_tsvector` function.
*/

CREATE OR REPLACE FUNCTION ts_prepare_text_for_presentation (input_text TEXT, end_delimiter TEXT DEFAULT '</b>')
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
	result_string := regexp_replace(result_string, '(\w)([^\w+|\s]+)(\w)', E'\\1\\2\u0001 \\3', 'g');
	result_string := regexp_replace(result_string, '(\w)([^\w+|\s]+)(\w)', E'\\1\\2\u0001 \\3', 'g');
	-- Use ts_debug to decompose and recompose string - computationally expensive
	result_string := (SELECT TRIM(STRING_AGG(CASE WHEN alias='blank' THEN E'\u0001' ELSE ' ' END || token, '')) 
                      FROM (SELECT * FROM ts_debug('simple', result_string)) AS terms
                      WHERE NOT(token IN (' ') AND token IS NOT NULL)); 
	result_string := regexp_replace(result_string, '(\(|\)) ', E'\\1', 'g');
 	result_string := regexp_replace(result_string, '(\s)([^\w|\s]+)(\s)', E' ', 'g');	 	


	RETURN TRIM(result_string);
END;
$$
STABLE
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION ts_query_matches
(config REGCONFIG, haystack_arr TEXT[], content_tsv TSVECTOR, search_query TSQUERY, match_limit INTEGER DEFAULT 5)
RETURNS TABLE(words TEXT, 
              ts_query TSQUERY, 
              start_pos SMALLINT, 
              end_pos SMALLINT) AS
$$    
BEGIN
    content_tsv := (SELECT ts_filter(setweight(content_tsv, 'A', ARRAY_AGG(lexes)), '{a}')
                    FROM (SELECT UNNEST(tsvector_to_array(vec.phrase_vector)) AS lexes
                          FROM ts_query_to_ts_vector(search_query) AS vec) AS query2vec);
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
                              FROM ts_vector_to_table(query_vec.phrase_vector)) as range_start
                    FROM ts_query_to_table(search_query) AS query_vec 
                    INNER JOIN ts_vector_to_table(content_tsv) AS haystack 
                    ON haystack.lex = query_vec.lexeme) AS joined_terms
              GROUP BY range_start, query, phrase_vector 
              HAVING COUNT(*) = length(phrase_vector)) AS phrase_agg
        WHERE (last - first) = (SELECT MAX(pos) - MIN(pos) 
                                FROM ts_query_to_table(query::TSQUERY))
        AND array_to_string(haystack_arr[first:last], ' ') @@ query::TSQUERY
        LIMIT match_limit);
END;
$$
STABLE
LANGUAGE plpgsql;



CREATE OR REPLACE FUNCTION ts_query_matches
(haystack_arr TEXT[], content_tsv TSVECTOR, search_query TSQUERY, match_limit INTEGER DEFAULT 5)
RETURNS TABLE(words TEXT, 
              ts_query TSQUERY, 
              start_pos SMALLINT, 
              end_pos SMALLINT) AS
$$    
BEGIN
   RETURN QUERY
    (SELECT *
     FROM   ts_query_matches(current_setting('default_text_search_config')::REGCONFIG,
                             haystack_arr, 
                             content_tsv, 
                             search_query, 
                             match_limit));
END;
$$
STABLE
LANGUAGE plpgsql;
CREATE OR REPLACE FUNCTION ts_query_to_table(config REGCONFIG, input_query TSQUERY)
RETURNS TABLE(phrase_vector TSVECTOR, phrase_query TSQUERY, lexeme TEXT, pos SMALLINT) AS
$$
BEGIN
	RETURN QUERY 
	(WITH phrases AS (SELECT phrase.phrase_vector, phrase.phrase_query 
	                  FROM ts_query_to_ts_vector(config, input_query) AS phrase)
     SELECT phrases.phrase_vector, 
            phrases.phrase_query,
            word.lex, 
            word.pos
     FROM phrases, ts_vector_to_table(phrases.phrase_vector) AS word);
END;
$$
STABLE
LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION ts_query_to_table(input_query TSQUERY)
RETURNS TABLE(phrase_vector TSVECTOR, phrase_query TSQUERY, lexeme TEXT, pos SMALLINT) AS
$$
BEGIN
	RETURN QUERY 
	(SELECT * FROM ts_query_to_table(current_setting('default_text_search_config')::REGCONFIG, 
                                        input_query));
END;
$$
STABLE
LANGUAGE plpgsql;/*
Function: ts_query_to_ts_vector

Accepts: 
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

CREATE OR REPLACE FUNCTION ts_query_to_ts_vector(config REGCONFIG, input_query TSQUERY)
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
    (SELECT setweight(ts_filter(setweight(setweight(phrase_vec, 'A'), 
                                          'D',
                                          ARRAY['xdummywordx']), 
                                '{a}'), 
                      'D') AS phrase_vector, 
            split_query AS phrase_query
     -- replace_multiple_strings will replace each of the <n> strings with n dummy word  entries
     FROM (SELECT to_tsvector((SELECT replace_multiple_strings(split_query, 
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

CREATE OR REPLACE FUNCTION ts_query_to_ts_vector(input_query TSQUERY)
RETURNS TABLE(phrase_vector TSVECTOR, phrase_query TSQUERY) AS
$$
BEGIN
   RETURN QUERY 
   (SELECT * FROM ts_query_to_ts_vector(current_setting('default_text_search_config')::REGCONFIG, input_query));
END;
$$
STABLE
LANGUAGE plpgsql;-- Arity-5 Form of fast ts_semantic_headline with pre-computed arr & tsv
CREATE OR REPLACE FUNCTION ts_semantic_headline 
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
		SELECT ts_prepare_text_for_presentation(STRING_AGG(highlighted_text,
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
		      FROM ts_query_matches (config, haystack_arr, content_tsv, search_query, max_fragments + 3)
			  GROUP BY (start_pos / (max_words + 1)) * (max_words + 1)
			  ORDER BY COUNT(*) DESC, (start_pos / (max_words + 1)) * (max_words + 1)
			  LIMIT max_fragments) AS frags);
END;
$$
STABLE
LANGUAGE plpgsql;

-- Arity-4 Form of fast ts_semantic_headline with pre-computed arr & tsv
CREATE OR REPLACE FUNCTION ts_semantic_headline 
(haystack_arr TEXT[], content_tsv TSVECTOR, search_query TSQUERY, options TEXT DEFAULT ' ')
RETURNS TEXT AS
$$
BEGIN
    RETURN ts_semantic_headline(current_setting('default_text_search_config')::REGCONFIG,
	                         	haystack_arr,
	                            content_tsv,
								search_query, 
								options);
END;
$$
STABLE
LANGUAGE plpgsql;
  
-- Arity-4 Form of simplified ts_semantic_headline 
CREATE OR REPLACE FUNCTION ts_semantic_headline 
(config REGCONFIG, content TEXT, user_search TSQUERY, options TEXT DEFAULT '')
RETURNS TEXT AS
$$
DECLARE cleaned_content TEXT = ts_headline(config, 
                                           content, 
										   user_search, 
										   'StartSel="",StopSel="",' || options);
BEGIN
	cleaned_content := ts_prepare_text_for_tsvector(cleaned_content);
	RETURN ts_semantic_headline(config,
	                            regexp_split_to_array(cleaned_content, '[\s]+'), 
                                TO_TSVECTOR(config, cleaned_content),
                                user_search,
                                options);
END;
$$
STABLE
LANGUAGE plpgsql;

-- Arity-3 Form of simplified ts_semantic_headline 
CREATE OR REPLACE FUNCTION ts_semantic_headline
(content TEXT, user_search TSQUERY, options TEXT DEFAULT '')
RETURNS TEXT AS
$$
BEGIN
	RETURN ts_semantic_headline(current_setting('default_text_search_config')::REGCONFIG, 
	                            content, 
								user_search, 
								options);
END;
$$
STABLE
LANGUAGE plpgsql;
/*
Function: ts_vector_to_table

Accepts: 
- input_vector TSVECTOR - a TSVector containing BOTH lexemes and positions 

Returns a table of the lexemes and positions of the TSVector, ordered by
position ASC. In effect, this function UNNESTs a TSVector into a table.
*/

CREATE OR REPLACE FUNCTION ts_vector_to_table(input_vector TSVECTOR)
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