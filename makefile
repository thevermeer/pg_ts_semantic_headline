EXTENSION = ts_semantic_headline
DIRECTORY = /sql
EXTENSION_NAME = ts_semantic_headline
VERSION = 1.0
SCHEMA = public

PG_CONFIG = pg_config
PGXS := $(shell $(PG_CONFIG) --pgxs)
include $(PGXS)