# Retrieveing Exact Matches from PostgreSQL Text Search
When a full-text search engine ingests and indexes text, typically the content is processed, word-by-word, against a language-specific dictionary, reduced to its lexeme (word root), and stored alphabetically in an inverted index with their position in the text; common connctive words (the, and, am, do as examples) are removed and not indexed.

In pre-realizing the TSVector in pgsql, when we perform search by similarly reducing the search term to its lexemes (as with the haystack, so too with the needle), we are losing the information of the exact terms within the source text that are matching the user query. 

#### Example: TSVector lexeme reduction loses the exact content matched
```
SELECT to_tsvector('exacting exactly the exact exaction that exacts the exacted');

     to_tsvector     
---------------------
 'exact':1,2,4,5,7,9
(1 row)
```

Can we use ts_headline to retrieve the exact strings that are being matched in the lexeme-reduced index lookup?

That is:
```
SELECT SOME_FUNCTION('exacting exactly the exact exaction that exacts the exacted', ts_tsquery('exact'));

::>
 SOME_FUNCTION
---------------
exacting, exactly, exact, exaction, exacts, exacted
```

## Setup 

If you follow the [[Project Setup](https://github.com/thevermeer/postgresql_semantic_tsheadline/blob/main/development_setup.md)], you will have a data table with 10,000 rows, each containing a source text as well as a pre-realized TSVector representation of the content.

Given that the TSVector is computed and available is it possible to use the TSVector to determine the location (and thus text) of a phrase matching? 

Recall that that a TS Vector is an alphaebtized list of lexemes and their positions:
```
SELECT to_tsvector('This is a very generic statment about the nature of statements and the proposition of various stated propositions that may arise.');

::>
 to_tsvector
---------------------
'aris':21 'generic':5 'may':20 'natur':9 'proposit':14,18 'state':17 'statement':11 'statment':6 'various':16
```
If we can determine which parts of the content_tsv match the pattern of the query phrase, we can return the positions, in the content, of the search matches; then, with the integer word positions, we can cut apart the string and highlight the term.

## Approach
The first task is to be able to identify the exact match phrase that a TSVECTOR @@ TSQUERY search condition produces, that is, we will ignore boolean connectives and TSQuery proximity for now, and look at identifying individual phrases.

As such, we will assume at first that we are trying to highlight a single phrase. To do this, we will accept the phrase as a string and then process the phrase as a TSVECTOR (careful - this is not a TSQuery).

Next, we will decomposed the TSVectors of the needle and the haystack, and with some clever SQL and arithmetic, will return from the TSVector the character ranges of matching phrases in the haystack.

Finally, we will split the haystack (source content) apart to determine the exact strings that are being matched in a text search query.

### Unnesting a TSVector into a table of occurences
Given any TS Vector in postgreSQL, that TSVector can be decomposed into a table of rows with lexemes (TEXT), positions (SMALLINT[]) and weights:
```
SELECT * FROM UNNEST(TO_TSVECTOR('the dogged fox jumps over the foxed dog'));

::>
lexeme | positions | weights 
-------------------------------
dog	{2,8}	{D,D}
fox	{3,7}	{D,D}
jump	{4}	{D}
```

In turn, the positions array can further be decomposed into a row for every position:
```
SELECT lexeme, UNNEST(positions) AS position FROM UNNEST(TO_TSVECTOR('the dogged fox jumps over the foxed dog'));

::>
 lexeme | position
-------------------
dog	  2
dog	  8
fox	  3
fox	  7
jump	4
```

For our purposes, we can make this code reusable and create a function that accepts a TSVector and returns a table of lexemes and positions:
```
CREATE OR REPLACE FUNCTION TSVECTOR_TO_TABLE(input_vector TSVECTOR)
RETURNS TABLE(lex TEXT, pos SMALLINT) AS
$$
BEGIN
	RETURN QUERY (SELECT lexeme, UNNEST(positions) AS position 
		    FROM UNNEST(input_vector)
		    ORDER BY position);
END;
$$
IMMUTABLE
LANGUAGE plpgsql;
```

### Joining the TSVectors of the Needle and Haystack
In order to compute where the pattern of the query/needle occurs in the haystack, we will take the tables of lexemes and positions for both the needle and the haystack, and join them on lexeme. The resulting recordset contains a row for each of the occurences of a lexeme in the haystack, for every occurence of a lexeme in the needle/query.

To begin, let's join the positions' tables for the needle/query and haystack:
```
SELECT query_vec.lex, query_vec.pos AS pos_in_needle, haystack.pos as pos_in_haystack
FROM TSVECTOR_TO_TABLE(to_tsvector('needle to find')) AS query_vec
INNER JOIN TSVECTOR_TO_TABLE(to_tsvector('finding? difficult is the needling to find in the needles or the haystack with needles I find')) AS haystack
ON haystack.lex = query_vec.lex;
```
Which produces:
```
lex | pos_in_needle | pos_in_haystack

find	3	1
find	3	7
find	3	17
needl	1	10
needl	1	5
needl	1	15
```

Here, in may not be perfectly obvious, however the following 2 rows comprise the sought query pattern of `'needle to find'`. In order to we are going to calculate the relative position of a haystack lexeme in the needle pattern; to do that, we need the MIN(pos) in the needle's TSVector. For the sake of readability, we are going to pull the query's TSVECTOR_TO_TABLE as a CTE in a `WITH` statement:
```
WITH query_vec AS (SELECT * FROM TSVECTOR_TO_TABLE(to_tsvector('needle to find')))
SELECT query_vec.lex, 
       haystack.pos AS pos_in_haystack, 
       haystack.pos - (query_vec.pos - (SELECT MIN(pos) FROM query_vec)) AS range_start
FROM query_vec
INNER JOIN TSVECTOR_TO_TABLE(to_tsvector('finding? difficult is the needling to find in the needles or the haystack with needles I find')) AS haystack 
ON haystack.lex = query_vec.lex;
```
Producing:
```
  lex | pos_in_haystack | range_start 
---------------------------------------
find	  1	    -1
find	  7      5
find	 17 	15
needl	 10 	10
needl	  5	     5
needl	 15	    15
```

Here, there are 2 groups of matches:
1) First Match:
- `needl	  5	   5`: needl is the 5th word in the haystack and is part of a range beginning at position 5
- `find	    7	   5`: find is the 7th word in the haystack and is part of a range beginning at position 5

2) Second Match:
- `needl	15	 15`: needl is the 15th word in the haystack and is part of a range beginning at position 15
- `find	  17   15`: find is the 17th word in the haystack and is part of a range beginning at position 15

