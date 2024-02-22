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
                       FROM (SELECT lex, pos FROM ts_vector_to_table(content_tsv)) AS haystack 
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
        content_tsv := ts_filter(setweight(content_tsv, 'A', tsvector_to_array(search_vec)), '{a}');
	
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
                             FROM (SELECT lex, pos FROM ts_vector_to_table(content_tsv)) AS haystack 
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
### Limitiations with the above approach
There are a few major limitations with the approach above:
- The above function returns a row for every match. In searching the term `time` in Dickens' _A Tale Of Two Cities_, the first two results returned are: `it was the best of <b>times</b>` followed by a second row: `it was the worst of <b>times</b>`. Ideally we would get one secction: `it was the best of <b>times</b>, it was the worst of <b>times</b>`.
- The function above will only highlight a single phrase and does not respect logical operators (AND[&], OR[|])
- The function above will not respect TS proximity/distance operators. For instance, a TSQuery of the form `needle<3>haystack` should match the string `needle in the haystack` and other phrases where the `haystack` lexeme is `<3>` (three) words from the `needle` lexeme.

## The Path Towards Better Fragmenting and full TSQuery Semantics
Our current approach accepts a phrase as a string, converts that string into a TSVECTOR, and finds matching patterns against the precomputed haystack `content_tsv` TSVECTOR. If we want to achieve the functional capabilities required to overcome the above limitations, we will need to evolve our code, from accepting a phrase string, to accepting a TSQUERY.

Thus, our new function will accept a `TSQUERY` and we will have to be able to:
- Split the incoming `TSQUERY` by logical operator, 
- Produce a TSVECTOR as a pattern representation of a TSQuery
- Using our function `ts_vector_to_table`, we are going to decompose our TSQUERY into a table of lexemes and positions.
- We will apply the same table join between the `query_vec` recordset/table and the haystack, but we will need to carry through information about the various phrase we split, as we will need to determine min and max positions for each phrase we have parsed.

Let's take this piece by piece.

## Converting a TSQuery into a TSVector
In order to convert a TS Query into a vector, we are going to:
1) Split the string on either an AND `&` or OR `|` operator, rendering a table/recordset of phrases
2) For each phrase, we are going to replace each of the distance operators `<n>` with n-1 dummy words in the string
3) Once the phrase is expressed as an exploded string, we parse it as a ts vector
4) The resulting TS Vector will have lexemes located at appropriate positions and dummy entries; we filter the dummy entries out and return both the phrase vector and the phrase query

Let's try this out:
First, we are going to clean up the text representation of the TSQuery by expanding the "beside" `<->` operator to a distance=1 tag:
`input_text := replace(input_query::TEXT, '<->', '<1>');`

Next, we are going to disregard any parts of the query that can be negated. To accomplish this, we are going to treat our input query using the pgsql built-in function `querytree`, which disregards the negated terms. Putting these pieces together, we have:
`input_text := replace(querytree(input_query)::TEXT, '<->', '<1>');`

Using a query like `to_tsquery('needles | (friend<3>people & !(rub<2>life)) | power<2>positive')`:
```
SELECT replace(querytree(to_tsquery('needles | (friend<3>people & !(rub<2>life)) | power<2>positive'))::TEXT, '<->', '<1>');
```
produces:
```
'needl' | 'friend' <3> 'peopl' | 'power' <2> 'posit'
```
Note above that we are removing the term negated with the `!` operator.

Next, for the purpose of highlighting, we can assume that brackets contained within TSQueries can be ignored, and we are only after the phrases therein.
With that in mind we split our TSQuery string into a table, splitting on either the AND `&` or OR `|` operators. We do this by calling 
`SELECT regexp_split_to_table(input_text, '\&|\|') AS phrase_query)`

