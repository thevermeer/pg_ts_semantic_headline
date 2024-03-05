/*
Function: TO_TSPQUERY

Accepts:
- config       REGCONFIG - PGSQL Text Search Language Configuration
- query_string TEXT      - String of search terms connected with TSQuery
                           operators.

Akin to the builtin function `to_tsquery`, this function converts text to a 
tsquery, normalizing words according to the specified or default configuration. 
The words must be combined by valid tsquery operators.

TO_TSPQUERY('english', 'The & Fat & Rats') → 'fat' & 'rat'

For the purposes of a TSQuery, this function is the treatment for TSQueries for
index-friendly positioning and is paralleled with TSP_INDEXABLE_TEXT in TSVectors
*/

CREATE OR REPLACE FUNCTION TO_TSPVECTOR(config REGCONFIG, string TEXT)
RETURNS TSPVECTOR AS
$$
BEGIN
	RETURN (TO_TSVECTOR(config, TSP_INDEXABLE_TEXT(unaccent(string))) || ('''ProcessedUnaccentedTSPIndexableText'':16384')::TSVECTOR)::TSPVECTOR;
END;
$$
STABLE
LANGUAGE plpgsql;

-- OVERLOAD Arity-2 form, to infer the default_text_search_config for parsing
CREATE OR REPLACE FUNCTION TO_TSPVECTOR(string TEXT)
RETURNS TSPVECTOR AS
$$
BEGIN    
    RETURN TO_TSPVECTOR(current_setting('default_text_search_config')::REGCONFIG, 
	                       string);
END;
$$
STABLE
LANGUAGE plpgsql;

-- Internal function that will transform a TSVector into a TSPVector WITHOUT 
-- checking internal lexemes, thus asserting that the TSVector is a well-formed
-- TSPVector. This function should ONLY be used on a candidate TSVector that is 
-- known to also be a well-formed TSPVector.
-- Internally this is used to coerce the disassembled portions of a known TSPVector
-- into pieces for semantic checking against a query phrase within tsp_query_matches.
CREATE OR REPLACE FUNCTION ASSERT_TSPVECTOR(vec TSVector)
RETURNS TSPVECTOR AS
$$
BEGIN    
    RETURN (vec || ('''ProcessedUnaccentedTSPIndexableText'':16384')::TSVECTOR)::TSPVECTOR;
END;
$$
STABLE
LANGUAGE plpgsql;