We can use the `range_start` value to group lexemes and thusly produce the start and end positions of matching word ranges.

We wrap the above query, grouping and then aggregating the results:
```
WITH query_vec AS (SELECT * FROM TSVECTOR_TO_TABLE(to_tsvector('needle to find')))
SELECT MIN(pos) AS first, MAX(pos) AS last 
FROM (SELECT query_vec.lex, 
             haystack.pos, 
             haystack.pos - (query_vec.pos - (SELECT MIN(pos) FROM query_vec)) AS range_start
	  FROM query_vec
      INNER JOIN TSVECTOR_TO_TABLE(to_tsvector('finding? difficult is the needling to find in the needles or the haystack with needles I find')) AS haystack 
      ON haystack.lex = query_vec.lex)
GROUP BY range_start;
```

Producing:
```
 first  |  last
----------------
 1	    1
 5	    7
10	   10
15	   17
```

We are clearly not interested in the smaller ranges, and want to collect the original string, between words 5 to 7, and 15 to 17. We have to further next our table here in order to put conditions on aggregated values. Nonetheless, we nest our query and select only the ranges that match the length of the query:
```
WITH query_vec AS (SELECT * FROM TSVECTOR_TO_TABLE(to_tsvector('needle to find')))
SELECT first, last
FROM(SELECT MIN(pos) AS first, MAX(pos) AS last
	   FROM (SELECT query_vec.lex, 
	                haystack.pos, 
	                haystack.pos - (query_vec.pos - (SELECT MIN(pos) FROM query_vec)) AS range_start
		       FROM query_vec
 	         INNER JOIN TSVECTOR_TO_TABLE(to_tsvector('finding? difficult is the needling to find in the needles or the haystack with needles I find')) AS haystack 
	         ON haystack.lex = query_vec.lex)
	   GROUP BY range_start)
WHERE last - first = (SELECT MAX(pos) - MIN(pos) FROM query_vec);
```
Producing:
```
 first  |  last
----------------
 5	    7
15	   17
```

