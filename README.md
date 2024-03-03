# PostgreSQL Full-text Search and Semantic ts_headline functionality
## Abstract
We explore a series of methods for improving the way that postgreSQL's `ts_headline` function resepects the semantics of phrase matching in TSQueries. 

In the process, we uncover a method for replacing ts_headline that, when implemented using pre-computed columns, performs  5-10 times faster than the built-in function.

The end result is a PostgreSQL extension that can either directly replace `ts_headline`, providing full phrase highlighting and improved TSQuery semantics, or, when pairing with a pre-realized lookup table, can return highlighted content up to 10x faster than `ts_headline`.

## Prerequisites
- PostgreSQL@14 or greater.
- The `UNACCENT` extension that, by default is bundled with PostgreSQL@14. To install it, run:
```
CREATE EXTENSION unaccent;
```

## Installation
This project is in development February/April of 2024. Before we have a stable release version, if you wish to run the extension:

1) Clone this repository.

2) `cd` into the project directory `(/postgresql_semantic_tsheadline) 

3) Run `make && make install` :
- `make` - will compile the source files in the `/sql` folder into a single .sql file as the extention.
- `make install` - will copy the _compiled_ (concatenated :)) .sql file into your PGSQL extensions directory. eg. `/usr/local/share/postgresql@14/extension/`

4) In your target Postgres database, run `CREATE EXTENSION TS_SEMANTIC_HEADLINE;`

## How to use TS_SEMANTIC_HEADLINE
How to use this extension will largely depend on your desired outcome, as this extension provides both:
- a means of correcting the built-in `ts_headline` function, to highlight entire, multi-word phrases, and NOT highlighting partial matches, 
- a pattern of pre-realizing computationally expensive columns to a data table, for faster searching AND text recall, that retrieves highlighted search results 5x to 10x faster than the built-in `ts_headline`. 

That is, do you want to just improve the phrase highlighting of `ts_headline`, or do you ALSO want to dramatically spped up the recall of those highlighted search results?

### How to highlight multi-word phrases and NOT highlight partial matches
In order to simply replace the existing `ts_headline` function with a highlighter that matches entire, multi-word phrases and does NOT highlight partial terms, we can simply substitute `TS_SEMANTIC_HEADLINE` in for `ts_headline` - `TS_SEMANTIC_HEADLINE` comes in a overloaded to have the same method signature as `ts_headline`:
```

