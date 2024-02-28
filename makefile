

EXTENSION = tsp_semantic_headline
DATA = tsp_semantic_headline--1.0.sql
DIRECTORY = /sql
EXTENSION_NAME = tsp_semantic_headline
VERSION = 1.0
SCHEMA = public

PG_CONFIG = pg_config
PGXS := $(shell $(PG_CONFIG) --pgxs)
include $(PGXS)

.PHONY: all compile_sql

all: compile_sql

compile_sql:
	bash package.sh .$(DIRECTORY) $(DATA)
