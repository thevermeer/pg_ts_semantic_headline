# ts_headline returns passages that do NOT contain the searched phrase
For multi-word search terms, ts_headline is treating a multi-word phrase like subject of interest as three, indepentent terms: subject, of and interest. As a result, the ts_headline function will return passages from the source that only contain partial matches. If the user is presented with a passage that only demonstrates a partial match, we will have broken user expectations:

```
SELECT ts_headline('liberally apply shampoo to scalp', to_tsquery('liberally<->applied<->semantics'));
```
| ts\_headline |
| --- |
| \<b\>liberally\</b\> \<b\>apply\</b\> shampoo to scalp |

The partial highlighting may seem trivial at this first stage, however, when applied to large documents, and the MaxFragments option for ts_headline is greater than zero (See [pgsql Full-text search - 12.3.4 Highlighting Results]) we can easily end up with somne partial matches, and we do not want those displayed.

## Large documents in the real world
The examples above do demonstrate that ts_headline can return content that only partially matches the query. Displaying partial matches can be problematic for the user as it suggests that In order to weed out headlines that only contain partial matches. The scale to the problem, with the highlighter applied to a single sentence. In real world applications, a single document can contain multiple gigabytes of text. Due to the limitations of TSVector containing a maximum of 2^14 - 1 = 16383 words, (see [[pgsql Full-text search - 12.11. Limitations](https://www.postgresql.org/docs/current/textsearch-limitations.html#TEXTSEARCH-LIMITATIONS)]) indexing a large document MAY require storing n ts_vectors of document fragments for each document. At that scale, ts_headline will produce partial matches.

## Approach
In order to guarantee that we are only displaying headlines that abide the user-inputted search string, we will:
1. Perform the OOTB `ts_headline` function on the content, separating passages with a `<passage>` tag.
2. We will split the headline into a table/recordset of passages.
3. We will select over the collection of passages `WHERE TO_TSVECTOR(passage) @@ query`.
4. We will finally re-aggregate our passages into a single delimited string.

## Decomposing ts_headline into passages and re-testing with @@
Per our approach above, we want to perform a ts_headline call, decompose the returned string into passages, and then re-aggregate only the passages that match the test `WHERE TO_TSVECTOR(passages.text) @@ query`. This is done like so:
```
SELECT string_agg(passages.text, '<passage>') 
FROM (SELECT regexp_split_to_table(ts_headline('quick fox, brown fox box and fox', 'fox<1>box'::TSQUERY, ''), 
                                   E'<passage>') AS text) AS passages
			WHERE TO_TSVECTOR(passages.text) @@ 'fox<1>box'::TSQUERY;
```
| string\_agg |
| --- |
| quick \<b\>fox\</b\>, brown \<b\>fox\</b\> \<b\>box\</b\> and \<b\>fox\</b\> |

Above, the `WHERE TO_TSVECTOR(passages.text) @@ 'fox<1>box'::TSQUERY` is taking the passage returned from `ts_headline`, casting that text into a TSVector and then testing with `@@` against the TSQuery. 

### Function to return value from option string (Comma-Delimited list of key=value)
As a sidenote, in the approach above, we are using the `<passage>` tag as the `FragmentDelimiter` (See [[pgsql Full-text search - 12.3.4. Highlighting Results](https://www.postgresql.org/docs/current/textsearch-controls.html#TEXTSEARCH-HEADLINE)]). This is opinionated and should be overloaded if the user speficies a different `FragmentDelimiter`. As such, we should take some care in preserving the user-specified value, and to do that we need a simple funciton to return a value from a k/v pair in a comma-delimited list:
```
CREATE OR REPLACE FUNCTION cdl_kv_to_value(input_str TEXT, key TEXT)
RETURNS TEXT AS 
$$ BEGIN
    RETURN (SELECT COALESCE(grp[2], grp[3])
			FROM regexp_matches(input_str,
			                    '(\w+)=(?:"([^"]+)"|((?:(?![\s,]+\w+=).)+))',
			                    'g') as matches(grp)
			WHERE grp[1] = key);
END; $$ 
LANGUAGE plpgsql;	
```
This function assumes a string of 0 or more options entries in the form `key1=value1, key2=value2`.

### ts_headline function that only returns matching passages
Combining these two approaches, we can derive a function that returns only passages which conform to the TS Query.
```
CREATE OR REPLACE FUNCTION conforming_headline (content TEXT, query TSQUERY, options TEXT) RETURNS TEXT
AS $$
DECLARE base_params TEXT;
DECLARE delimiter TEXT;
BEGIN
    SELECT options || ',FragmentDelimiter=<passage>' INTO base_params;
    SELECT COALESCE(cdl_kv_to_value(options, 'FragmentDelimiter'), '<passage>') INTO delimiter;

    RETURN (SELECT string_agg(passages.text, delimiter) 
            FROM (SELECT regexp_split_to_table(ts_headline(content, query, base_params), E'<passage>') AS text) AS passages
			WHERE TO_TSVECTOR(passages.text) @@ query);
END;
$$
IMMUTABLE
LANGUAGE plpgsql;
```
## Real-World problems with this approach
This pattern and approach suffers from 3 main issues:
1) While this guarantees that ts_headline returns a conforming passage, it does not prevent ts_headline from highlighting partial terms which do NOT match the TS Query.  See
- [[BUG #15172: Postgresql ts_headline with <-> operator does not highlight text properly](https://www.postgresql.org/message-id/flat/152461454026.19805.6310947081647212894%40wrigleys.postgresql.org)]
- [[SO: Is `ts_headline` intended to highlight non-matching parts of the query (which it does)?](https://stackoverflow.com/questions/69512416/is-ts-headline-intended-to-highlight-non-matching-parts-of-the-query-which-it)]
- and many more...

2) This approach to generating headlines is not capable of highlighting phrases, rather only single words within a phrase.

3) `ts_headline` is very slow. Taking the results of a `ts_headline` call and then casting it to a TSVector is even slower.  