```


## Purpose
The purpose of this repository is to document some issues encountered with using PostgreSQL full-text search to display highlighted search results to the user, and propose a solution that is expressed firstly as PGSQL user-defined functions (UDFs). The goal of creating this functionality is to demonstrate the value to the PostgreSQL community of correcting the ts_headline function to better reflect the actual semantics of the full-text search operators used for index lookup. From that, the goal is to introduce better ts_headline semantics into the postgresql source code, but that is a different project althoether. To get there, let's first outline the current issues and create a few UDFs to address the issue and illuminate the value of the improvements.

## Preamble
I am a full-stack developer, building a web application that has stored a large volume of texts, as rows in a postgreSQL data table. The UI we are building performs full-text search by accepting a user-inputted string, searching, and displaying results. When we display results, we want to display passages from the text with "highlights", emphasizing the portions of the passage that match our search.

The user has at their disposal the ability to search a single word or a multi-word phrase; they can join phrases together with AND/OR operators, group logical expressions with brackets and negate the presence of certain words with NOT. [[pgsql Full-text search - 12.1.2 matching](https://www.postgresql.org/docs/current/textsearch-intro.html#TEXTSEARCH-MATCHING)]

In the database, we have created a table to store the text contents of a large volume of files. For each tuple in the "files" table, we have a file ID, a text field, and a TS Vector column that is a pre-realized, because adhoc realization of TSVector of a large table of text is very memory-(and time-)intensive, and likewise such that we can create a GIN index of the TSVector column for fast lookup. This is a recommended pattern for large-scale full-text search in PostgreSQL. [[pgsql Full-text Search - 12.2.2 Creating Indexes](https://www.postgresql.org/docs/current/textsearch-tables.html#TEXTSEARCH-TABLES-INDEX)]

## Problems with ts_headline
As a developer, the built-in ts_headline offers a number of quirks and gotchas, and at the highest level, it is fair to say that the internals to ts_headline do not abide by the intended meaning of full-text operators. Specifically when the user has inputted a multi-word phrase, we find that ts_headline will return only partial matches, and only highlight single words from the phrase.

### 1. ts_headline returns passages that do NOT contain the searched phrase
Approach: [[Guarantee that a TS Headline conforms to a ts query phrase](https://github.com/thevermeer/postgresql_semantic_tsheadline/blob/main/problems/semantic_headlines.md)]
### 2. How can I convert a fuzzy full-text search into the exact phrase matches in a document
Approach: [[Produce the exact content that pgsql matches on a fuzzy search](https://github.com/thevermeer/postgresql_semantic_tsheadline/blob/main/problems/exact_matches.md)]
### 3. ts_headline is very slow. Our solution to Problem 2 is slower.
Approach: [[An approach to content hihglighting that is up to 10 times faster than built-in ts_headline](https://github.com/thevermeer/postgresql_semantic_tsheadline/blob/main/problems/efficient_content_retrieval.md)]
### 4. ts_headline only highlights single words for multi-word phrase queries
Approach: [[Headline function that highlights phrases without partial matches](https://github.com/thevermeer/postgresql_semantic_tsheadline/blob/main/problems/multi_word_phrase_highlighting.md)]

## Solution
The overall solution to all 4 of the above problems, derived in the various _Approach_ sections above comes together, both from the implementation of a table with 2 pre-computed columns for more efficiecnt search AND content retrieval. Therefore, our solution consists of:

### Core Functions 
- `TSP_QUERY_MATCHES (haystack_arr TEXT[], content_tsv TSVECTOR, search_query TSPQUERY, match_limit INTEGER DEFAULT 5)` function, which converts a fuzzy, stemmed search into the exact phrase matches from the actual text, as well as the word positions of the match within the source text.
- `TS_SEMANTIC_HEADLINE (content TEXT, search_query TSQUERY, options TEXT DEFAULT ' ')` is a 1:1 replacement of ther built-in `ts_headline` function that improves the highlighting of TSQuery search to fully respect the internal semantics of full-text boolean operators, including phrase highlighting, and excluding partial matches.
- `TS_FAST_HEADLINE (haystack_arr TEXT[], content_tsv TSVECTOR, search_query TSQUERY, options TEXT DEFAULT ' ')` function, which, when using prerealized TSVector and TEXT[] columns, delivers highlighting 5-10 times FASTER than the built-in `ts_headline` function.

### Fast-Lookup Table (Optional)
- An optional table schema for faster indexing, implementing both a TSVector column for fast lookup, and a TEXT[] array column for fast content retrieval. Without the table, the work herein is valuable in order to improve the phrase semantics of `ts_headline`; the pre-realization of the TEXT[] array is a necessary feature of the 5x-10x performance gains we have made in this work. For maximal performance, recommend using both a TSVector column and a TEXT[] array column in your lookup table. The TEXT[] array is used for fast lookup

### Text Treatment for Positional Indexing, etc
- `TSP_INDEXABLE_TEXT` treats a string for better positional indexing in TSVectors, by inserting \u0001\u0032 (bell character + SPACE) into words that are delineated by special characters like hyphens. 
- `TSP_PRESENT_TEXT` undoes the special character delineation performs in `TSP_INDEXABLE_TEXT` and returns the text to the pre-indexed state.
- `REPLACE_MULTIPLE_STRINGS` accepts a source string, an array of text to find, and an array to text to replace and accretes the replacements to form a final, transformed text.

### TSQuery and TSVector Type Coersion
- `tsquery_to_tsvector` - Given a TSQuery, the function returns a table of rows, with each row representing a TSQuery phrase and a TSVector representation of that phrase
- `TSQUERY_TO_TABLE` - Decomposes a TSQuery into a table of lexemes and their positions.
- `TSVECTOR_TO_TABLE` - Decomposes a TSVectos into a table of lexemes and their positions.
- `TO_TSPQUERY` - a 1:1 replacement for the built-in `TO_TSQUERY` which treats special character delimited strings in the same fashion as `TSP_INDEXABLE_TEXT`

## Outcomes
### Highlighting Entire Phrases in a TSQuery
The `TS_SEMANTIC_HEADLINE` function will highlight matching, multi-word phrase patterns in our source text. Compare that, side-by-side to the built-in `ts_headline`:
```
SELECT 
TS_SEMANTIC_HEADLINE('I can highlight search results as phrases, and not just single terms', TO_TSPQUERY('search<3>phrases')),
ts_headline('I cannot highlight search results as phrases, and only single terms', TO_TSPQUERY('search<3>phrases'));
```
| ts\_semantic\_headline |ts\_headline |
| --- | --- |
| I can highlight \<b\>search results as phrases,\</b\> and not just single terms |I cannot highlight \<b\>search\</b\> results as \<b\>phrases\</b\>, and only single terms |

### Partial Matches are NOT highlighted
The built-in `ts_headline` function will not respect the phrase operators within a TSQuery, and will highlight single words and partially matching terms. `TS_SEMANTIC_HEADLINE` enforces the notion that all highlighted matches' content will abide the semantics of the TSQuery:
```
SELECT 
TS_SEMANTIC_HEADLINE('phrase matches are highlighted, partial matches are not', TO_TSPQUERY('phrase<->match')),
ts_headline('phrase matches are highlighted, partial matches are as well', TO_TSPQUERY('phrase<->match'));
```
| ts\_semantic\_headline |ts\_headline |
| --- | --- |
| \<b\>phrase matches\</b\> are highlighted, partial matches are not |\<b\>phrase\</b\> \<b\>matches\</b\> are highlighted, partial \<b\>matches\</b\> are as well |

### Performs 5x-10x Faster than ts_headline (with pre-computed TSVector and TEXT[] columns)
We identified that full-text content recall is slow to do adhoc, because the retrieval requires manipulating and slicing large strings. At the same time, the built-in `ts_headline` function performs this reduction of text on every pass. If we have a table with a pre-computed TSVector of the source text AND a pre-computed array of words as they appear in the TSVector (delimited by spaces in the source), we can radically improve the performance to content recall in postgreSQL full-text search 

Though not required, if we pre-compute both the lookup index (TSVector) and the recall array (TEXT[]), we can perform semantically-correct content highlighting and recall roughly 10 times faster than using the built-in `ts_headline` function. 

Performing our search-and-recall across 100 documents, each with nearly the maximum number of words permitted in a TSVector,  we see:
```
EXPLAIN ANALYZE SELECT TS_FAST_HEADLINE(content_arr, content_tsv, TO_TSPQUERY('best<2>time')) FROM files;
```
| QUERY PLAN |
| --- |
| Seq Scan on files  \(cost=0.00..53.00 rows=100 width=32\) \(actual time=8.646..793.117 rows=100 loops=1\) |
| Planning Time: 0.117 ms |
| Execution Time: 793.227 ms |


Compared to the built-in `ts_headline` function performing the same task:
```
EXPLAIN ANALYZE SELECT ts_headline(content, TO_TSPQUERY('best<2>time')) FROM files;
```
| QUERY PLAN |
| --- |
| Seq Scan on files  \(cost=0.00..53.00 rows=100 width=32\) \(actual time=60.714..5724.190 rows=100 loops=1\) |
| Planning Time: 0.115 ms |
| Execution Time: 5724.348 ms |

### Improves ts_headline semantics without additional indices or pre-computed columns
If you do not want to pre-compute (or re-compute) a TSVector for search, or realizing a TEXT[] array of a long string seems too expensive, we also have a flavour of `TS_SEMANTIC_HEADLINE` that has the same method signature as the built-in `ts_headline` function, and uses function that under-the-hood to perform semantically-correct content highlighting of phrases, highlighting multi-word phrases and eliminating partial matches.

## Usage

### Parsing Documents
In order to perform fast content retrieval, we are going to treat our source text such that the positions within our language-stemmed TSVector will align with the word positions in our TEXT[] array of words. In order to do that, we will use the `TSP_INDEXABLE_TEXT` function, which accpets TEXT, cleans the string of special-character delimited words, and returns text:
```
TSP_INDEXABLE_TEXT(TEXT) RETURNS TEXT
```
As an example, `SELECT TSP_INDEXABLE_TEXT('hyphen-delimited and other.such~terms are treated');` will return:
| ts\_prepare\_text\_for\_tsvector |
| --- |
| hyphen\- delimited and other. such~ terms are treated |

Note that the ` ` (Bell Character + SPACE) have been inserted to break apart special character-delimited terms, in order to maintain 'word' positionality between the TSVector and content arrays. 

With that, in order to render a conformant TSVector, we will run:
```
SELECT TO_TSVECTOR(TSP_INDEXABLE_TEXT('our content to index'));
```
In order to generate our precomputed TEXT[] array, we will do much the same:
```
SELECT regexp_split_to_array(TSP_INDEXABLE_TEXT('our content to index'), '[\s]+');
```
Finally, if we are realizing the TSVector and TEXT[] array to a lookup table, we can do both, in one step, in our trigger function:
```
CREATE OR REPLACE FUNCTION trg_update_content_tsv_and_arr()
RETURNS TRIGGER AS $$
DECLARE clean_text TEXT = = TSP_INDEXABLE_TEXT(NEW.content);
BEGIN
    NEW.content_tsv       := to_tsvector(clean_text);   
    NEW.content_arr       := regexp_split_to_array(clean_textt, '[\s]+');
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
```

### Parsing Queries
The preparations that we make on the haystack TSVector also need to be made to the TSQuery.

Given the above section on _Parsing Documents_, for the purposes of our TSQuery, we are going to have to replace all special characters, as we do above, however, we will have to replace the characters with the TSQuery distance=1 operator, `<1>`. This will match the pattern of the Bell Character+SPACE inserted into the haystack, where the Bell Character is ignored when the TSVector is parsed and term is treated as 2 words. In terms of worldwide languages, this is probably a terrible idea and needs to be rethought out. For now, the goal is fast content retrieval, but do keep this in mind: Not all languages have space-delimited words, splitting on special; characters can either change or nullify meaning, amongst many other factors.

With all of that said, we will treat the needle with the same preparaions as we do the haystack, but are required to preserve the logical special characters inside of the query.

To render a TSQuery with compatible string preparations:
```
TO_TSPQUERY ([ config regconfig, ] query_string TEXT) RETURNS TSQUERY
```
Consider
```
SELECT 
TO_TSPQUERY( 'seek-ing<2>find.ing<1>the<1>needle<3>in-fix'),
to_tsquery('seek-ing<2>find.ing<1>the<1>needle<3>in-fix');
```
| ts\_prepare\_query |to\_tsquery |
| --- | --- |
| 'seek' \<\-\> 'ing' \<2\> 'find' \<\-\> 'ing' \<2\> 'needl' \<4\> 'fix' |'seek\-' \<\-\> 'seek' \<\-\> 'ing' \<2\> 'find.ing' \<2\> 'needl' \<3\> \( 'in\-fix' \<2\> 'fix' \) |


### Highlighting Search Results
To present search results it is ideal to show a part of each document and how it is related to the query. Usually, search engines show fragments of the document with marked search terms. PostgreSQL provides a function `ts_headline` that implements this functionality, however the built-in `ts_headline` function does not respect the semantics of phrase operators in TSQueries, and it is very computationally expensive.

In order to correct these two pressing issues, this extension offers two (2) separate approaches to replacing `ts_headline` with `TS_SEMANTIC_HEADLINE` OR `ts_fast_headline`:
```
TS_SEMANTIC_HEADLINE([ config regconfig, ] document text, query tsquery [, options text ]) returns text
```
ts_headline accepts a document along with a query, and returns an excerpt from the document in which terms from the query are highlighted. Specifically, the function will use the query to select relevant text fragments, and then highlight the phrases that match the subconditions of the query. Where `ts_headline` will highlight terms even if those word positions do not match the query's restrictions, `TS_SEMANTIC_HEADLINE` will highlight the multi-word phrase patterns, in the form that they are matching in search. The configuration to be used to parse the document can be specified by config; if config is omitted, the default_text_search_config configuration is used.

The options, as implemented, do not match 1:1 with the same options for `ts_headline`, and the differences should be noted below. If an options string is specified it must consist of a comma-separated list of one or more option=value pairs. The available options are:

* `MaxWords`, `MinWords` (integers): these numbers determine the number of words, beyond the length of a phrase in TSQuery, to return in each headline. For instance, a value of MinWords=4 will put min. 2 words on either side of a phrase headline.

* `ShortWord` (integer): NOT IMPLEMENTED: The system does not use precisely the same `rank_cd` ordering to return the most cover-dense headline segments first, but rather find the FIRST find n matching passages within the document. See `tsp_exact_matches` function for more

* `HighlightAll` (boolean): TODO: Implement this option.

* `MaxFragments` (integer): maximum number of text fragments to display. The default value of zero selects a non-fragment-based headline generation method. A value greater than zero selects fragment-based headline generation (see below).

* `StartSel`, `StopSel` (strings): the strings with which to delimit query words appearing in the document, to distinguish them from other excerpted words. The default values are “<b>” and “</b>”, which can be suitable for HTML output.

* `FragmentDelimiter` (string): When more than one fragment is displayed, the fragments will be separated by this string. The default is “ ... ”.

These option names are recognized case-insensitively. You must double-quote string values if they contain spaces or commas.

In non-fragment-based headline generation, ts_headline locates matches for the given query and chooses a single one to display, preferring matches that have more query words within the allowed headline length. In fragment-based headline generation, ts_headline locates the query matches and splits each match into “fragments” of no more than MaxWords words each, preferring fragments with more query words, and when possible “stretching” fragments to include surrounding words. The fragment-based mode is thus more useful when the query matches span large sections of the document, or when it's desirable to display multiple matches. 

#### TODO:
Currently: In either mode, if no query matches can be identified, we return NULL, however, this will do weird things with JOINs and as a result, we should really return text qsa per the ts_headline spec: 
> In either mode, if no query matches can be identified, then a single fragment of the first MinWords words in the document will be displayed.

For example
```
SELECT TS_SEMANTIC_HEADLINE('english'::REGCONFIG,
  'The most common type of search
is to find all documents containing given query-terms
and return them in order of their similarity to the query.',
  TO_TSPQUERY('english', 'query-terms & similarity<3>query'));
```
| tsp\_semantic\_headline |
| --- |
| \<b\>query\-terms\</b\>and return them in order of their \<b\>similarity to the query\</b\> |

```
'Search terms may occur
many times in a document,
requiring ranking of the search matches to decide which
occurrences to display in the result.',
  to_tsquery('english', 'search & term'),
  'MaxFragments=10, MaxWords=7, MinWords=3, StartSel=<<, StopSel=>>');
```