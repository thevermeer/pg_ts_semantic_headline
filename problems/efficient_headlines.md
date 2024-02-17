# Highlightling multi-word phrases

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
