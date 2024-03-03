/*
Function: TS_SEMANTIC_HEADLINE
This function is intended as a 1:1 replacement for ts_headline and maintains
the same signature as ts_headline

Accepts: 
- config       REGCONFIG - PGSQL Text Search Language Configuration
- content      TEXT      - The source text to be fragmented and highlighted
- user_search  TSQuery   - TSQuery search as a collection of phrases, separated
                           by logical operators. Do NOT pass a TSPQuery to this 
                           function.
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
TS_SEMANTIC_HEADLINE to the results to achieve semantically accurate phrase
highlighting.
*/


-- Arity-4 Form of simplified TS_SEMANTIC_HEADLINE 
CREATE OR REPLACE FUNCTION TS_SEMANTIC_HEADLINE
(config REGCONFIG, content TEXT, user_search TSQUERY, options TEXT DEFAULT '')
RETURNS TEXT AS
$$
DECLARE headline TEXT = ts_headline(config, 
                                    content, 
							               user_search, 
								            'StartSel="",StopSel="",FragmentDelimiter=XDUMMYFRAGMENTX,' || options);
BEGIN
    user_search := TO_TSPQUERY(regexp_replace((user_search::TEXT), '''(\w+)(\W)(\w+)'' <-> ''(\w+)'' <-> ''(\w+)''', 
                                              E'\\4 <-> \\5',
                                              'g'));
    headline := regexp_replace(' ' || headline || ' ', 'XDUMMYFRAGMENTX', ' ... ', 'g');
    IF (OPTIONS <> '') THEN options := ',' || options; END IF;
    RETURN COALESCE(TS_FAST_HEADLINE(config,
	                                  TO_TSP_TEXT_ARRAY(headline), 
                                     TO_TSPVECTOR(config, headline), 
                                     user_search,
                                     'MaxFragments=30,MinWords=64,MaxWords=64' || options),
                    headline);
END;
$$
STABLE
LANGUAGE plpgsql;

-- OVERLOAD Arity-4 form #2, to infer the default_text_search_config for parsing
-- Arity-3 Form of simplified TS_SEMANTIC_HEADLINE 
CREATE OR REPLACE FUNCTION TS_SEMANTIC_HEADLINE
(content TEXT, user_search TSQUERY, options TEXT DEFAULT '')
RETURNS TEXT AS
$$
BEGIN
	RETURN TS_SEMANTIC_HEADLINE(current_setting('default_text_search_config')::REGCONFIG, 
	                            content, 
								       user_search, 
								       options);
END;
$$
STABLE
LANGUAGE plpgsql;