Alright! Now we are getting somewhere, because, if you look at the haystack sentence, we will see that the ranges 5-7 and 15-17 are indeed matching:
```
finding? difficult is the needling to find in the needles or the haystack with needles I find
     1        2     3   4     5     6   7   8  9     10   11  12    13     14    15    16 17
                          ----------------                                     --------------
```
We are almost ready to produce a function that can return the exact matches of a postgreSQL text search. First, we need a function that can crop a string between the ith and jth word. Let's try the following, although I will look into whether reg_exp functions are more performant. Until then:

### Function for cropping as string between the ith and jth words
Here is a quick function that can likely be improved to crop a string in a given word range. 
```
CREATE OR REPLACE FUNCTION get_word_range(input_text text, start_pos INTEGER, end_pos INTEGER)
RETURNS text AS
$$
DECLARE
    words_array text[];
BEGIN
    -- Split the input text into an array of words
    words_array := string_to_array(input_text, ' ');
    -- Ensure n is within the valid range
    end_pos := GREATEST(1, LEAST(end_pos, array_length(words_array, 1)));
    -- Return the first n words as a concatenated string
    RETURN array_to_string(words_array[start_pos:end_pos], ' ');
END;
$$
IMMUTABLE
LANGUAGE plpgsql;
```

### Putting it all together
Now, let's combine the `get_word_range` function with our range aggregation and see if we can return the exact matches from a full-text search
```
WITH query_vec AS (SELECT * FROM TSVECTOR_TO_TABLE(to_tsvector('needle to find')))
SELECT get_word_range('finding? difficult is the needling to find in the needles or the haystack with needles I find', first, last) AS exact_matches
FROM(SELECT MIN(pos) AS first, MAX(pos) AS last
	 FROM (SELECT query_vec.lex, 
	              haystack.pos, 
	              haystack.pos - (query_vec.pos - (SELECT MIN(pos) FROM query_vec)) AS range_start
		   FROM query_vec
	       INNER JOIN TSVECTOR_TO_TABLE(to_tsvector('finding? difficult is the needling to find in the needles or the haystack with needles I find')) AS haystack 
	       ON haystack.lex = query_vec.lex)
	 GROUP BY range_start)
WHERE last - first = (SELECT MAX(pos) - MIN(pos) FROM query_vec);
```
produces:
```
 exact_matches
---------------
needling to find
needles I find
```

Great! we have found a general pattern for matching PHRASES is a TS Search. (See Limitations below) 

## ts_exact_phrase_matches : A function to produce exact match results from a text search query
Let's take the above technique and put it into a UDF, giving us a reusable code unit and allowing us to streamline our logic:
```
CREATE OR REPLACE FUNCTION ts_exact_phrase_matches(content TEXT, content_tsv TSVECTOR, user_search TEXT)
RETURNS TABLE(lex TEXT) AS
$$
DECLARE minmaxarr SMALLINT[];
DECLARE search_vec TSVECTOR;
    
BEGIN
	search_vec := TO_TSVECTOR(user_search);
	SELECT ARRAY[MIN(pos), MAX(pos)] FROM TSVECTOR_TO_TABLE(search_vec) INTO minmaxarr;

	
  RETURN QUERY 
     (SELECT match
	    FROM (SELECT get_word_range(content, first, last) AS match 
	   	      FROM (SELECT MIN(pos) AS first, MAX(pos) AS last 
		  	      	  FROM (SELECT haystack.pos, haystack.pos - (query_vec.pos - minmaxarr[1]) as range_start
	           		        FROM TSVECTOR_TO_TABLE(search_vec) AS query_vec
			                  INNER JOIN TSVECTOR_TO_TABLE(content_tsv) AS haystack ON haystack.lex = query_vec.lex)
	      		      GROUP BY range_start)
	          WHERE (minmaxarr[2] - minmaxarr[1]) = (last - first)
	          ORDER BY first ASC));
END;
$$
IMMUTABLE
LANGUAGE plpgsql;
```
The function accepts the content to be highlighted, a TSVector representation of the content and a phrase to be matched, and returns a table of the exact strings in the content that match the phrase. If a TSVector has not been pre-realized, the text can be cast on the fly in the function invocation, but this is not recommended as it will be a massive performance burden.

