

EXTENSION = tsp_semantic_headline
DATA = tsp_semantic_headline--1.0.sql
DIRECTORY = /sql
EXTENSION_NAME = tsp_semantic_headline
VERSION = 1.0
SCHEMA = public
DB_NAME = default_database
DB_USER = default_user
PG_CONFIG = pg_config
PGXS := $(shell $(PG_CONFIG) --pgxs)
include $(PGXS)

.PHONY: all compile_sql test

test: 
	psql -U $(DB_USER) -d $(DB_NAME) -f ./test/english_lang_test.sql
	psql -U $(DB_USER) -d $(DB_NAME) -f ./test/german_lang_test.sql
	psql -U $(DB_USER) -d $(DB_NAME) -f ./test/jswift_modest_proposal_test.sql

all: compile_sql

compile_sql:
	bash package.sh .$(DIRECTORY) $(DATA)
