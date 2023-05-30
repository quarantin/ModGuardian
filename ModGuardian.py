#!/usr/bin/env python3

import os
import sys
import json
import shutil

from luaparser import ast

class CommentVisitor(ast.ASTVisitor):

	def visit_Comment(self, node):
		node.s = ''

class IndexVisitor(ast.ASTVisitor):

	def visit_Index(self, node):
		if hasattr(node.value, 'id') and node.value.id in ModGuardian.exposed and hasattr(node.idx, 'id'):
			ModGuardian.keywords[node.idx.id] = True

class InvokeVisitor(ast.ASTVisitor):

	def visit_Invoke(self, node):
		ModGuardian.keywords[node.func.id] = True

class NameVisitor(ast.ASTVisitor):

	def visit_Name(self, node):
		if not node.id.startswith('IS'):
			node.id = ModGuardian.obfuscate_name(node.id)

class StringVisitor(ast.ASTVisitor):

	def visit_String(self, node):
		node.s = ModGuardian.obfuscate_string(node.s)

class ModGuardian:

	def __init__(self, input_dir, output_dir, config='config.json', strip_newlines=True, strip_indent=True):
		ModGuardian.db = {}
		ModGuardian.counter = 0
		self.input_dir = input_dir
		self.output_dir = output_dir
		self.parse_config(config)
		self.modinfo = self.parse_mod_info()
		self.prelude = "require('ModGuardian/loader').a00(DATA,KEY)"

	def parse_config(self, config):
		ModGuardian.exposed = {}
		ModGuardian.keywords = {}
		with open(config) as fd:
			jsondata = json.loads(fd.read())
		for keyword in jsondata['exposed'] + jsondata['files']:
			ModGuardian.exposed[keyword] = True
			ModGuardian.keywords[keyword] = True
		for keyword in jsondata['events'] + jsondata['fields'] + jsondata['functions'] + jsondata['globals'] +  jsondata['methods'] + jsondata['LuaMethods'] + jsondata['ModGuardian']:
			ModGuardian.keywords[keyword] = True

	def parse_mod_info(self):
		modinfo = {}
		filepath = os.path.join(self.input_dir, 'mod.info')
		with open(filepath) as fd:
			for line in fd:
				key, value = line.strip().split('=', 1)
				modinfo[key.lower()] = value
		return modinfo

	def obfuscate_name(name):

		if name in ModGuardian.keywords:
			return name

		if name not in ModGuardian.db:
			ModGuardian.db[name] = 'a' + str(ModGuardian.counter)
			ModGuardian.counter += 1

		return ModGuardian.db[name]

	def obfuscate_string(string):
		newstring = ''
		for char in string:
			newstring += '\\' + str(ord(char))
		return newstring

	def obfuscate_data(self, data):
		tree = ast.parse(data)

		InvokeVisitor().visit(tree)
		IndexVisitor().visit(tree)
		NameVisitor().visit(tree)
		StringVisitor().visit(tree)
		CommentVisitor().visit(tree)

		newdata = ast.to_lua_source(tree)
		lines = []
		for line in newdata.splitlines():
			line = line.rstrip().replace('return False', 'return')
			if line.endswith('='):
				line += ' nil'
			lines.append(line)
		newdata = '\n'.join(lines)

		return ' '.join(newdata.split())

	def obfuscate_file(self, input_file, output_file, encrypt=True):

		with open(input_file) as fd:
			code = fd.read()

		newcode = self.obfuscate_data(code)

		with open(output_file, 'w') as fd:

			if encrypt:
				key, random = self.get_random_key()
				newcode = self.encrypt(newcode, key)
				#print(self.decrypt(newcode, key))

				self.keywords['a00'] = True
				self.keywords['DATA'] = True
				prelude = self.prelude.replace('KEY', '"%s"' % random) # self.to_lua_string(random))
				prelude = self.obfuscate_data(prelude)
				self.keywords.pop('a00')
				self.keywords.pop('DATA')
				prelude = prelude.replace('DATA', '"%s"' % newcode)
			if os.path.basename(input_file) == 'ModGuardian.lua':
				fd.write('return ')
			fd.write(encrypt and prelude or newcode)

	def to_lua_string(self, data):
		output = ''

		for b in data:
			output += '\\' + str(b)

		return output

	def obfuscate(self):

		if not self.output_dir:
			self.output_dir = self.input_dir + '.obfuscated'

		if os.path.exists(self.output_dir):
			shutil.rmtree(self.output_dir)

		shutil.copytree(self.input_dir, self.output_dir)

		for root, dirs, files in os.walk(self.input_dir):

			for name in files:
				input_file = os.path.join(root, name)
				output_file = input_file.replace(self.input_dir, self.output_dir, 1)
				if not input_file.lower().endswith('.lua'):
					continue

				encrypt = (os.path.basename(input_file) != 'loader.lua')
				self.obfuscate_file(input_file, output_file, encrypt=encrypt)

	def get_random_key(self, length=64):

		# TODO Mix workshopID in the key somehow
		#workshop_id = self.key_schedule(workshop_id, length)
		random = os.urandom(length).replace(b'"', b"'")
		return repr(random)[2:-1], repr(random)[2:-1]

	def key_schedule(self, key, length):
		out = ''
		while len(out) < length:
			out += key
		return out

	def encrypt(self, a, b):
		encrypted = ''

		b = self.key_schedule(b, len(a))

		for c1, c2 in zip(a, b):
			xored = ord(c1) ^ ord(c2)
			encrypted += f'{xored:02x}'

		return encrypted

	def decrypt(self, a, b):
		decrypted = ''
		a = bytes.fromhex(a).decode('utf-8')
		b = self.key_schedule(b, len(a))

		for c1, c2 in zip(a, b):
			xored = ord(c1) ^ ord(c2)
			#print(chr(xored))
			decrypted += chr(xored)

		return decrypted
def main():

	if len(sys.argv) < 2:
		print("Usage: %s <input dir> [output dir]" % sys.argv[0])
		sys.exit()

	input_dir = sys.argv[1].rstrip('/')
	output_dir = None

	if len(sys.argv) > 2:
		output_dir = sys.argv[2].rstrip('/')

	ModGuardian(input_dir, output_dir).obfuscate()

if __name__ == '__main__':
	main()
