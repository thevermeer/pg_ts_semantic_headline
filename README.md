# PostgreSQL Full-text Search and Semantic ts_headline functionality
## Abstract
We explore a series of methods for improving the way that postgreSQL's ts_headline function resepects the semantics of phrase matching. 

In the process, we uncover a method for replacing ts_headline that, when implemented using pre-computed columns, performs over 10 times faster than the built-in function.

## Purpose
The purpose of this repository is to document some issues encountered with using PostgreSQL full-text search to display highlighted search results to the user, and propose a solution that is expressed firstly as PGSQL user-defined functions (UDFs). The goal of creating this functionality is to demonstrate the value to the PostgreSQL community of correcting the ts_headline function to better reflect the actual semantics of the full-text search operators used for index lookup. From that, the goal is to introduce better ts_headline semantics into the postgresql source code. To get there, let's first outline the current issues and create a few UDFs to address the issue and illuminate the value of the improvements.

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
Approach: [[An approach to content hihglighting that is up to 10 times faster than built-in ts_headline](https://github.com/thevermeer/postgresql_semantic_tsheadline/blob/main/problems/efficient_headlines.md)]
### 4. ts_headline only highlights single words for multi-word phrase queries
Approach: [[Headline function that highlights phrases without partial matches](https://github.com/thevermeer/postgresql_semantic_tsheadline/blob/main/problems/multi_word_phrase_highlighting.md)]