### Examples
As we begin querying for content, it seems that we have been successful in creating a function that returns the exact match for fuzzy queries:
#### Example 1
```
SELECT ts_exact_phrase_matches(content, content_tsv, 'it was the age of wisdom') FROM files LIMIT 1;
```
produces:
```
age of wisdom,
```
This is correct; the "it was the" portion of the search query are all stop words and therefore excluded from the range. Great.

The correct matching continues further into the text, and we will only begin to encounter trouble after a few paragraphs of text

#### Example 2
```
SELECT ts_exact_phrase_matches(content, content_tsv, 'direct the other way') FROM files LIMIT 1;
```
nearly correctly produces: (Notice the extra 'in' at the end)
```
direct the other way—in
```
#### Explanation
As we encounted terms within our text that contain hyphens, as an example, we find that the default english stem parser is creating multiple entries for the parts of the term. Namely, for a hypenated term, we index the first term, the last term and the conjoined 2-word term. The result is that when indexing a single hypenated word, we index 3 terms, like so:
```
SELECT to_tsvector('seventy-five');
::>
 to_tsvector 
-------------
 'five':3 'seventi':2 'seventy\-f':1 
```
as well as:
```
SELECT to_tsvector('power-law');
::>
 to_tsvector
-------------
'law':3 'power':2 'power-law':1
```

#### Example 3
As we start searching terms further down in a given text, here, content from chapter 3 of A Tale of Two Cities, and the phrase `"two passengers would admonish him to pull up the window"` actually returns content from 4 paragraphs 'lower' in the document.
```
SELECT ts_exact_phrase_matches(content, content_tsv, 'two passengers would admonish him to pull up the window') FROM files LIMIT 1;
::>
 ts_exact_phrase_matches
-------------------------
wet, the sky was clear, and the sun rose bright,
```
#### Conclusions
Clearly, we need to do more than tokenize our source string, because TSVector is doing some special handling of special characters in the source text, in order to better use the lexeme-reduced, english-stem TSVector to identify the positions of fuzzy searches within the source text. Let's try that now:

## Preparing source text for better positional indexing
In order to get a more favourable rendering of the TSVector to correlate positions to the actual word position in the text, we are going to apply a few rules to the source text. Those rules are:
- Any word that contains a special character is split and the second term will have a space inserted prior to the word.
- Any sequence of exclusively non-word characters will be removed and replaced with a space.
- All instances of multiple whitespace tokens (multiple line returns, double spaces) are reduced to a single space

Pulling that all together, we produce the following function:
```
CREATE OR REPLACE FUNCTION prepare_text_for_tsvector(result_string text)
RETURNS text AS
$$
BEGIN
	result_string := regexp_replace(result_string, '(\w)([^[:alnum:]|\s]+)(\w)', E'\\1\\2\u0001 \\3', 'g');
	result_string := regexp_replace(result_string, '(\w)([^[:alnum:]|\s]+)(\w)', E'\\1\\2\u0001 \\3', 'g');
	result_string := regexp_replace(result_string, '(\s)([^[:alnum:]|\s]+)(\s)', E' ', 'g');
	result_string := regexp_replace(result_string, E'[\\s]+', ' ', 'g');		    

	RETURN result_string;
END;
$$
STABLE
LANGUAGE plpgsql;
```
This articulation of our string cleaning pattern will produce a string that breaks apart hypen-delimited and special-character delimited terms into single words and as a result, when we convert the string to TSVector, the word positions of lexemes in the vector will correspond to the position of the same term in a space-tokenized string.

