# Highlightling multiple, multi-word phrases in a TSQuery
For multi-word search terms, only the single words that comprise the search term are highlighted. Combining this with the first issue (ts_headline returns passages that do NOT contain the searched phrase), we will display highlights that do not fully demonstrate the phrase semantics of search applied. For instance:
```
SELECT ts_headline('search is separate from term and then combined in a search term', 
                   to_tsquery('search<->term'));
```
| ts\_headline |
| --- |
| \<b\>search\</b\> is separate from \<b\>term\</b\> and then combined in a \<b\>search\</b\> \<b\>term\</b\> |

In this case, the desired result is that the phrase, in its full form, is highlighted as a single term. That is, `<b>search</b> <b>term</b>` should be returned as `<b>search term</b>`:
```
<b>search</b> is separate from <b>term</b> and then combined in a <b>search term</b>
```

This is particularly important when highlighting multi-word search terms that include stop-words in the query. Consider:
```
SELECT ts_headline('Do not underestimate the power of the pen in changing the world.', 
                   to_tsquery('power<->of<->the<->pen'));
```
| ts\_headline |
| --- |
| Do not underestimate the \<b\>power\</b\> of the \<b\>pen\</b\> in changing the world. |

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
| replace |
| --- |
| 'needl' &#124; 'friend' \<3\> 'peopl' &#124; 'power' \<2\> 'posit' |

Note above that we are removing the term negated with the `!` operator.

Next, for the purpose of highlighting, we can assume that brackets contained within TSQueries can be ignored, and we are only after the phrases therein.
With that in mind we split our TSQuery string into a table, splitting on either the AND `&` or OR `|` operators. We do this by calling 
`SELECT regexp_split_to_table(input_text, '\&|\|') AS phrase_query)`

To demonstrate:
```
SELECT regexp_split_to_table(replace(querytree('power | (friend<19>people & !(rub<2>life)) | power<2>positive')::TEXT, '<->', '<1>'), '\&|\|');
```
produces:
| regexp\_split\_to\_table |
| --- |
| 'power'  |
|  'friend' \<19\> 'people'  |
|  'power' \<2\> 'positive' |

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
```
| replace\_multiple\_strings |
| --- |
| we are always, always, always giving friends oranges |


From this, we are going to use `regexp_matches` to acrete the `<n>` distance terms and replace them with n-1 dummy entries, and cast that into a TSVECTOR:
```
SELECT to_tsvector((SELECT replace_multiple_strings(phrase_query, 
                                                    array_agg('<' || g[1] || '>'), 
                                                    array_agg(REPEAT(' xdummywordx ', g[1]::SMALLINT - 1)))
                    FROM regexp_matches(phrase_query, '<(\d+)>', 'g') AS matches(g))) as phrase_vec,
       phrase_query::TSQUERY
FROM (SELECT regexp_split_to_table('power | (friend<4>people) | power<2>positive', '\&|\|') AS phrase_query);
```
produces:

| phrase\_vec |phrase\_query |
| --- | --- |
| 'power':1 |'power' |
| 'friend':1 'peopl':5 'xdummywordx':2,3,4 |'friend' \<4\> 'people' |
| 'posit':3 'power':1 'xdummywordx':2 |'power' \<2\> 'positive' |

Note here that we are producing both the TSVector representation while preserving the TSQuery form of the phrase, however our 'xdummywordx' entries remain in the tsvector. Let's filter out the artificial terms by:
1) stemming our `xdummywordx` term to its lexeme, given an unknown default language
2) setting the weight for all terms to A
3) setting the weight for the dummy term as D
4) filtering for only the remaining A-weighted terms
5) remove all the weights

That looks like:
```
SELECT setweight(ts_filter(setweight(setweight(phrase_vec, 'A'), 
                                     'D',
                                     tsvector_to_array('xdummywordx')), 
                           '{a}'), 
                 'D') AS phrase_vector
```

Applying that all together, we will end up with resultant TSVectors that contain only the lexemes from the search pattern, like so:
```
SELECT setweight(ts_filter(setweight(setweight(phrase_vec, 'A'), 
                                          'D',
                                          ARRAY['xdummywordx']), 
                                '{a}'), 
                      'D') AS phrase_vector, 
			phrase_query
