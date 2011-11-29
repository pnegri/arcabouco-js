SHELL := /bin/bash

test:
	@node test/arcabouco.js

doc:
	docco lib/*.coffee

.PHONY: test
