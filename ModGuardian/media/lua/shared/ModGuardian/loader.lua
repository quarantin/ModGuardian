local hex2binary = {
	['0']='0000',
	['1']='0001',
	['2']='0010',
	['3']='0011',
	['4']='0100',
	['5']='0101',
	['6']='0110',
	['7']='0111',
	['8']='1000',
	['9']='1001',
	['a']='1010',
	['b']='1011',
	['c']='1100',
	['d']='1101',
	['e']='1110',
	['f']='1111',
}

local binary2hex = {
	['0000']='0',
	['0001']='1',
	['0010']='2',
	['0011']='3',
	['0100']='4',
	['0101']='5',
	['0110']='6',
	['0111']='7',
	['1000']='8',
	['1001']='9',
	['1010']='a',
	['1011']='b',
	['1100']='c',
	['1101']='d',
	['1110']='e',
	['1111']='f',
}

local hex2char = {}
for i = 0, 255 do
	hex2char[("%02x"):format(i)] = string.char(i)
end

local function hex(data)
	local out = ''
	for i = 1, #data do
		char = string.sub(data, i, i)
		out = out .. string.format("%02x", string.byte(char))
	end
	return out
end

local function unhex(data)
	local result, _ = data:gsub("(..)", hex2char)
	return result
end

local function xor_bits(a, b)
	return a == b and '0' or '1'
end

local function xor_nibbles(a, b)
	local out = ''
	local a = hex2binary[a]
	local b = hex2binary[b]
	for i=1, 4 do
		local bit_a = a:sub(i, i)
		local bit_b = b:sub(i, i)
		out = out .. xor_bits(bit_a, bit_b)
	end
	return binary2hex[out]
end

local function key_schedule(key, length)
	local out = ''
	while #out < length do
		out = out .. key
	end
	return out
end

function ModGuardianEncrypt(a, b)
	local out = ''
	local a = hex(a)
	local b = hex(key_schedule(b, #a))
	for i=1, #a do
		local nibble_a = a:sub(i, i)
		local nibble_b = b:sub(i, i)
		out = out .. xor_nibbles(nibble_a, nibble_b)
	end
	return out
end

function ModGuardianDecrypt(a, b)
	local out = ''
	local b = key_schedule(hex(b), #a)
	for i=1, #a do
		local nibble_a = a:sub(i, i)
		local nibble_b = b:sub(i, i)
		out = out .. xor_nibbles(nibble_a, nibble_b)
	end
	local data = unhex(out)
	print(data)
	return loadstring(data)()
end

return {
	['a00'] = ModGuardianDecrypt
}
