# Efficient Content Retrieval 
The goal of this work is to take the discovery done in the previous sections and, through both database schema and UDFs (User-Defined PGSQL functions), deliver `ts_headline` functionality up to 10x faster than the OOTB `ts_headline` functionality.

## Preamble
In [[Retrieveing Exact Matches from PostgreSQL Text Search](https://github.com/thevermeer/postgresql_semantic_tsheadline/blob/main/problems/exact_matches.md)] we came up with a basic approach to identifies the exact text being matched by PostgreSQL's fuzzy full-text search, when being reduced by the default `english-stem` dictionary.

Our initial function runs **5 times** slower that the postgresql built-in `ts_headline` function:
```
CREATE OR REPLACE FUNCTION ts_exact_phrase_matches(content TEXT, content_tsv TSVECTOR, user_search TEXT)
RETURNS TABLE(lex TEXT) AS
$$
DECLARE minmaxarr SMALLINT[];
DECLARE search_vec TSVECTOR;
    
BEGIN
	search_vec := TO_TSVECTOR(substitute_characters(user_search));
	content := substitute_characters(content);
	SELECT ARRAY[MIN(pos), MAX(pos)] FROM tsvector_to_table(search_vec) INTO minmaxarr;
	
    RETURN QUERY 
     (SELECT match
	  FROM (SELECT get_word_range(content, first, last) AS match 
	   	    FROM (SELECT MIN(pos) AS first, MAX(pos) AS last 
		  		  FROM (SELECT haystack.pos, haystack.pos - (query_vec.pos - minmaxarr[1]) as range_start
	           		    FROM tsvector_to_table(content_tsv) AS haystack 
			            INNER JOIN tsvector_to_table(search_vec) AS query_vec 
			            ON haystack.lex = query_vec.lex)
	      		  GROUP BY range_start)
	  		WHERE (minmaxarr[2] - minmaxarr[1]) = (last - first)
	  		ORDER BY first ASC));
END;
$$
STABLE
LANGUAGE plpgsql;
```
As seen here:
```
EXPLAIN ANALYZE
SELECT ts_exact_phrase_matches(
		prepare_text_for_tsvector(content), 
		TO_TSVECTOR(prepare_text_for_tsvector(content)), 
		'Eighteen years!” am the passenger') 
FROM files;
```
| QUERY PLAN |
| --- |
| ProjectSet  \(cost=0.00..610.50 rows=100000 width=32\) \(actual time=6317.262..6317.263 rows=0 loops=1\) |
|   \-\>  Seq Scan on files  \(cost=0.00..10.00 rows=100 width=18\) \(actual time=0.008..0.253 rows=100 loops=1\) |
| Planning Time: 0.282 ms |
| Execution Time: 26244.055 ms |


versus:
```
EXPLAIN ANALYZE SELECT ts_headline(content, phraseto_tsquery('Eighteen years!” said the passenger')) FROM files;
```
| QUERY PLAN |
| --- |
| Seq Scan on files  \(cost=0.00..60.00 rows=100 width=32\) \(actual time=20.584..1879.231 rows=100 loops=1\) |
| Planning Time: 0.056 ms |
| Execution Time: 5592.525 ms |

Clearly, we have a lot of ground to make up.

## Cost Analysis
In examining our UDF, `ts_exact_phrase_matches`, we find that our cost is coming from several places. If it takes 25s to process 100 rows of our `table`, we currently require ~250ms per row. Where is that cost coming from?

### 1. JIT v. Precomputed content TSVector
Generating the `TS_VECTOR` on the fly is expensive and requires ~9 seconds to process per 100 rows. Preferring the pre-computed `content_tsv` column brings our total runtime across 100 records from 25 seconds to 16 seconds.
```
EXPLAIN ANALYZE
SELECT ts_exact_phrase_matches(
		prepare_text_for_tsvector(content), 
		content_tsv, 
		'Eighteen years!” am the passenger') 
FROM files;
```
| QUERY PLAN |
| --- |
| ProjectSet  \(cost=0.00..560.50 rows=100000 width=32\) \(actual time=17063.759..17063.759 rows=0 loops=1\) |
|   \-\>  Seq Scan on files  \(cost=0.00..10.00 rows=100 width=36\) \(actual time=0.011..0.225 rows=100 loops=1\) |
| Planning Time: 0.067 ms |
| Execution Time: 17063.375 ms |


### 2. JIT v. Precomputed content prepare_text_for_tsvector
The call to `prepare_text_for_tsvector(content)` is accounting for roughly 25% of total time (4s or 40ms per row). If we replace that call with a pre-computed row, we see:
```
EXPLAIN ANALYZE
SELECT ts_exact_phrase_matches(
		indexed_content, 
		content_tsv, 
		'Eighteen years!” am the passenger') 
FROM files;
```
| QUERY PLAN |
| --- |
| ProjectSet  \(cost=0.00..535.50 rows=100000 width=32\) \(actual time=13121.386..13121.386 rows=0 loops=1\) |
|   \-\>  Seq Scan on files  \(cost=0.00..10.00 rows=100 width=50\) \(actual time=0.021..0.258 rows=100 loops=1\) |
| Planning Time: 1.217 ms |
| Execution Time: 13121.152 ms |

Great! In 2 steps of precomputing, we have reduced our time to compute by half. Let's keep going!
   
### 3. Use PGSQL's full-text tools to reduce compute load on TSVectors
Unpacking the tsvector of a 16,000+ word document, and the subsequent joining of that to the TSVector of the search query is a significant in-memory table operation; its computation and then aggregation accounts for roughly 3/4th (9 seconds) of the overall cost. Let's find a way of reducing that:

After some reading of PGSQL full-text manipulation functions, we find two of interest:  
a) `setweight(TSVECTOR, TEXT, TEXT[])` - the 3-arity form of this function allows one to add weight strings to a list of the lexemes provided as an array of text in the third argument. If we therefore invoke setweight on the haystack TSV, passing in the array of lexemes in our needle, we 'weight' the relevant query lexemes in the haystack:
```
SELECT setweight(to_tsvector('find this needle and that needle in the haystack'), 'A', ARRAY['needl']);
```
| setweight |
| --- |
| 'find':1 'haystack':9 'needl':3A,6A |

b) `ts_filter(TSVECTOR, CHAR[])` given an array of characters will return a tsvector containing only the elements of the weights provided in the character array as the second argument:
```
SELECT ts_filter(setweight(to_tsvector('find this needle and that needle in the haystack'), 'A', ARRAY['needl']), '{a}');
```
| ts\_filter |
| --- |
| 'needl':3A,6A |