```
SELECT prepare_text_for_tsvector('on seventy power-rules,  --- she!, !!@#!@$% entertain''s the reason-to-be! with F!in-ess');
::>
 prepare_text_for_tsvector
---------------------------
on seventy power- rules, she!, entertain' s the reason- to- be! with F! in- ess
```
Let's compare the before and after, resulting TSVector:
```
Before: SELECT to_tsvector('on seventy power-rules,  --- she!, !!@#!@$% entertain''s the reason-to-be! with F!in-ess');
----------
'entertain':7 'ess':18 'f':15 'in-ess':16 'power':4 'power-rul':3 'reason':11 'reason-to-b':10 'rule':5 'seventi':2
```
```
After: SELECT to_tsvector(prepare_text_for_tsvector('on seventy power-rules,  --- she!, !!@#!@$% entertain''s the reason-to-be! with F!in-ess'));
----------
'entertain':6 'ess':15 'f':13 'power':3 'reason':9 'rule':4 'seventi':2
```
This may prove problematic in some contexts, however we can see that the resultant vector is freed from the expansion of character-delimited terms, and this will allow us to correctly position fuzzy matches against the exact text, reduced and returned from `prepare_text_for_tsvector`.

### Function to repair treated source text
The `prepare_text_for_tsvector` function above is preparing text by breaking apart special character-delimited words by splitting on the special chararter and inserting a bell character followed by a space into the string. The bell character is an invisible charater that should be a relatively safe means of identifying treated regions of the document. The insertion of the space is to prevent various stemming parser from dividing the character-delimited word intto more than 2 terms, thereby breaking the actual position indexing of words in the TSVector. In our methodology, we index by inserting this character sequence into both needle and haystack. 

Here, we provide a simple helper funciton to remove the bell character + space sequence, for the purposes of presentation:
```
CREATE OR REPLACE FUNCTION prepare_text_for_presentation (input_text TEXT)
RETURNS TEXT AS
$$
BEGIN
	RETURN (SELECT regexp_replace(input_text, E'\u0001 ', '', 'g'));
END;
$$
STABLE
LANGUAGE plpgsql;
```
and thus:
```
SELECT 'character-split' AS given,
       TO_TSVECTOR('character-split') AS untreated_tsv,
       prepare_text_for_tsvector('character-split'),
       TO_TSVECTOR(prepare_text_for_tsvector('character-split')),
	   -- Undo the bell-char + space indexing features:
       prepare_text_for_presentation(prepare_text_for_tsvector('character-split'));
```
gives us:
| given |untreated\_tsv |prepare\_text\_for\_tsvector |to\_tsvector |prepare\_text\_for\_presentation |
| --- | --- | --- | --- | --- |
| character\-split |'charact':2 'character\-split':1 'split':3 |character\- split |'charact':1 'split':2 |character\-split |

allowing us to return text to the user without internal indexing features.


## Revisiting Exact Matches with text prepared for indexing
With that, let's apply `prepare_text_for_tsvector` to BOTH the needle and haystack and see how effectively our scrubbing on the string has been:

#### Example 2 revisited:
```
SELECT ts_exact_phrase_matches(
		prepare_text_for_tsvector(content), 
		TO_TSVECTOR(prepare_text_for_tsvector(content)), 
		'direct the other way') 
FROM files LIMIT 1;
::>
 ts_exact_phrase_matches
-------------------------
 direct the other way— 
```
That is what we want!

#### Example 3 revisited:
```
SELECT ts_exact_phrase_matches(
		prepare_text_for_tsvector(content), 
		TO_TSVECTOR(prepare_text_for_tsvector(content)), 
		'two passengers would admonish him to pull up the window') 
FROM files LIMIT 1;
::>
 ts_exact_phrase_matches
-------------------------
 two passengers would admonish him to pull up the window,
```
Great!. In fact, if we search the last phrase in chapter 3 of `A Tale pf Two Cities`, which happens to be `Gracious Creator a day! To be buried alive for eighteen years` we get precisely that back:
```
SELECT ts_exact_phrase_matches(
		prepare_text_for_tsvector(content), 
		TO_TSVECTOR(prepare_text_for_tsvector(content)), 
		'Gracious Creator a day! further not the one for eighteen years!”') 
FROM files LIMIT 1;
::>
 ts_exact_phrase_matches
-------------------------
 “Gracious Creator of day! To be buried alive for eighteen years!”
```

## Limitations
- Does not work with TS logical operators
- Does not work with TS Queries; the query phrase must come in as user-keyed text.
- This process is slow; 3 times slower than `ts_headline`.

This whole work presents a good start, but we are going to have to improve the efficiency of this process in order to have a viable, performant solution.
