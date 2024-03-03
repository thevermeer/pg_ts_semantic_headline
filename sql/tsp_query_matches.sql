/*
Function: TSP_QUERY_MATCHES
Accepts: 
- config       REGCONFIG - PGSQL Text Search Language Configuration
- haystack_arr TEXT[]    - Ordered array of words, as they appear in the source
                           document, delimited by spaces. Assumes text is preprocessed
                           by tsp_indexable text function
- content_tsv  TSVECTOR  - TSVector representation of the source document. Assumes text 
                           is preprocessed by tsp_indexable text function to maintain
                           the correct positionality of lexemes.
- search_query TSPQUERY  - TSPQuery representation of a user-inputted search.
- match_limit  INTEGER   - Number of matches to return from the start of the document.
                           Defaults to 5.

Returns a table of exact matches returned from the fuzzy TSPQuery search, Each row contains:
- words     TEXT     - the exact string found in the text
- ts_query  TSQUERY  - the TSQuery phrase pattern that matches `words` text. A given TSQuery 
                       can contain multiple phrase patterns
- start_pos SMALLINT - the first word position of the found term within the document.
- end_pos   SMALLINT - the last word position of the found term within the document.

Reduces the TSPQuery into a collection of TSVector phrase patterns; Reduces the source
TSVector to a filtered TSV containing only the lexemes in the TSPQuery. JOINs the 
exploded TSPQuery (as a table of lexemes and positions) to the TSvector (also as a table)
of lexemes and positions. JOINing, reducing and GROUPing, herein we implement the 
matching pattern inherent in the TSVECTOR @@ TSQUERY searching operation.

Performing this lookup on pre-computed, pre-treated (ts_indexable_text + UNACCENT) 
ts_vectors is surprisingly fast. Using a pre-computer TEXT[] array as a RECALL index
drastically reduces the computational and memory overhead of this function.

Support TSQuery logical operators (&, |, !) as well as phrase distance/proximity 
operators (<->, <n>).

Currently does NOT support TSQuery Wildcards (*), but that is the only known 
exception at present.
*/


-- Internal Helper Function, broken out for debugging
-- Returns a filtered TSV containing ONLY the lexemes within
CREATE OR REPLACE FUNCTION tsp_filter_tsvector_with_tsquery
(config REGCONFIG, tsv TSVECTOR,  search_query TSQUERY)
RETURNS TSVECTOR AS
$$    
BEGIN
   RETURN 
    (SELECT ts_filter(setweight(tsv, 'A', ARRAY_AGG(lexes)), '{a}')
     FROM (SELECT UNNEST(tsvector_to_array(vec.phrase_vector)) AS lexes
           FROM tsquery_to_tsvector(config, search_query) AS vec) AS query2vec);
END;
$$
STABLE
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION TSP_QUERY_MATCHES
(config REGCONFIG, haystack_arr TEXT[], content_tsv TSPVECTOR, search_query TSPQUERY, 
 match_limit INTEGER DEFAULT 5, 
 disable_semantic_check BOOLEAN DEFAULT FALSE)

RETURNS TABLE(words TEXT, 
              ts_query TSPQUERY, 
              start_pos SMALLINT, 
              end_pos SMALLINT) AS
$$    
BEGIN
    -- Reduce the input TSV to only the lexemes matching the query
    content_tsv := tsp_filter_tsvector_with_tsquery(config, content_tsv, search_query);

    RETURN QUERY
    (   SELECT array_to_string(haystack_arr[first:last], ' '),           
               query::TSPQUERY,
               first, 
               last
        FROM (SELECT MIN(pos) AS first, 
                     MAX(pos) AS last, 
                     range_start AS range_start, 
                     MAX(lex) as lex,
                     phrase_query as query
              FROM (SELECT phrase_vector,
                           query_vec.phrase_query,
                           (SELECT COUNT(*) FROM TSVECTOR_TO_TABLE(phrase_vector)) AS query_length, 
                           haystack.lex,
                           haystack.pos AS pos, 
                           haystack.pos - query_vec.pos 
                           + (SELECT MIN(pos) 
                              FROM TSVECTOR_TO_TABLE(query_vec.phrase_vector)) as range_start
                    FROM TSQUERY_TO_TABLE(config, search_query) AS query_vec 
                    INNER JOIN TSVECTOR_TO_TABLE(content_tsv) AS haystack 
                    ON haystack.lex = query_vec.lexeme) AS joined_terms
              GROUP BY range_start, query, query_length 
              HAVING COUNT(*) = query_length) AS phrase_agg
        WHERE (last - first) = (SELECT MAX(pos) - MIN(pos) 
                                FROM TSQUERY_TO_TABLE(config, query))
        AND (disable_semantic_check 
             OR TO_TSPVECTOR(config, array_to_string(haystack_arr[first:last], ' ')) @@ query::TSQUERY)
        LIMIT match_limit);
END;
$$
STABLE
LANGUAGE plpgsql;


-- OVERLOAD Arity-5 form, to infer the default_text_search_config for parsing
CREATE OR REPLACE FUNCTION TSP_QUERY_MATCHES
(haystack_arr TEXT[], content_tsv TSPVECTOR, search_query TSPQUERY, match_limit INTEGER DEFAULT 5)
RETURNS TABLE(words TEXT, 
              ts_query TSPQUERY, 
              start_pos SMALLINT, 
              end_pos SMALLINT) AS
$$    
BEGIN
   RETURN QUERY
    (SELECT *
     FROM   TSP_QUERY_MATCHES(current_setting('default_text_search_config')::REGCONFIG,
                             haystack_arr, 
                             content_tsv, 
                             search_query, 
                             match_limit));
END;
$$
STABLE
LANGUAGE plpgsql;