To demonstrate:
```
SELECT regexp_split_to_table(replace(querytree('power | (friend<19>people & !(rub<2>life)) | power<2>positive')::TEXT, '<->', '<1>'), '\&|\|')
```
produces:
```
 phrase_query
--------------
 'power'  
  'friend' <19> 'people'
  'power' <2> 'positive' 
```
### The replace_multiple_strings function
For each one of the phrases in the resulting table, we want to replace the distances terms `<n>` with n-1 dummy terms. Due to the limitations of PGSQL's regexp_replace function we cannot directly cast the string matched to the INTEGER value of n, so instead we are going to have to use regexp_matches and then write a crafty little function that accepts a source TEXT string, a TEXT[] array of strings to find, and a TEXT[] array of replacement strings.

That funciton looks like:
```
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
```

That should be relatively straightforward:
```
SELECT replace_multiple_strings('we are never, never, never getting back together', 
                                ARRAY['never', 'getting', 'back', 'together'], 
                                ARRAY['always', 'giving', 'friends', 'oranges']);
::>
we are always, always, always giving friends oranges
```

From this, we are going to use `regexp_matches` to acrete the `<n>` distance terms and replace them with n-1 dummy entries, and cast that into a TSVECTOR:
```
to_tsvector((SELECT replace_multiple_strings(phrase_query, 
                                             array_agg('<' || g[1] || '>'), 
                                             array_agg(REPEAT(' xdummywordx ', g[1]::SMALLINT - 1)))
             FROM regexp_matches(phrase_query, '<(\d+)>', 'g') AS matches(g)))
```
produces:
```
 phrase_vec | phrase_query
---------------------------
 'power':1 |'power' 
 'friend':1 'peopl':5 'xdummywordx':2,3,4  | 'friend' <4> 'people' 
 'posit':3 'power':1 'xdummywordx':2       | 'power' <2> 'positive' 
```
Note here that we are producig both the TSVector representation while preserving the TSQuery form of the phrase, however our 'xdummywordx' entries remain in the tsvector. Let's filter out the artificial terms by:
1) setting the weight for all terms to A
2) setting the weight for the dummy term as D
3) filtering for only the remaining A-weighted terms
4) remove all the weights

That looks like:
```
SELECT setweight(ts_filter(setweight(setweight(phrase_vec, 'A'), 
                                     'D',
                                     ARRAY['xdummywordx']), 
                           '{a}'), 
                 'D') AS phrase_vector
```

### The ts_query_to_ts_vector function
Here's the function fully assembled:
```
CREATE OR REPLACE FUNCTION ts_query_to_ts_vector(input_query TSQUERY)
RETURNS TABLE(phrase_vector TSVECTOR, phrase_query TSQUERY) AS
$$
DECLARE
    input_text TEXT;
BEGIN
    input_text := replace(querytree(input_query)::TEXT, '<->', '<1>');
    RETURN QUERY 
    (SELECT setweight(ts_filter(setweight(setweight(phrase_vec, 'A'), 
                                          'D',
                                          ARRAY['xdummywordx']), 
                                '{a}'), 
                      'D') AS phrase_vector, 
            split_query AS phrase_query
     FROM (SELECT to_tsvector((SELECT replace_multiple_strings(split_query, 
                                                               array_agg('<' || g[1] || '>'), 
                                                               array_agg(REPEAT(' xdummywordx ', g[1]::SMALLINT - 1)))
                               FROM regexp_matches(split_query, '<(\d+)>', 'g') AS matches(g))) as phrase_vec,
                  split_query::TSQUERY
           FROM (SELECT regexp_split_to_table(input_text, '\&|\|') AS split_query)));
END;
$$
LANGUAGE plpgsql;
```

All together, `ts_query_to_ts_vector` accepts a TSQuery and converts it into a table of phrases, returning both the TSVector and TSQuery representation of a phrase. Consider:
```
SELECT *  FROM ts_query_to_ts_vector(to_tsquery('power | (friend<19>people & !(rub<2>life)) | power<2>positive'));
```
Produces:
```
 phrase_vector |  phrase_query 
-------------------------------
 'power':1              |  'power' 
 'friend':1 'peopl':20  |  'friend' <19> 'peopl' 
 'posit':3 'power':1    |  'power' <2> 'posit' 
```

