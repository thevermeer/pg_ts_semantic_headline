/*
Function: TS_FAST_HEADLINE
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

Internally, this function calls TSP_QUERY_MATCHES, aggregates ranges based on 
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

-- Arity-5 Form of fast TS_FAST_HEADLINE with pre-computed arr & tsv

CREATE OR REPLACE FUNCTION TS_FAST_HEADLINE_COVER_DENSITY 
(config REGCONFIG, haystack_arr TEXT[], content_tsv TSPVECTOR, search_query TSPQUERY, options TEXT DEFAULT '')
RETURNS TABLE(headline TEXT, density INTEGER) AS
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
    RETURN QUERY (
		 SELECT REGEXP_REPLACE(-- Aggregate the source text over a Range
		                            ' ' || 
									ARRAY_TO_STRING(haystack_arr[MIN(start_pos) - GREATEST((max_offset - (MAX(end_pos) - MIN(start_pos) / 2 + 1)), min_words): 
		                                                         MAX(end_pos)   + GREATEST((max_offset - (MAX(end_pos) - MIN(start_pos) / 2 + 1)), min_words)], 
		                                                   ' ') || ' ', 
				                    -- Capture Exact Matches over Range
				                    E' (' || STRING_AGG(REGEXP_REPLACE(words, '([\.\+\*\?\^\$\(\)\[\]\{\}\|\\])', '\\\1', 'g'), '|') || ') ', 
				                    -- Replace with Tags wrapping Content
				                    ' ' || tag_range || ' ', 
				                    'g') AS highlighted_text,
				     COUNT(*)::INTEGER AS match_count
		      FROM TSP_QUERY_MATCHES (config, 
			                          haystack_arr, 
									  content_tsv, 
									  search_query, 
									  max_fragments + 6, 
									  COALESCE(opts->>'DisableSematics', 'FALSE')::BOOLEAN)
			  GROUP BY (start_pos / (max_words + 1)) * (max_words + 1)
			  ORDER BY COUNT(*) DESC, (start_pos / (max_words + 1)) * (max_words + 1)
			  LIMIT max_fragments);
END;
$$
STABLE
LANGUAGE plpgsql;



CREATE OR REPLACE FUNCTION TS_FAST_HEADLINE 
(config REGCONFIG, haystack_arr TEXT[], content_tsv TSPVECTOR, search_query TSPQUERY, options TEXT DEFAULT '')
RETURNS TEXT AS
$$
DECLARE
    -- Parse Options string to JSON map --
    opts          JSON    = (SELECT JSON_OBJECT_AGG(grp[1], COALESCE(grp[2], grp[3])) AS opt 
                             FROM REGEXP_MATCHES(options, 
                                                 '(\w+)=(?:"([^"]+)"|((?:(?![\s,]+\w+=).)+))', 
                                                 'g') as matches(grp));
BEGIN
    RETURN (
		SELECT TSP_PRESENT_TEXT(STRING_AGG(headline,
		                                   COALESCE(opts->>'FragmentDelimiter', '...')),
		                        COALESCE(opts->>'StopSel', '</b>'))
		FROM TS_FAST_HEADLINE_COVER_DENSITY(config, haystack_arr, content_tsv, search_query, options));
END;
$$
STABLE
LANGUAGE plpgsql;


-- OVERLOAD Arity-5 form, to infer the default_text_search_config for parsing
-- Arity-4 Form of fast TS_FAST_HEADLINE with pre-computed arr & tsv
CREATE OR REPLACE FUNCTION TS_FAST_HEADLINE 
(haystack_arr TEXT[], content_tsv TSPVECTOR, search_query TSPQUERY, options TEXT DEFAULT '')
RETURNS TEXT AS
$$
BEGIN
    RETURN TS_FAST_HEADLINE(current_setting('default_text_search_config')::REGCONFIG,
	                        haystack_arr,
	                        content_tsv,
							search_query, 
							options);
END;
$$
STABLE
LANGUAGE plpgsql;
  
