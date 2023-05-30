#!/usr/bin/env python3

import os
import re
import sys
import json

from luaparser import ast, astnodes

zomboid_lua_path = '/home/co/hack/beautiful-java.git/pz/41.78/lua'
#zomboid_lua_path = 'tests'
zomboid_java_path = '/home/co/hack/beautiful-java.git/pz/41.78/sources/'

dbkeys = [
	'events',
	'exposed',
	'fields',
	'files',
	'functions',
	'globals',
	'methods',
	'LuaMethods',
]

stringfuncs = [
	"byte",
	"compare",
	"rep"
]

db = {}
for key in dbkeys:
	db[key] = set()

db['ModGuardian'] = [
	'disablePlayerBlacklist',
	'disableServerBlacklist',
	'disableExclusiveServers',
	'disableModpackCheck',
	'exclusiveServers',
	'playerBlacklist',
	'serverBlacklist',
	'modID',
	'workshopID'
]

class SetEncoder(json.JSONEncoder):

	def default(self, obj):
		if isinstance(obj, set):
			return sorted(list(obj))
		return json.JSONEncoder.default(self, obj)

class FunctionVisitor(ast.ASTVisitor):

	def visit_Function(self, node):
		if isinstance(node.name, astnodes.Name):
			db['functions'].add(node.name.id)
		elif isinstance(node.name, astnodes.Index):
			if isinstance(node.name.value, astnodes.Index):
				db['functions'].add(node.name.value.value.id)
			else:
				db['functions'].add(node.name.value.id)
		else:
			raise Exception('AST node type: ' + str(type(node.name)))

class IndexVisitor(ast.ASTVisitor):

	def visit_Index(self, node):
		if isinstance(node.value, astnodes.Name):
			if isinstance(node.idx, astnodes.Name):
				db['fields'].add(node.idx.id)
			else:
				#print("DEBUG1: FALLBACK: ", type(node.idx), node.idx, file=sys.stderr)
				pass
		elif isinstance(node.value, astnodes.Index):
			if isinstance(node.value.value, astnodes.Index):
				#print("DEBUG2", type(node.value.value.value), node.value.value.value.id, file=sys.stderr)
				pass
			else:
				#print("DEBUG3", type(node.value.value.id), node.value.value.id, file=sys.stderr)
				pass

class MethodVisitor(ast.ASTVisitor):

	def visit_Method(self, node):
		db['methods'].add(node.name.id)
		#print(node.name.id)

def get_path(filename):
	return os.path.join(os.path.dirname(__file__), filename)

def apply_transform(path, code):

	transforms = {
		'stdlib.lua': (r'\[\[-- test --\]\]', r''),
		'ISZoneDisplay.lua': (r'\\%', r'\\\\%'),
		'ISGameStatisticPanel.lua': (r'([0-9]+\.[0-9]+)f', r'\1'),
	}

	name = os.path.basename(path)
	if name not in transforms:
		return code

	t = transforms[name]
	return re.sub(t[0], t[1], code)

def parse_with_regex(path, regex, dbkey):
	with open(path) as fd:
		code = fd.read()
		for name in re.findall(regex, code):
			db[dbkey].add(name)

def parse_lua(path):
	with open(path) as fd:
		code = apply_transform(path, fd.read())
		tree = ast.parse(code)
		FunctionVisitor().visit(tree)
		IndexVisitor().visit(tree)
		MethodVisitor().visit(tree)

def parse_globals():

	for symbol in stringfuncs:
		db['functions'].add(symbol)

	path = get_path('_G.txt')
	with open(path) as fd:
		for line in fd:

			symbol, symtype = line.strip().split(';', 1)
			if symtype == 'table':
				db['globals'].add(symbol)

			elif symtype in ['closure', 'function']:
				db['functions'].add(symbol)

def process_lua():

	regex_events = r'triggerEvent\("([^"]*)"'

	parse_globals()

	for root, dirs, files in os.walk(zomboid_lua_path):

		for name in files:
			if not name.endswith('.lua'):
				continue

			path = os.path.join(root, name)
			print(path)

			db['files'].add(name.replace('.lua', ''))
			parse_lua(path)
			parse_with_regex(path, regex_events, 'events')

def process_java():

	regex_events = r'triggerEvent\("([^"]*)"'
	regex_exposed = r'setExposed\(([_a-zA-Z0-9]*).class\)'
	regex_luamethods = r'@LuaMethod\(.*name = "([^"]*)"'

	for root, dirs, files in os.walk(zomboid_java_path):

		for name in files:
			if not name.endswith('.java'):
				continue

			path = os.path.join(root, name)
			print(path)

			parse_with_regex(path, regex_events, 'events')
			parse_with_regex(path, regex_exposed, 'exposed')
			parse_with_regex(path, regex_luamethods, 'LuaMethods')

process_java()
process_lua()

path = get_path('config.json')
print(path)
with open(path, 'w') as fd:
	fd.write(json.dumps(db, indent='\t', cls=SetEncoder))
