## Setup and Data initialization
In order to emulate a real-world large document store in postgreSQL full-text search, we will create a simple table with 10,000 files.

Each file will contain the first 2 paragraphs of Charles Dickens' 'A Tale of Two Cities' repeated 30 times. Each document will then contain 10,290 words (ie. TSVector lexeme positions). Each row will contain an ID, a `content` (TEXT) column and a `content_tsv` column, with a preprocessed TSVector of the content text.

### Create the table
To start, we add a `files` table to our database.
```
-- Table Definition ----------------------------------------------

CREATE TABLE files (
    id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    content text,
    content_tsv tsvector,
    CONSTRAINT files_id_not_null 
);

-- Indices -------------------------------------------------------

CREATE UNIQUE INDEX files_pkey ON files(id int4_ops);
```

### Add a trigger on content insert/update to generate TSVector
Next we add a trigger to our table, to update the content_tsv column when changes are made to the content text field. This will ensure that the TSVector and the source content will have consistent word positions:
```
-- Create or replace the trigger function
CREATE OR REPLACE FUNCTION trg_update_content_tsv()
RETURNS TRIGGER AS $$
BEGIN
    NEW.content_tsv := to_tsvector('english', NEW.content);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create the trigger on the files table
CREATE TRIGGER update_content_tsv_trigger
BEFORE INSERT OR UPDATE OF content ON files
FOR EACH ROW
EXECUTE FUNCTION trg_update_content_tsv();
```

### Add the content
Next, we add our content from Dickens' work, in order to emulate 10,000 files, each of ~10,000 words.
I do not want to insert a massive volume of text here, so I am using repeat on a large enough text that the resulting TSVectors should be well-formed and meaningful:
```
INSERT INTO files (content)
SELECT CONCAT(REPEAT('It was the best of times, it was the worst of times, it was the age of wisdom, it was the age of foolishness, it was the epoch of belief, it was the epoch of incredulity, it was the season of Light, it was the season of Darkness, it was the spring of hope, it was the winter of despair, we had everything before us, we had nothing before us, we were all going direct to Heaven, we were all going direct the other way—in short, the period was so far like the present period, that some of its noisiest authorities insisted on its being received, for good or for evil, in the superlative degree of comparison only.

There were a king with a large jaw and a queen with a plain face, on the throne of England; there were a king with a large jaw and a queen with a fair face, on the throne of France. In both countries it was clearer than crystal to the lords of the State preserves of loaves and fishes, that things in general were settled for ever.

It was the year of Our Lord one thousand seven hundred and seventy-five. Spiritual revelations were conceded to England at that favoured period, as at this. Mrs. Southcott had recently attained her five-and-twentieth blessed birthday, of whom a prophetic private in the Life Guards had heralded the sublime appearance by announcing that arrangements were made for the swallowing up of London and Westminster. Even the Cock-lane ghost had been laid only a round dozen of years, after rapping out its messages, as the spirits of this very year last past (supernaturally deficient in originality) rapped out theirs. Mere messages in the earthly order of events had lately come to the English Crown and People, from a congress of British subjects in America: which, strange to relate, have proved more important to the human race than any communications yet received through any of the chickens of the Cock-lane brood.', 30),
generate_series(1, 10000)); 
```
This last step will take some time, as we are both inserting text and creating TS Vectors from it...
