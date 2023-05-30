#!/usr/bin/env python3

import sys
from luaparser import ast

with open(sys.argv[1]) as fd:
	code = fd.read()
	tree = ast.parse(code)
	print(ast.to_lua_source(tree))
