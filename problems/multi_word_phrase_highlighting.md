# Highlightling multi-word phrases

For multi-word search terms, only the single words that comprise the search term are highlighted. Combining this with the first issue (ts_headline returns passages that do NOT contain the searched phrase), we will display highlights that do not fully demonstrate the phrase semantics of search applied. For instance:
```
SELECT ts_headline('search is separate from term and then combined in a search term', 
                   to_tsquery('search<->term'));

::>
<b>search</b> is separate from <b>term</b> and then combined in a <b>search</b> <b>term</b>
```
In this case, the desired result is that the phrase, in its full form, is highlighted as a single term. That is, `<b>search</b> <b>term</b>` should be returned as `<b>search term</b>`:
```
<b>search</b> is separate from <b>term</b> and then combined in a <b>search term</b>
```

This is particularly important when highlighting multi-word search terms that include stop-words in the query. Consider:
```
SELECT ts_headline('Do not underestimate the power of the pen in changing the world.', 
                   to_tsquery('power<->of<->the<->pen'));

::>
Do not underestimate the <b>power</b> of the <b>pen</b> in changing the world.
```
However, we want the entire phrase highlighted and wrapped in a single tag, like so:
```
Do not underestimate the <b>power of the pen</b> in changing the world.
```

## Approach
### Function should accept pre-computed TSVector
Taking note of the various arguments and arities of the built_in `ts_headline` function, we notice that ts_headline does not accept a precomputed TSVector, and computes the lexeme position of a given source text on every invocation. This should hint as to one of the many reasons that `ts_headline` is so woefully non-performant. Given that it is recommended to pre-compute text into TSVectors, one of the aims of this work is to leverage pre-computed TSVectors in order to deliver `ts_headline` functionality with less computational overhead. (At the cost of disk space, mind you...)

### Function will convert search phrase into TSVector
Secondly, as `ts_headline` only highlights single words in a multi-word search term, we need a different way of matching and retrieving the multi-word search patterns and their location in the TSVector. In order to do this, we are going to write a function that accepts a phrase as a string and converts that phrase to a tsvector. In turn, we are going to use the query/needle TSVector to identify matching phrase patterns in the haystack TSVector.

### Function will expand on our efficient ts_exact_matches function
Our work begins with the `ts_exact_phrase_matches` function that we created in this repo, and refined in [[Performant Exact Phrase Matches Function](https://github.com/thevermeer/postgresql_semantic_tsheadline/blob/main/problems/efficient_headlines.md#performant-exact-phrase-matches-function)]:
```
CREATE OR REPLACE FUNCTION ts_exact_phrase_matches(haystack_arr TEXT[], content_tsv TSVECTOR, user_search TEXT)
RETURNS TABLE(positions TEXT) AS
$$
DECLARE minmaxarr SMALLINT[];
DECLARE search_vec TSVECTOR;
    
BEGIN
	user_search := prepare_text_for_tsvector(user_search);
	search_vec  := TO_TSVECTOR(user_search);
	minmaxarr   := (SELECT ARRAY[MIN(pos), MAX(pos)] FROM ts_vector_to_table(search_vec));
	
    RETURN QUERY 
          (SELECT replace(array_to_string(haystack_arr[first:last], ' '), chr(1) || ' ', '')
           FROM (SELECT MIN(pos) AS first, MAX(pos) AS last 
                 FROM (SELECT haystack.pos, 
                              haystack.pos - (query_vec.pos - minmaxarr[1]) as range_start
                       FROM (SELECT lex, pos FROM ts_vector_to_table(ts_filter(setweight(content_tsv, 
	           		                                                                     'A', 
	           		                                                                     tsvector_to_array(search_vec)), 
	           		                                                           '{a}'))) AS haystack 
			           INNER JOIN ts_vector_to_table(search_vec) AS query_vec 
			           ON haystack.lex = query_vec.lex)
	      		 GROUP BY range_start)
           WHERE (minmaxarr[2] - minmaxarr[1]) = (last - first)
           AND array_to_string(haystack_arr[first:last], ' ') @@ phraseto_tsquery(user_search)
           ORDER BY first ASC);
END;
$$
STABLE
LANGUAGE plpgsql;
```

We are going to use this function to not only retrieve the exact matching text, we also the previous `n=10` words on either side of the match. To do this, we are going to replace `array_to_string(haystack_arr[first:last], ' ')` with a concatenation of string aggregations:
```
array_to_string(haystack_arr[first-10:first-1], ' ') ||
' <b>' || 
array_to_string(haystack_arr[first:last], ' ') || 
'</b> ' || 
array_to_string(haystack_arr[last+1:last+10], ' ')
```

Next, our function currently returns all of the exact phrase matches for a given section of content. Let's put a `LIMIT 5` on that to render the first 5 headlines in a document.

Finally, we take the returning record of texts and aggregate it into a single string using `string_agg(blurb, ' ... ' ) AS headline`

The result is the first iteration of our phrase headline function:
```
CREATE OR REPLACE FUNCTION ts_phrase_headlines(haystack_arr TEXT[], content_tsv TSVECTOR, user_search TEXT)
RETURNS TEXT AS
$$
DECLARE minmaxarr SMALLINT[];
DECLARE search_vec TSVECTOR;
    
BEGIN
	user_search := prepare_text_for_tsvector(user_search);
	search_vec  := TO_TSVECTOR(user_search);
	minmaxarr   := (SELECT ARRAY[MIN(pos), MAX(pos)] FROM ts_vector_to_table(search_vec));
	
    RETURN 
          (SELECT string_agg(blurb, ' ... ' )
           FROM (SELECT replace( array_to_string(haystack_arr[GREATEST(first-5, 1):first-1], ' ') ||
                                    ' <b>' || 
                                    array_to_string(haystack_arr[first:last], ' ') || 
                                    '</b> ' || 
                                    array_to_string(haystack_arr[last+1:last+5], ' ')
                                    , 
                               chr(1) || ' ', 
                               '') as blurb
                 FROM (SELECT MIN(pos) AS first, MAX(pos) AS last 
                       FROM (SELECT haystack.pos, 
                                    haystack.pos - (query_vec.pos - minmaxarr[1]) as range_start
                             FROM (SELECT lex, pos FROM ts_vector_to_table(ts_filter(setweight(content_tsv, 
	           		                                                                           'A', 
	           		                                                                           tsvector_to_array(search_vec)), 
	           		                                                                 '{a}'))) AS haystack 
			           INNER JOIN ts_vector_to_table(search_vec) AS query_vec 
			           ON haystack.lex = query_vec.lex
			           ORDER BY haystack.pos
			           LIMIT 5)
	      		 GROUP BY range_start)
           WHERE (minmaxarr[2] - minmaxarr[1]) = (last - first)
           AND array_to_string(haystack_arr[first:last], ' ') @@ phraseto_tsquery(user_search)
           ORDER BY first ASC));
END;
$$
STABLE
LANGUAGE plpgsql;
```
