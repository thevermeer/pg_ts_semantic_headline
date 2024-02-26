CREATE OR REPLACE FUNCTION ts_semantic_headline(haystack_arr TEXT[], content_tsv TSVECTOR, search_query TSQUERY, options TEXT DEFAULT ' ')
RETURNS TEXT AS
$$
DECLARE
    -- Parse Options string to JSON map --
    opts          JSON    = (SELECT JSON_OBJECT_AGG(grp[1], COALESCE(grp[2], grp[3])) AS opt 
                             FROM REGEXP_MATCHES(options, 
                                                 '(\w+)=(?:"([^"]+)"|((?:(?![\s,]+\w+=).)+))', 
                                                 'g') as matches(grp));
    -- Options Map and Default Values --
    tag_range     TEXT    = COALESCE(opts->>'StartSel', '<b>') || E'\\1' || COALESCE(opts->>'StopSel', '</b>');
    min_words     INTEGER = COALESCE((opts->>'MinWords')::SMALLINT / 2, 10);
    max_words     INTEGER = COALESCE((opts->>'MaxWords')::SMALLINT, 30);
    max_offset    INTEGER = max_words / 2 + 1;
    max_fragments INTEGER = COALESCE((opts->>'MaxFragments')::INTEGER, 1);
BEGIN
    RETURN (
		SELECT prepare_text_for_presentation(STRING_AGG(highlighted_text,
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
		      FROM ts_query_matches(haystack_arr, content_tsv, search_query, max_fragments + 3)
			  GROUP BY (group_no / (max_words + 1)) * (max_words + 1)
			  ORDER BY COUNT(*) DESC, (group_no / (max_words + 1)) * (max_words + 1)
			  LIMIT max_fragments));
END;
$$
STABLE
LANGUAGE plpgsql;
  
CREATE OR REPLACE FUNCTION ts_semantic_headline(config REGCONFIG, content TEXT, user_search TSQUERY, options TEXT DEFAULT '')
RETURNS TEXT AS
$$
DECLARE cleaned_content TEXT = ts_headline(config, content, user_search, 'StartSel="",StopSel="",' || options);
BEGIN
	cleaned_content := ts_prepare_text_for_tsvector(cleaned_content);
	RETURN  (SELECT ts_semantic_headline(regexp_split_to_array(cleaned_content, '[\s]+'), 
                                         TO_TSVECTOR(cleaned_content),
                                         user_search,
                                         options));
END;
$$
STABLE
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION ts_semantic_headline(content TEXT, user_search TSQUERY, options TEXT DEFAULT '')
RETURNS TEXT AS
$$
BEGIN
	RETURN (SELECT ts_semantic_headline('english', content, user_search, options));
END;
$$
STABLE
LANGUAGE plpgsql;