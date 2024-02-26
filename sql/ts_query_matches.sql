

CREATE OR REPLACE FUNCTION ts_query_matches(haystack_arr TEXT[], content_tsv TSVECTOR, search_query TSQUERY, match_limit INTEGER DEFAULT 5)
RETURNS TABLE(words TEXT, ts_query TSQUERY, group_no SMALLINT, start_pos SMALLINT, end_pos SMALLINT) AS
$$    
BEGIN
    content_tsv := (SELECT ts_filter(setweight(content_tsv, 'A', ARRAY_AGG(lexes)), '{a}')
                    FROM (SELECT UNNEST(tsvector_to_array(vec.phrase_vector)) AS lexes
                          FROM ts_query_to_ts_vector(search_query) AS vec));
    RETURN QUERY
    (   SELECT array_to_string(haystack_arr[first:last], ' ') as found_words,           
               query AS pq,
               range_start,
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
                    ON haystack.lex = query_vec.lexeme)
              GROUP BY range_start, query, phrase_vector 
              HAVING COUNT(*) = length(phrase_vector))
        WHERE (last - first) = (SELECT MAX(pos) - MIN(pos) 
                                FROM ts_query_to_table(query::TSQUERY))
        AND array_to_string(haystack_arr[first:last], ' ') @@ query::TSQUERY
        LIMIT match_limit);
END;
$$
STABLE
LANGUAGE plpgsql;
