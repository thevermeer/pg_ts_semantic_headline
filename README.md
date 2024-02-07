# PostgreSQL Full-text Search and Semantic ts_headline functionality
The purpose of this repository is to document some issues encountered with using PostgreSQL full-text search to display highlighted search results to the user, and propose a solution that is expressed firstly as PGSQL user-defined functions (UDFs). The goal of creating this functionality is to demonstrate the value to the PostgreSQL community of correcting the ts_headline function to better reflect the actual semantics of the full-text search operators used for index lookup. From that, the goal is to introduce better ts_headline semantics into the postgresql source code. To get there, let's first outline the current issues and create a few UDFs to address the issue and illuminate the value of the improvements.

## Preamble
I am a full-stack developer, building a web application that has stored a large volume of texts, as rows in a postgreSQL data table. The UI we are building performs full-text search by accepting a user-inputted string, searching, and displaying results. When we display results, we want to display passages from the text with "highlights", emphasizing the portions of the passage that match our search.

The user has at their disposal the ability to search a single word or a multi-word phrase; they can join phrases together with AND/OR operators, group logical expressions with brackets and negate the presence of certain words with NOT. [[pgsql Full-text search - 12.1.2 matching](https://www.postgresql.org/docs/current/textsearch-intro.html#TEXTSEARCH-MATCHING)]

In the database, we have created a table to store the text contents of a large volume of files. For each tuple in the "files" table, we have a file ID, a text field, and a TS Vector column that is a pre-realized, because adhoc realization of TSVector of a large table of text is very memory-(and time-)intensive, and likewise such that we can create a GIN index of the TSVector column for fast lookup. This is a recommended pattern for large-scale full-text search in PostgreSQL. [[pgsql Full-text Search - 12.2.2 Creating Indexes](https://www.postgresql.org/docs/current/textsearch-tables.html#TEXTSEARCH-TABLES-INDEX)]

## Problems with ts_headline
As a developer, the built-in ts_headline offers a number of quirks and gotchas, and at the highest level, it is fair to say that the internals to ts_headline do not abide by the intended meaning of full-text operators. Specifically when the user has inputted a multi-word phrase, we find that ts_headline will return only partial matches, and only highlight single words from the phrase.

### 1. ts_headline returns passages that do NOT contain the searched phrase
For multi-word search terms, ts_headline is treating a multi-word phrase like `subject of interest` as three, indepentent terms: `subject`, `of` and `interest`. As a result, the ts_headline function will return passages from the source that only contain partial matches. If the user is presented with a passage that only demonstrates a partial match, we will have broken user expectations:
``` 
SELECT ts_headline('liberally apply shampoo to scalp', to_tsquery('liberally<->applied<->semantics'));

::>
ts_headline
<b>liberally</b> apply shampoo to scalp
```
The partial highlighting may seem trivial at this first stage, however, when applied to large documents, and the `MaxFragments` option for ts_headline is greater than zero (See [[pgsql Full-text search - 12.3.4 Highlighting Results](https://www.postgresql.org/docs/current/textsearch-controls.html#TEXTSEARCH-HEADLINE)]) we can easily end up with somne partial matches, and we do not want those displayed.

### 2. ts_headline only highlights single words for multi-word phrase queries.
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

### 3. How can I use ts_headline to return the exact phrase matches from a lexeme-reduced TSVector
I am