Ultimately, using the combination of `setweight` and `ts_filter`, we will substitute `tsvector_to_table(search_vec)` for `tsvector_to_table(ts_filter(setweight(content_tsv, 'A', tsvector_to_array(search_vec)), '{a}'))` and...
```
EXPLAIN ANALYZE 
SELECT ts_exact_phrase_matches(indexed_content, content_tsv, 'Eighteen years!” am the passenger') 
FROM files;
```
| QUERY PLAN |
| --- |
| ProjectSet  \(cost=0.00..535.50 rows=100000 width=32\) \(actual time=3564.827..3564.827 rows=0 loops=1\) |
|   \-\>  Seq Scan on files  \(cost=0.00..10.00 rows=100 width=50\) \(actual time=0.010..0.221 rows=100 loops=1\) |
| Planning Time: 0.065 ms |
| Execution Time: 3564.848 ms |



Wow. We have cut the total time of our function from 13s per 100 rows down to ~3.5 seconds. We are almost there, but it is also worth remembering: the total time for the built-in `ts_headline` function was ~5500ms. Our function is already **40% faster that the OOTB ts_headline function**. 

### 4. JIT v. Precomputed word arrays
The call to `get_word_range(content, first, last)` is accounting for roughly 20% of initial total time (~3-4s or ~30-40ms per row) and nearly all of our remaining computational cost. The vast majority of that computational cost is going into exploding a space-delimited string into an array of words.

What if we pre-computed our space-delimited vector from the text passed through our `prepare_text_for_tsvector` function, and pass that into `ts_exact_phrase_matches`?
```
EXPLAIN ANALYZE
SELECT ts_exact_phrase_matches(
		content_arr, 
		content_tsv, 
		'Eighteen years!” or the passenger') 
FROM files;
```
| QUERY PLAN |
| --- |
| ProjectSet  \(cost=0.00..535.50 rows=100000 width=32\) \(actual time=281.827..281.827 rows=0 loops=1\) |
|   \-\>  Seq Scan on files  \(cost=0.00..10.00 rows=100 width=50\) \(actual time=0.010..0.221 rows=100 loops=1\) |
| Planning Time: 0.065 ms |
| Execution Time: 281.848 ms |

Look at that! If we pre-realize the space-delimited array of our prepared content, we are able to process 100 rows, each of 16,300+ words of text, in less that 300ms or 2.8ms per row. The baseline time for the built-in `ts_headline` function was 5592ms, and thus, we have managed to highlight the semantically correct phrase in roughly 5% of the time (281ms). **This technique represents a 20 x improvement over built-in functionality**

## Performant Exact Phrase Matches Function

Let's look at our new function:
```
CREATE OR REPLACE FUNCTION ts_exact_phrase_matches(haystack_arr TEXT[], content_tsv TSVECTOR, user_search TEXT)
RETURNS TABLE(positions TEXT) AS
$$
DECLARE minmaxarr SMALLINT[];
DECLARE search_vec TSVECTOR;
    
BEGIN
	user_search := prepare_text_for_tsvector(user_search);
	search_vec  := TO_TSVECTOR(user_search);
	minmaxarr   := (SELECT ARRAY[MIN(pos), MAX(pos)] FROM tsvector_to_table(search_vec));
	
    RETURN QUERY 
          (SELECT replace(array_to_string(haystack_arr[first:last], ' '), chr(1) || ' ', '')
           FROM (SELECT MIN(pos) AS first, MAX(pos) AS last 
                 FROM (SELECT haystack.pos, 
                              haystack.pos - (query_vec.pos - minmaxarr[1]) as range_start
                       FROM (SELECT lex, pos FROM tsvector_to_table(ts_filter(setweight(content_tsv, 
	           		                                                                     'A', 
	           		                                                                     tsvector_to_array(search_vec)), 
	           		                                                           '{a}'))) AS haystack 
			           INNER JOIN tsvector_to_table(search_vec) AS query_vec 
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

#### Some notes:
- As we now do not have to render a word array, the call of `array_to_string(haystack_arr[first:last], ' ')` will aggregate a range of words inserting spaces in between.
  
- Given the content added through our `prepare_text_for_tsvector` function, we know that the character sequence has (very probably) been inserted to break apart words deliniated with special characters. As such, the invocation of replace, `replace(array_to_string(haystack_arr[first:last], ' '), chr(1) || ' ', '')` removes both the unicode character 0001 and the space, howfully returning the string to something akin to how we found it.
  
- The addition of the anded term in the WHERE condition, `array_to_string(haystack_arr[first:last], ' ') @@ phraseto_tsquery(user_search)` ensures that the exact match we return correctly obeys the PGSQL text search semantics. (Otherwise, we could highlight a term where only the first and last words are 'correct')


