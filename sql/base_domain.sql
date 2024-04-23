-- TYPE/DOMAIN for restricting, differentiating and marshalling pre- v.
--  post-processed TS Query and Vectors

-- TYPE: TSPQuery
-- OVERLOADS: TSQuery
-- Enforces a query that is BOTH UNACCENTed and contains no infix characters; 
-- \W+ will capture 
DO $$ BEGIN
    CREATE DOMAIN TSPQuery AS TSQuery
    NOT NULL CHECK (value::TEXT !~ '[\w+][\W+][\w]');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- Note:
-- 1) in TO_TSPVECTOR er inject a dummy, marker node into the max lexeme 
--    position, 16383
-- 2) multiple lexemes can occupy position 16,383 without logically 
--    interfering with each other

-- A TSPVector 'proves' it has been pre-processed by inserting the
-- ProcessedUnaccentedTSPIndexableText at the maximum position.
DO $$ BEGIN
    CREATE DOMAIN TSPVector AS TSVector
    NOT NULL CHECK (value @@ 'ProcessedUnaccentedTSPIndexableText'::TSQUERY);
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;