We now have the ability to convert a TSQuery into a TSVector. Based on the techniques developed in [[Retrieveing Exact Matches from PostgreSQL Text Search](https://github.com/thevermeer/postgresql_semantic_tsheadline/blob/main/problems/exact_matches.md)] and streamlined in [[Efficient Content Retrieval](https://github.com/thevermeer/postgresql_semantic_tsheadline/blob/main/problems/efficient_content_retrieval.md)], we will JOIN the needle and haystack TSVectors and determine overlaps. The key difference is that we are now processing multiple multi-words search phrases; in doing that, we are aiming at a single pass join, and not devolving into a FOR loop.

In the _Retrieveing Exact Matches from PostgreSQL Text Search_ document , we brought forward a function, `ts_vector_to_table` for decomposing a TSVector into a table of lexemes and positions, ordered by position. See [[Unnesting a TSVector into a table of occurences](https://github.com/thevermeer/postgresql_semantic_tsheadline/blob/main/problems/exact_matches.md#unnesting-a-tsvector-into-a-table-of-occurences)].

For our purposes now, we will bring our new `ts_query_to_ts_vector` function together with `ts_vector_to_table` for further decompose our TSQuery into a table. We are taking this path because we want to maintain the relative lexeme positions of each of the n phrases contained in the TSQuery; the built-in TSVector concatenate function will NOT preserve the relative positions of the second, concatenated vector, shifting them to the positions AFTER the last lexeme in the first vector. Witness:
```
SELECT * FROM ts_vector_to_table(TO_TSVECTOR('first second third') || TO_TSVECTOR('one two three'));
::>
 lex | pos 
------------
 first | 1 
 second | 2 
 third | 3 
 one | 4 
 two | 5 
 three | 6 
```
Semantically, this represent a single, linear phrase of 6 words. What we actually want is EITHER 'first' OR 'one' to occupy position 1, like so:
```
 lex | pos 
------------
 first | 1 
 second | 2 
 third | 3 
 one | 1 
 two | 2 
 three | 3 
```

### The ts_query_to_table function
Keeping the above in mind, we bring together our TSQuery decomposed into a table of TSVectors, with our function that decomposes a TSVector into a table of lexemes and their positions. This gives us:
```
CREATE OR REPLACE FUNCTION ts_query_to_table(input_query TSQUERY)
RETURNS TABLE(phrase_vector TSVECTOR, phrase_query TSQUERY, lexeme TEXT, pos SMALLINT) AS
$$
BEGIN
	RETURN QUERY 
	(WITH phrases AS (SELECT phrase.phrase_vector, phrase.phrase_query 
	                  FROM ts_query_to_ts_vector(input_query) AS phrase)
     SELECT phrases.phrase_vector, 
            phrases.phrase_query,
            word.lex, 
            word.pos
     FROM phrases, ts_vector_to_table(phrases.phrase_vector) AS word);
END;
$$
STABLE
LANGUAGE plpgsql;
```
With that, from the example immediately above:
```
SELECT * FROM ts_query_to_table('first<->second<->third|one<->two<->three');
```
Produces:
```
 phrase_vector |  phrase_query |  lexeme |  pos 
--------------------------------------------
 'first':1 'second':2 'third':3 |'first' \<\-\> 'second' \<\-\> 'third' | first  | 1 
 'first':1 'second':2 'third':3 |'first' \<\-\> 'second' \<\-\> 'third' | second | 2 
 'first':1 'second':2 'third':3 |'first' \<\-\> 'second' \<\-\> 'third' | third  | 3 
 'one':1 'three':3 'two':2      |'one' \<\-\> 'two' \<\-\> 'three'      | one    | 1 
 'one':1 'three':3 'two':2      |'one' \<\-\> 'two' \<\-\> 'three'      | two    | 2 
 'one':1 'three':3 'two':2      |'one' \<\-\> 'two' \<\-\> 'three'      | three  | 3 
```