FROM (SELECT to_tsvector((SELECT replace_multiple_strings(phrase_query, 
                                                          array_agg('<' || g[1] || '>'), 
                                                          array_agg(REPEAT(' xdummywordx ', g[1]::SMALLINT - 1)))
                          FROM regexp_matches(phrase_query, '<(\d+)>', 'g') AS matches(g))) as phrase_vec,
             phrase_query::TSQUERY
      FROM (SELECT regexp_split_to_table('power | (friend<4>people) | power<2>positive', '\&|\|') AS phrase_query));
```

| phrase\_vector |phrase\_query |
| --- | --- |
| 'power':1 |'power' |
| 'friend':1 'peopl':5 |'friend' \<4\> 'people' |
| 'posit':3 'power':1 |'power' \<2\> 'positive' |


### The ts_query_to_ts_vector function
Here's the function, fully assembled:
```
CREATE OR REPLACE FUNCTION ts_query_to_ts_vector(input_query TSQUERY)
RETURNS TABLE(phrase_vector TSVECTOR, phrase_query TSQUERY) AS
$$
DECLARE
    input_text TEXT;
BEGIN
    input_text := replace(querytree(input_query)::TEXT, '<->', '<1>');
    input_text := regexp_replace(input_text, '\(|\)', '', 'g');
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
| phrase\_vector |phrase\_query |
| --- | --- |
| 'power':1 |'power' |
| 'friend':1 'peopl':20 |'friend' \<19\> 'peopl' |
| 'posit':3 'power':1 |'power' \<2\> 'posit' |


