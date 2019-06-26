function table.print(tbl, indent)
	if type(tbl)~="table" then return end
	if not indent then indent = 0 end
	for k, v in pairs(tbl) do
		formatting = string.rep('  ', indent) .. k .. ': '
		if type(v) == 'table' then
			print(formatting)
			table.print(v, indent+1)
		else
			print(formatting .. tostring(v))
		end
	end
end
local stack = {
	__tostring = function(self)
		return table.concat(self,", ")
	end
}
stack.__index=stack
function stack:new(n)
	local c = {}
	setmetatable(c,stack)
	c.limit = n
	return c
end
function stack:push(dat)
	if self.limit then return "StackOverflow!" end
	table.insert(self,dat)
end
function stack:peek()
	return self[#self]
end
function stack:pop()
	return table.remove(self)
end
local special = {["("]=true,[")"]=true,["+"]=true,["-"]=true,["/"]=true,["*"]=true,["%"]=true,["^"]=true}
function parseA(expr)
	local data = {}
	local group = ""
	for i in expr:gmatch(".") do
		if special[i] then
			if group~="" then
				data[#data+1]=group
			end
			data[#data+1]=i
			group = ""
		elseif i~=" " then
			group = group .. i
		end
	end
	return data
end
function parseB(dat)
	local isNum = false
	local isFunc = false
	local isVar = false
	local cmds = {}
	local ref
	local open = 0
	for i,v in ipairs(dat) do
		if #v>1 and tostring(tonumber(v))~=v and dat[i+1] and dat[i+1]=="(" then
			table.insert(cmds,{"Function",v})
		elseif tostring(tonumber(v))==v then
			table.insert(cmds,{"Number",v})
		elseif #v>1 and tostring(tonumber(v))~=v then
			table.insert(cmds,{"Variable",v})
		else
			table.insert(cmds,v)
		end
	end
	return cmds
end
function parseC(dat)
	local a = {}
	local ref
	local pos = 0
	local open = 0
	local group = {}
	for i,v in ipairs(dat) do
		if v=="(" then
			open = open + 1
			if not ref then
				ref = {}
			end
		elseif v==")" then
			open = open - 1
			if open == 0 then
				table.insert(group,ref)
				ref = nil
			elseif open < 0 then
				error("Unbalanced ()")
			end
		elseif ref == nil then
			table.insert(group,v)
		else
			table.insert(ref,v)
		end
	end
	return group
end
function parse(e)
	local tokens = parseA(e)
	local cmds = parseB(tokens)
	local c = parseC(cmds)
	table.print(c)
end
------------------
expr = "test(2.4+(18+(20-4)))/(sqrt(100) + food) + 5(10 + 4)"
function prepare(expr)
	local cmds = {}
	local cc = 64
	function clean(expr)
		expr = expr:gsub("(%b())",function(a)
			local dat = a:sub(2,-2)
			if not(dat:find("%(") or dat:find("%)")) then
				cc=cc+1
				cmds["$"..string.char(cc)]=dat
				return "$"..string.char(cc)
			else
				return clean(dat)
			end
		end)
		return expr
	end
	local expr = clean(expr)
	print(expr)
	table.print(cmds)
end
prepare(expr)
--~ c=parse(expr)
