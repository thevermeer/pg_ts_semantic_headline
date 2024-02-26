/*
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
CREATE OR REPLACE FUNCTION ts_query_to_ts_vector(input_query TSQUERY)
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
           FROM (SELECT regexp_split_to_table(input_text, '\&|\|') AS split_query)));
END;
$$
LANGUAGE plpgsql;