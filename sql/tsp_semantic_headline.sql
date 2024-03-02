/*
Function: tsp_semantic_headline
This function is intended as a 1:1 replacement for ts_headline and maintains
the same signature as ts_headline

Accepts: 
- config       REGCONFIG - PGSQL Text Search Language Configuration
- content      TEXT      - The source text to be fragmented and highlighted
- user_search  TSQuery   - TSQuery search as a collection of phrases, separated
                           by logical operators.
- options      TEXT      - Configuration options in the same form as the 
                           TS_HEADLINE options, with some semantic difference 
						   in interpretting parameters.


Returns a string of 1 or more passages of text, with content matching one or more 
phrase patterns in the TSQuery highlighted, meaning wrapped by the StartSel and 
StopSel options.

Options:
* `MaxWords`, `MinWords` (integers): these numbers determine the number of words, 
   beyond the length of a phrase in TSQuery, to return in each headline. For instance, 
   a value of MinWords=4 will put min. 2 words on either side of a phrase headline.
* `ShortWord` (integer): NOT IMPLEMENTED: The system does not use precisely the same 
   `rank_cd` ordering to return the most cover-dense headline segments first, but rather 
   find the FIRST find n matching passages within the document. See `tsp_exact_matches` 
   function for more.
* `HighlightAll` (boolean): TODO: Implement this option.
* `MaxFragments` (integer): maximum number of text fragments to display. The default 
  value of zero selects a non-fragment-based headline generation method. A value 
  greater than zero selects fragment-based headline generation (see below).
* `StartSel`, `StopSel` (strings): the strings with which to delimit query words 
   appearing in the document, to distinguish them from other excerpted words. The 
   default values are “<b>” and “</b>”, which can be suitable for HTML output.
* `FragmentDelimiter` (string): When more than one fragment is displayed, the fragments 
   will be separated by this string. The default is “ ... ”.
*/

/*
Note: This form is the 1:1 replacement for ts_headline:

Likewise, this function uses TS_HEADLINE under the hood to handle content that 
does NOT use precomputed TEXT[] and TSVector columns. Rather, this implementation
calls ts_headline to return fragments, and then applies the arity-5 form of
tsp_semantic_headline to the results to achieve semantically accurate phrase
highlighting.
*/
-- Arity-4 Form of simplified tsp_semantic_headline 
CREATE OR REPLACE FUNCTION tsp_semantic_headline 
(config REGCONFIG, content TEXT, user_search TSQUERY, options TEXT DEFAULT '')
RETURNS TEXT AS
$$
DECLARE cleaned_content TEXT = ts_headline(config, 
                                           content, 
										   user_search, 
										   'StartSel="",StopSel="",FragmentDelimiter= XDUMMYFRAGMENTX ' || options);
BEGIN
	RETURN tsp_fast_headline(config,
	                         tsp_to_text_array(cleaned_content), 
                             tsp_to_tsvector(config, UNACCENT(cleaned_content)),
                             UNACCENT(user_search::TEXT)::TSQUERY,
                             options);
END;
$$
STABLE
LANGUAGE plpgsql;

-- OVERLOAD Arity-4 form #2, to infer the default_text_search_config for parsing
-- Arity-3 Form of simplified tsp_semantic_headline 
CREATE OR REPLACE FUNCTION tsp_semantic_headline
(content TEXT, user_search TSQUERY, options TEXT DEFAULT '')
RETURNS TEXT AS
$$
BEGIN
	RETURN tsp_semantic_headline(current_setting('default_text_search_config')::REGCONFIG, 
	                            content, 
								user_search, 
								options);
END;
$$
STABLE
LANGUAGE plpgsql;
