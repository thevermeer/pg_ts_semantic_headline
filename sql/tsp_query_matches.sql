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