We now have the ability to convert a TSQuery into a TSVector. Based on the techniques developed in [[Retrieveing Exact Matches from PostgreSQL Text Search](https://github.com/thevermeer/postgresql_semantic_tsheadline/blob/main/problems/exact_matches.md)] and streamlined in [[Efficient Content Retrieval](https://github.com/thevermeer/postgresql_semantic_tsheadline/blob/main/problems/efficient_content_retrieval.md)], we will JOIN the needle and haystack TSVectors and determine overlaps. The key difference is that we are now processing multiple multi-words search phrases; in doing that, we are aiming at a single pass join, and not devolving into a FOR loop.

In the _Retrieveing Exact Matches from PostgreSQL Text Search_ document , we brought forward a function, `ts_vector_to_table` for decomposing a TSVector into a table of lexemes and positions, ordered by position. See [[Unnesting a TSVector into a table of occurences](https://github.com/thevermeer/postgresql_semantic_tsheadline/blob/main/problems/exact_matches.md#unnesting-a-tsvector-into-a-table-of-occurences)].

For our purposes now, we will bring our new `ts_query_to_ts_vector` function together with `ts_vector_to_table` for further decompose our TSQuery into a table. We are taking this path because we want to maintain the relative lexeme positions of each of the n phrases contained in the TSQuery; the built-in TSVector concatenate function will NOT preserve the relative positions of the second, concatenated vector, shifting them to the positions AFTER the last lexeme in the first vector. Witness:
```
SELECT * FROM ts_vector_to_table(TO_TSVECTOR('first second third') || TO_TSVECTOR('one two three'));
```
| lex |pos |
| --- | --- |
| first |1 |
| second |2 |
| third |3 |
| one |4 |
| two |5 |
| three |6 |


Semantically, this represent a single, linear phrase of 6 words. What we actually want is EITHER 'first' OR 'one' to occupy position 1, like so:
| lex |pos |
| --- | --- |
| first |1 |
| second |2 |
| third |3 |
| one |1 |
| two |2 |
| three |3 |


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
| phrase\_vector |phrase\_query |lexeme |pos |
| --- | --- | --- | --- |
| 'first':1 'second':2 'third':3 |'first' \<\-\> 'second' \<\-\> 'third' |first |1 |
| 'first':1 'second':2 'third':3 |'first' \<\-\> 'second' \<\-\> 'third' |second |2 |
| 'first':1 'second':2 'third':3 |'first' \<\-\> 'second' \<\-\> 'third' |third |3 |
| 'one':1 'three':3 'two':2 |'one' \<\-\> 'two' \<\-\> 'three' |one |1 |
| 'one':1 'three':3 'two':2 |'one' \<\-\> 'two' \<\-\> 'three' |two |2 |
| 'one':1 'three':3 'two':2 |'one' \<\-\> 'two' \<\-\> 'three' |three |3 |


## Bringing together Semantic TSQuery Headlines
Jumping back to our previous attempt at phrase highlighting, we examine the `ts_phrase_headlines` function:
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

Here, we note that we have:
- only one phrase rendered into a TSVector
- a `minmaxarr` that considers the positions of only one phrase
- `content_tsv` is only being filtered for the lexemes of a single phrase
- `prepare_text_for_tsvector` is going to have to be pushed upstream, into the preprocessing of the TSQuery that we want to highlight.

In order to search over multiple, logically connected phrases, we are going to have to expand our strategy, by:
- Expanding the join in `INNER JOIN ts_vector_to_table(search_vec)` to instead explode the entire TSQuery using `ts_query_to_table`
- Collecting all of the lexemes in each of the search phrases contained in the TSQuery, and filtering `content_tsv` to include those lexemes.
  ```
  content_tsv := (SELECT ts_filter(setweight(content_tsv, 'A', ARRAY_AGG(lexes)), '{a}')
                  FROM (SELECT UNNEST(tsvector_to_array(vec.phrase_vector)) AS lexes
                        FROM ts_query_to_ts_vector(search_query) AS vec));
  ```
  Note that, here we are using the built-in `tsvector_to_array` to return an array of phrase lexemes, unnesting that array, and recomposing the array of lexemes for all phrases.
- For each search phrase in the TSQuery, we will need to calculate its min/max lexeme positions on the fly.

In order to accomplish the task of highlighting multiple query phrases in a single section, we are going to break up our concerns into 2 functions:
- `ts_query_matches` will return a table of the positions and lexemes of a limited number of matches within the document
- `ts_query_headline` will effectively replace the built-in `ts_headline` function, by aggregating over the ranges of lexeme positions returned by `ts_query_matches`.

## The ts_query_matches function
The purpose of the `ts_query_matches` function is to determine the matching position of lexemes within a PGSQL full-text query.

The function accepts:
- `haystack_arr` as an ordered array of words, as they appear in the document, AFTER the source string was treated with the `prepare_text_for_tsvector` string cleaning function
- content_tsv as the TSVector rendered from the content, again, AFTER treatment with `prepare_text_for_tsvector` to ensure that the "haystack" has been cleared of words delimited with special characters, thus preserving the word positions in the TSVector after lexizing and stemming.
- `search_query` as  TSQuery statement; that statement can include multiple phrases separated by OR, AND and NOT `|, &, !` operators, brackets, and will be divided such that the brackets are ignored, and the logical operators are treated as seperators between phrases.
- `match_limit` is the maximum number of matches to return, and parameterizes the arbitrary limit of retulning the first 5 results. This value is quite important in determining the overall performance cost of this function, and the forthcoming function that depends on it. That is, the larger this vallue becomes, the longer the overall runtime of the function.

```
CREATE OR REPLACE FUNCTION ts_query_matches(haystack_arr TEXT[], content_tsv TSVECTOR, search_query TSQUERY, match_limit INTEGER DEFAULT 5)
RETURNS TABLE(words TEXT, tsquery TSQUERY, group_no SMALLINT, start_pos SMALLINT, end_pos SMALLINT) AS
$$    
BEGIN
    content_tsv := (SELECT ts_filter(setweight(content_tsv, 'A', ARRAY_AGG(lexes)), '{a}')
                    FROM (SELECT UNNEST(tsvector_to_array(vec.phrase_vector)) AS lexes
                          FROM ts_query_to_ts_vector(search_query) AS vec));
    RETURN QUERY
    (
        SELECT array_to_string(haystack_arr[first:last], ' ') as found_words,           
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
        LIMIT match_limit
   );
END;
$$
STABLE
LANGUAGE plpgsql;
```

Running the function on a single row in our `files` table, we see:
```
SELECT found.* 
FROM (SELECT * FROM files LIMIT 1), 
     ts_query_matches(content_arr, content_tsv, to_tsquery('best<2>time|worst<2>time')) AS found;
```
Producing:
| words |tsquery |group\_no |start\_pos |end\_pos |
| --- | --- | --- | --- | --- |
| best of times, |'best' \<2\> 'time' |4 |4 |6 |
| worst of times, |'worst' \<2\> 'time' |10 |10 |12 |

That is a simple demonstration of `ts_query_matches` returning the exact matches, phrase queries, and the start/end position of the terms.
In less ideal situations, we can see that a more complex search yields a variety of results:
```
SELECT found.* 
FROM (SELECT * FROM files LIMIT 1), 
     ts_query_matches(content_arr, content_tsv, to_tsquery('best|time|worst')) AS found;
```
Returns 48 results (NOT listed :)) for a single document, and requires ~55ms per row to process. Thus, inside of our function the `LIMIT 5` is an arbitrary and ultimately configurable, in order to balance product and performance needs. _Do we need all 48 examples of a query within a text?_ If not, we will impose a limit.

Nonetheless, consider the results of a more interesting query string, `(swallow<3>london<2>westminster|king<2>queen) & (worst<2>times)`:
```
SELECT found.* 
FROM (SELECT * FROM files LIMIT 1), 
     ts_query_matches(content_arr, 
                      content_tsv, 
                      to_tsquery('(swallow<3>london<2>westminster|king<2>queen) & (worst<2>times)')) AS found;
```
Gives us:
| words |tsquery |group\_no |start\_pos |end\_pos |
| --- | --- | --- | --- | --- |
| worst of times, |'worst' \<2\> 'time' |10 |10 |12 |
| swallowing up of London and Westminster. |'swallow' \<3\> 'london' \<2\> 'westminst' |247 |247 |252 |
| king, the queen, |'king' \<2\> 'queen' |7835 |7835 |7837 |

Putting those pieces together, we now have a function that can retrieve the positions and exact match text of complex TSQuery statements; with the word positions and the exact matches we will be able to formulate, aggregate and regexp_replace our way towards a replacement for `ts_headline`.

## Developing the ts_semantic_headlines function
In order to culminate the progress we have made in searching for TSQuery patterns in TSVectors, and as we can now return the exact positions and strings from compound, multi-phrase TSQueries, aggregate matches in close proximity to each other using `ts_query_exact_matches`, we are ready to aggregate and sort match ranges, and perform highlighting.

Consider the following query that SELECTS from the files table, JOINs to the table/recordset returned by `ts_query_matches`; in this query:
- The `WHERE id = (SELECT MIN(ID) FROM files)` condition will return results from ONLYL one, single file. 
- The `GROUP BY id, ROUND(group_no / 20)` will aggregate results, such that each resulting row will contain data from a single file (grouped by ID), and contains the data for n matches within a 20-word range (grouped by ROUND(group_no / 20)) in the source text. 
- The `ORDER BY COUNT(*) DESC, min_pos ASC` term will sort results such that the word ranges with the highest density of matches will come first, and otherwise results will be ordered by their appearance in the source text.

Examining our exploratory query:
```
SELECT id, 
       COUNT(*) AS match_count,
       MIN(start_pos) AS min_pos, 
       MAX(end_pos) AS max_pos,
       STRING_AGG(words, '|') AS strings_to_replace,
       ARRAY_TO_STRING(content_arr[MIN(start_pos)- 5:MAX(end_pos)+5], ' ') AS content_to_highlight    
FROM files, 
     (SELECT to_tsquery('best<2>time|worst') AS value) as q, 
     ts_query_matches(content_arr, content_tsv, q.value) AS phrases
WHERE id = (SELECT MIN(ID) FROM files)
GROUP BY id, ROUND(group_no / 20)
ORDER BY COUNT(*) DESC, min_pos ASC;
```

Produces:
| id |match\_count |min\_pos |max\_pos |strings\_to\_replace |content\_to\_highlight |
| --- | --- | --- | --- | --- | --- |
| 46250 |2 |4 |10 |best of times, &#124; worst |It was the best of times, it was the worst of times, it was the |
| 46250 |1 |8481 |8481 |worst |now\! The best and the worst are known to you, now. |
| 46250 |1 |12687 |12687 |worst |dear miss\! Courage\! Business\! The worst will be over in a |
| 46250 |1 |12703 |12703 |worst |the room\- door, and the worst is over. Then, all the |

In our result set, we see that:
- `min_pos` is the first matching word found in the range.
- `max_pos` is the last matching word found in the range, though this should not be confused with the last word of the pattern that begins at `min pos`; that is both min_pos and max_pos are aggregated across multiple matches in the range
- `strings_to_replace` is an aggregated string of each of the exact terms found and to be highlighted. the match patterns are delinieated with a `|` which is treated as a logical OR in regexp_replace evaluation, in the next step.
- `content_to_highlight` is a section of the source content, ranging (arbitrarily, for now) from 5 words before `min_pos` to 5 words after `max_pos`

The next step is to take the above recordset, perform `regexp_replace` on the `content_to_highlight` column, replacing `strings_to_replace` with the regex patten that wraps the found string in `<b>` tags. (Again, we will make the `<b>` tag configurable later.) Once we have replaced the tags, we will again aggregate our result-set into a single string, where each range will produce a `fragment` in terms equivalent to the built-in `ts_headline` options parameter.


First, doing away with returning group information of file id, we move towards creating our final string. First, we perform the highlighting via `regexp_replace`:
```
SELECT REGEXP_REPLACE(' ' || ARRAY_TO_STRING(content_arr[MIN(start_pos)- 5:MAX(end_pos)+5], ' ') || ' ', 
                      E' (' || STRING_AGG(words, '|') || ') ', 
                      E'<b>\\1</b>', 'g') AS highlighted_text   
FROM files, 
     (SELECT to_tsquery('best<2>time|worst') AS value) as q, 
     ts_query_matches(content_arr, content_tsv, q.value) AS phrases
WHERE id = (SELECT MIN(ID) FROM files)
GROUP BY id, ROUND(group_no / 20)
ORDER BY COUNT(*) DESC, ROUND(group_no / 20) ASC;
```
This produces:
| highlighted\_text |
| --- |
|  It was the\<b\>best of times,\</b\>it was the\<b\>worst\</b\>of times, it was the  |
|  now\! The best and the\<b\>worst\</b\>are known to you, now.  |
|  dear miss\! Courage\! Business\! The\<b\>worst\</b\>will be over in a  |
|  the room\- door, and the\<b\>worst\</b\>is over. Then, all the  |

As we cannot nest aggregate functions, we need to nest our SELECT statements, in order to produce a single string of multiple fragments/passages as a result:
```
SELECT STRING_AGG(highlighted_text, ' ... ') as headline
FROM (SELECT REGEXP_REPLACE(' ' || ARRAY_TO_STRING(content_arr[MIN(start_pos)- 5:MAX(end_pos)+5], ' ') || ' ', 
                            E' (' || STRING_AGG(words, '|') || ') ', 
                            E'<b>\\1</b>', 'g') AS highlighted_text   
      FROM files, 
           (SELECT to_tsquery('best<2>time|worst') AS value) as q, 
           ts_query_matches(content_arr, content_tsv, q.value) AS phrases
      WHERE id = (SELECT MIN(ID) FROM files)
      GROUP BY id, ROUND(group_no / 20)
      ORDER BY COUNT(*) DESC, ROUND(group_no / 20) ASC);
```
which gives us:
| headline |
| --- |
|  It was the\<b\>best of times,\</b\>it was the\<b\>worst\</b\>of times, it was the  ...  now\! The best and the\<b\>worst\</b\>are known to you, now.  ...  dear miss\! Courage\! Business\! The\<b\>worst\</b\>will be over in a  ...  the room\- door, and the\<b\>worst\</b\>is over. Then, all the  |

The final step is to remove the bell-character + space that we have inserted for indexing. In you recall, we created the `prepare_text_for_presentation` function in the [[Repair treated source text](https://github.com/thevermeer/postgresql_semantic_tsheadline/blob/main/problems/exact_matches.md#function-to-repair-treated-source-text)] section. Let's use it here:

```
SELECT prepare_text_for_presentation(STRING_AGG(highlighted_text, ' ... ')) 
FROM (SELECT REGEXP_REPLACE(' ' || ARRAY_TO_STRING(content_arr[MIN(start_pos)- 5:MAX(end_pos)+5], ' ') || ' ', 
                            E' (' || STRING_AGG(words, '|') || ') ', 
                            E'<b>\\1</b>', 'g') AS highlighted_text   
      FROM files, 
           (SELECT to_tsquery('best<2>time|worst') AS value) as q, 
           ts_query_matches(content_arr, content_tsv, q.value) AS phrases
      WHERE id = (SELECT MIN(ID) FROM files)
      GROUP BY id, ROUND(group_no / 20)
      ORDER BY COUNT(*) DESC, ROUND(group_no / 20) ASC);
```

| prepare\_text\_for\_presentation |
| --- |
|  It was the\<b\>best of times,\</b\>it was the\<b\>worst\</b\>of times, it was the  ...  now\! The best and the\<b\>worst\</b\>are known to you, now.  ...  dear miss\! Courage\! Business\! The\<b\>worst\</b\>will be over in a  ...  the room\-door, and the\<b\>worst\</b\>is over. Then, all the  |

We can clearly see that we have something quite workable as a substitute for `ts_headline`.

### Towards a replacement for ts_headline
Let's bring this into a function and do away with the inner joins and grouping on the `files` table. Replacing and removing SELECT statements in favour of variables, our first version of our function should look like:
```
CREATE OR REPLACE FUNCTION ts_semantic_headline(haystack_arr TEXT[], content_tsv TSVECTOR, search_query TSQUERY)
RETURNS TEXT AS
$$
BEGIN
    RETURN (
		SELECT prepare_text_for_presentation(STRING_AGG(highlighted_text, ' ... '))
		FROM (SELECT REGEXP_REPLACE(ARRAY_TO_STRING(haystack_arr[MIN(start_pos)- 5:MAX(end_pos)+5], ' '), 
				                    E' (' || STRING_AGG(words, '|') || ') ', 
				                    E' <b>\\1</b> ', 'g') AS highlighted_text
		      FROM ts_query_matches(haystack_arr, content_tsv, search_query)
			  GROUP BY ROUND(group_no / 30)
			  ORDER BY COUNT(*) DESC, ROUND(group_no / 30) ASC));
END;
$$
STABLE
LANGUAGE plpgsql;
```

Calling our new function on a single file, we see:
```
SELECT ts_query_headline(content_arr, content_tsv, to_tsquery('arrange<5>swallow<3>london<2>westminster')) FROM files LIMIT 1;
```
| ts\_query\_headline |
| --- |
| sublime appearance by announcing that \<b\>arrangements were made for the swallowing up of London and Westminster.\</b\> Even the Cock\-lane ghost |

Querying `'best<2>time|worst'`, we see:
| ts\_query\_headline |
| --- |
| It was the \<b\>best of times,\</b\> it was the \<b\>worst\</b\> of times, it was the ... now\! The best and the \<b\>worst\</b\> are known to you, now. ... dear miss\! Courage\! Business\! The \<b\>worst\</b\> will be over in a ... the room\-door, and the \<b\>worst\</b\> is over. Then, all the |

Querying 'king | queen', we get:
| ts\_query\_headline |
| --- |
| comparison only. There were a \<b\>king\</b\> with a large jaw and a \<b\>queen\</b\> with a plain face, on the throne of England; there were a \<b\>king\</b\> with a large jaw and ... a large jaw and a \<b\>queen\</b\> with a fair face, on ... his place. “Gentlemen\! In the \<b\>king’\</b\> s name, all of you\!” |

Oops! Our cleaning function is not properly wrapping our end delimiter of '</b>'. As we added the training space after the4 delimiter during text preparation, we need to improve our function to clean our output:

### The prepare_text_for_presentation function (revised)

Up to this point, be have only cleaned our inserted \u0001 (bell character) + SPACE as a string sequence. To better imporove our presentation above, we are going to expand the scope of cleaning up our bell character + space token, by cleaning the pattern `\u0001<\b> `, like so:
```
CREATE OR REPLACE FUNCTION prepare_text_for_presentation (input_text TEXT, end_delimiter TEXT DEFAULT '</b>')
RETURNS TEXT AS
$$
BEGIN
    input_text := regexp_replace(input_text, E'\u0001 ', '', 'g');
    input_text := regexp_replace(input_text, E'\u0001(' || end_delimiter || ') ', E'\\2\\1', 'g');
	RETURN input_text;
END;
$$
STABLE
LANGUAGE plpgsql;
```

Using this, we can better remove hidden bell caharacter and more importantly, their induced, trailing spaces, like so:
```
SELECT prepare_text_for_presentation(ts_new_headline('second-first-third first-second first-second', to_tsquery('first')));
```
| prepare\_text\_for\_presentation |
| --- |
| second\-\<b\>first\-\</b\>third \<b\>first\-\</b\>second \<b\>first\-\</b\>second |

Great! we have gotten rid of all the characters used for indexing text, and can proceed to refining our `ts_query_headline` function.

### Emulating ts_headline options
Per the PostgreSQL documentation for [[ts_headline](https://www.postgresql.org/docs/16/textsearch-controls.html#TEXTSEARCH-HEADLINE)], we need to emulate the following options:
>If an options string is specified it must consist of a comma-separated list of one or more option=value pairs. The available options are:
- `MaxWords`, `MinWords` (integers): these numbers determine the longest and shortest headlines to output. The default values are 35 and 15.
- `ShortWord` (integer): words of this length or less will be dropped at the start and end of a headline, unless they are query terms. The default value of three eliminates common English articles.
- `HighlightAll` (boolean): if true the whole document will be used as the headline, ignoring the preceding three parameters. The default is false.
- `MaxFragments` (integer): maximum number of text fragments to display. The default value of zero selects a non-fragment-based headline generation method. A value greater than zero selects fragment-based headline generation (see below).
- `StartSel`, `StopSel` (strings): the strings with which to delimit query words appearing in the document, to distinguish them from other excerpted words. The default values are “<b>” and “</b>”, which can be suitable for HTML output.
- `FragmentDelimiter` (string): When more than one fragment is displayed, the fragments will be separated by this string. The default is “ ... ”.

Needless to say, there are strict expextations as to the format of the options string; we will parse the string into a json object, like so:
```
WITH options_map AS (SELECT json_object_agg(grp[1], COALESCE(grp[2], grp[3])) AS opt 
                 FROM regexp_matches('Key1=Value1,Key2=Value2', '(\w+)=(?:"([^"]+)"|((?:(?![\s,]+\w+=).)+))', 'g') as matches(grp))
SELECT opt->'Key1' as value FROM options_map;
```
and that gives us:
| value |
| --- |
| "Value1" |

With that we can incorporate the options into our function, by parsing the options string into a JSON map and then destructuring the map and using `COALESCE` to fall over to default values:
```
CREATE OR REPLACE FUNCTION ts_semantic_headline(haystack_arr TEXT[], content_tsv TSVECTOR, search_query TSQUERY, options TEXT DEFAULT '')
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
		                            ' ' || ARRAY_TO_STRING(haystack_arr[MIN(start_pos) - 
                                                                        GREATEST((max_offset - (MAX(end_pos) - MIN(start_pos) / 2 + 1)), min_words): 
		                                                                MAX(end_pos) + 
                                                                        GREATEST((max_offset - (MAX(end_pos) - MIN(start_pos) / 2 + 1)), min_words)], 
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
```
