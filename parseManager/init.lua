require("bin")
parseManager={}
parseManager.VERSION = 3.4
parseManager.__index=parseManager
parseManager.chunks={}
parseManager.stats={}
parseManager.stack={}
parseManager.cFuncs={}
parseManager.mainENV={}
parseManager.__INTERNAL = {}
parseManager.currentENV=parseManager.mainENV
parseManager.entry="START"
parseManager.methods={}
parseManager.lastCall=nil
parseManager.currentHandle=nil
parseManager.currentHandleName=nil
function readonlytable(tab)
	return setmetatable({},{
		__index=tab,
		__newindex=function()
			error("Attempt to modify read-only table!")
		end,
		__metatable=false
	})
end
function parseManager:debug(...)
	if self.stats.debugging then
		print("<DEBUG>",...)
	end
end
function parseManager:newENV()
	local env={}
	function env:getParent()
		return getmetatable(self).__index
	end
	setmetatable(env,{__index=self.currentENV})
	return env
end
function parseManager:setENV(env)
	self.currentENV=env
end
function parseManager:defualtENV()
	self:setENV(self.mainENV)
end
function parseManager:exposeNamespace(name,ref)
	self.mainENV[name]=ref
end
function factorial(n)
    if (n == 0) then
        return 1
    else
        return n * factorial(n - 1)
    end
end
function parseManager:load(path,c)
	local c = c
	if not c then
		c = {}
		setmetatable(c,parseManager)
	end
	local file
	if type(path)=="table" then
		if path.Type=="bin" then
			file = path
		else
			error("Currently unsupported path type!")
		end
	elseif type(path)=="string" then
		if bin.fileExists(path) then
			file=bin.load(path)
		else
			error("File: "..path.." does not exist!")
		end
	end
	-- process the data
	file.data=file.data:gsub("/%*.-%*/","")
	file.data=file.data:gsub('%b""',function(a) a=a:gsub("//","\2") return a end)
	file.data=file.data:gsub("%b''",function(a) a=a:gsub("//","\2") return a end)
	file.data=file.data:gsub("//.-\n","\n")
	file.data=file.data:gsub('%b""',function(a) a=a:gsub(";","\1") return a end)
	file.data=file.data:gsub("%b''",function(a) a=a:gsub(";","\1") return a end)
	file.data=file.data:gsub(";\n","\n")
	file.data=file.data:gsub(";\r","\r")
	file.data=file.data:gsub(";","\n")
	file.data=file.data:gsub("\r\n","\n")
	file.data=file.data:gsub("\n\n","\n")
	file.data=file.data:gsub("\1",";")
	file.data=file.data:gsub("\2","//")
	file.data=file.data:gsub("\t","")
	file:trim()
	for fn in file:gmatch("ENABLE (.-)\n") do
		self:debug("E",fn)
		c.stats[string.lower(fn)]=true
	end
	for fn in file:gmatch("LOAD (.-)\n") do
		self:debug("L",fn)
		c:load(fn,c)
	end
	for fn in file:gmatch("DISABLE (.-)\n") do
		self:debug("D",fn)
		c.stats[string.lower(fn)]=false
	end
	for fn in file:gmatch("ENTRY (.-)\n") do
		self:debug("E",fn)
		c.entry=fn
	end
	for fn in file:gmatch("USING (.-)\n") do
		self:debug("U",fn)
		local m = require("parseManager."..fn)
		if not m then
			self:pushError(fn.." was not found as an import that can be used!")
		else
			c[fn](c)
		end
	end
	for fn in file:gmatch("VERSION (.-)\n") do
		self:debug("V",fn)
		local num = tonumber(fn)
		local int = tonumber(c.VERSION)
		if not num then 
			c:pushWarning("VERSION: "..fn.." is not valid! Assuming "..c.VERSION)
		else
			if num>int then
				c:pushWarning("This script was written for a version that is greater than what this interperter was built for!")
			end
		end
	end
	for name,data in file:gmatch("%[(.-)[:.-]?%].-{(.-)}") do
		local ctype="BLOCK"
		if name:find(":") then
			ctype=name:match(":(.+)")
			name=name:match("(.-):")
		end
		c.chunks[name]={}
		c.chunks[name].type=ctype
		c.chunks[name].pos=1
		c.chunks[name].labels={}
		c.chunks[name].path=path
		c.chunks[name].name=name
		parseManager.currentHandleName=name
		parseManager.currentHandle=c
		c:compile(name,ctype,data)
	end
	--c.chunks=readonlytable(c.chunks)
	c.mainENV["False"]=false
	c.mainENV["True"]=true
	return c
end
function parseManager:extractState()
	return {name=self.currentChunk.name,pos = self.currentChunk.pos,variables = self.mainENV,cc = self.currentENV}
end
function parseManager:injectState(tbl)
	self.chunks[tbl.name].pos=tbl.pos
	self.currentChunk=self.chunks[tbl.name]
	self.mainENV = tbl.variables
	self.currentENV = tbl.cc
end
function parseManager.split(s,pat)
	local pat=pat or ","
	local res = {}
	local start = 1
	local state = 0
	local c = '.'
	local elem = ''
	for i = 1, #s do
		c = s:sub(i, i)
		if state == 0 or state == 3 then -- start state or space after comma
			if state == 3 and c == ' ' then
				state = 0 -- skipped the space after the comma
			else
				state = 0
				if c == '"' or c=="'" then
					state = 1
					elem = elem .. '"'
				elseif c=="[" then
					state = 1
					elem = elem .. '['
				elseif c == pat then
					res[#res + 1] = elem
					elem = ''
					state = 3 -- skip over the next space if present
				else
					elem = elem .. c
				end
			end
		elseif state == 1 then -- inside quotes
			if c == '"' or c=="'" then --quote detection could be done here
				state = 0
				elem = elem .. '"'
			elseif c=="]" then
				state = 0
				elem = elem .. ']'
			elseif c == '\\' then
				state = 2
			else
				elem = elem .. c
			end
		elseif state == 2 then -- after \ in string
			elem = elem .. c
			state = 1
		end
	end
	res[#res + 1] = elem
	return res
end
function deepcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[deepcopy(orig_key)] = deepcopy(orig_value)
        end
        setmetatable(copy, deepcopy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end
local function concat(tab,sep)
	if not tab then return "" end
	for g=1,#tab do
		if type(tab[g])=="table" then
			tab[g]="<"..(tab[g][1] or "!NEW!").."["..(tab[g][2] or "").."]>"
		end
		if type(tab[g])=="string" then
			tab[g]=tab[g]:gsub("\1","")
		end
		tab[g]=tostring(tab[g])
	end
	return table.concat(tab,sep)
end
function parseManager:dump()
	local bytecode = deepcopy(self.chunks)
	local str=""
	for i,v in pairs(bytecode) do
		str=str.."BLOCK: ["..i.."]\n"
		for k=1,#v do
			if type(v[k].Func)=="table" and v[k].Func.IsALookup==true then
				if v[k].Type=="fwor" then
					str=str.."\t"..v[k].Func[2].." "..concat(v[k].args,", ").."\n"
				elseif v[k].Type=="fwr" then
					str=str.."\t"..concat(v[k].vars,", ").." <- "..v[k].Func[2].." "..concat(v[k].args,", ").."\n"
				end
			elseif v[k].Type=="fwor" then
				str=str.."\t"..v[k].Func.." "..concat(v[k].args,", ").."\n"
			elseif v[k].Type=="funcblock" then
				str=str.."\tFUNCTION: args("..concat(v[k].args,", ")..")\n"
			elseif v[k].Type=="return" then
				str=str.."\tRETURN: rets("..concat(v[k].RETArgs,", ")..")\n"
			elseif v[k].Type=="label" then
				str=str.."\t::"..v[k].label.."::\n"
			elseif v[k].Type=="fwr" then
				str=str.."\t"..concat(v[k].vars,", ").." <- "..v[k].Func.." "..concat(v[k].args,", ").."\n"
			elseif v[k].Type=="choice" then
				local opt={}
				local met={}
				local args={}
				for i=1,#v[k] do
					opt[#opt+1]=v[k][i][1]
					met[#met+1]=v[k][i][2].Func
					args[#args+1]=concat(v[k][i][2].args," ")
				end
				str=str.."\tCHOICE["..v[k].prompt.."]$C<"..concat(opt,", ")..">$F<"..concat(met,", ")..">$A<"..concat(args,", ")..">\n"
			elseif v[k].Type=="text" then
				str=str.."\tDISP_MSG \""..v[k].text.."\"\n"
			elseif v[k].Type=="assign" then
				str=str.."\t"..concat(v[k].vars,", ").." <- "..concat(v[k].vals,", ").."\n"
			else
				str=str.."\tUnknown Code!: "..tostring(v[k].data).."\n"
			end
		end
	end
	return str
end
function table.print(tbl, indent)
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
function parseManager:pushError(err,sym)
	local lines = bin.load(self.currentChunk.path):lines()
	local chunk = self.currentChunk[self.currentChunk.pos-1]
	-- table.print(chunk)
	for i=1,#lines do
		if sym then
			if lines[i]:find(sym) then
				print(err.." At line: "..i.." "..(lines[i]:gsub("^\t+","")).." ("..tostring(sym)..")")
				break
			end
		elseif chunk.Type=="fwor" or chunk.Type=="fwr" then
			if lines[i]:match(chunk.Func.."%(") then
				print(err.." At line: "..i.." "..(lines[i]:gsub("^\t+","")).." ("..tostring(sym)..")")
				break
			end
		else
			
		end
	end
	io.read()
	os.exit()
end
function parseManager:pushWarning(warn)
	if not self.stats["warnings"] then return end
	print("WARNING: "..warn)
end
local function pieceList(list,self,name)
	if #list==0 then
		return {}
	end
	local list=parseManager.split(list)
	local L={}
	local mathass=1
	for i=1,#list do
		if list[i]:match("[%w_]-%[.-%]") and list[i]:sub(1,1)~='"' then
			local dict,sym=list[i]:match("([%w_]-)%[(.-)%]")
			if tonumber(sym) then
				L[#L+1]={"\1"..dict,tonumber(sym),IsALookup=true}
			elseif sym:sub(1,1)=="\"" and sym:sub(-1,-1)=="\"" then
				L[#L+1]={"\1"..dict,sym:sub(2,-2),IsALookup=true}
			end
		elseif list[i]:sub(1,1)=="\"" and list[i]:sub(-1,-1)=="\"" then
			L[#L+1]=list[i]:sub(2,-2)
		elseif list[i]:sub(1,1)=="[" and list[i]:sub(-1,-1)=="]" then
			L[#L+1]=pieceList(list[i]:sub(2,-2),self,name)
		elseif tonumber(list[i]) then
			L[#L+1]=tonumber(list[i])
		elseif list[i]:match("[%w_]-%..-") then
			local dict,sym=list[i]:match("([%w_]-)%.(.+)")
			L[#L+1]={"\1"..dict,sym,IsALookup=true}
		elseif list[i]=="true" then
			L[#L+1]=true
		elseif list[i]=="false" then
			L[#L+1]=false
		elseif list[i]:match("[%w_]+")==list[i] then
			L[#L+1]="\1"..list[i]
		elseif list[i]:match("[_%w%+%-/%*%^%(%)%%]+") then
			local char="$"..string.char(mathass+64)
			self:compileExpr(char,list[i],name)
			mathass=mathass+1
			L[#L+1]="\1"..char
		else
			self:pushError("Invalid Syntax!",list[i])
		end
	end
	return L
end
local function pieceAssign(a,self,name)
	local dict,ind=a:match("(.-)%[(.+)%]")
	local var
	if dict and ind then
		if ind:sub(1,1)=="\"" and ind:sub(-1,-1)=="\"" then
			var={dict,ind:sub(2,-2)}
		elseif tonumber(ind) then
			var={dict,tonumber(ind)}
		elseif ind:match("[%w_]+")==ind then
			var={dict,"\1"..ind}
		elseif ind:match("[_%w%+%-/%*%^%(%)%%]+") then
			local sym="@A"
			self:compileExpr(sym,ind,name)
			var={dict,"\1"..sym}
		else
			self:pushError("Invalid way to index a dictonary/array!",ind)
		end
	elseif a:match("[%$%w_]+")==a then
		var="\1"..a
	elseif a:match("[%$%w_]-%..-") then
		local dict,sym=a:match("([%w_]-)%.(.+)")
		var={dict,sym,IsALookup=true}
	elseif a:find(",") then
		local list = parseManager.split(a)
		var={}
		for i=1,#list do
			table.insert(var,pieceAssign(list[i],self,name))
		end
	else
		self:pushError("Invalid Syntax, Assignment is invalid!",a)
	end
	return var
end
function parseManager:compileFuncInExpr(list,name)
	local c = 65
	str = list:gsub("([%S]+)%s*%((.-)%)",function(a,b)
		if a and b then
			local d = "$"..string.char(c)
			self:compileFWR(a,d,b,name)
			c=c+1
			return d
		end
	end)
	return str
end
function parseManager:compileAssign(assignA,assignB,name)
	local listA=parseManager.split(assignA)
	local listB=parseManager.split(assignB)
	local assign={
		Type="assign",
		vars={},
		vals={}
	}
	for k=1,#listA do
		local mathTest=false
		local parsetest=false
		self:debug("VAL: "..listB[k])
		self:debug("NAME: "..listA[k])
		if tonumber(listB[k]) then
			assign.vals[#assign.vals+1]=tonumber(listB[k])
		elseif listB[k]:sub(1,1)=="[" and listB[k]:sub(-1,-1)=="]" then
			if listB[k]:match("%[%]") then
				assign.vals[#assign.vals+1]={}
			else
				assign.vals[#assign.vals+1]=pieceList(listB[k]:sub(2,-2),self,name)
			end
		elseif listB[k]:sub(1,1)=="$" and listB[k]:sub(-1,-1)=="$" then
			parsetest = true
			self:compileFWR("__PUSHPARSE",listA[k],'"'..listB[k]..'"',name)
		elseif listB[k]:match("[%w_]-%[.-%]") then
			local dict,sym=listB[k]:match("([%w_]-)%[(.-)%]")
			if tonumber(sym) then
				assign.vals[#assign.vals+1]={"\1"..dict,tonumber(sym),IsALookup=true}
			elseif sym:sub(1,1)=="\"" and sym:sub(-1,-1)=="\"" then
				assign.vals[#assign.vals+1]={"\1"..dict,sym:sub(2,-2),IsALookup=true}
			end
		elseif listB[k]:match("[%w_]-%..-") and not listB[k]:match("(%d-)%.(%d-)") then
			local dict,sym=listB[k]:match("([%w_]-)%.(.+)")
			assign.vals[#assign.vals+1]={"\1"..dict,sym,IsALookup=true}
		elseif listB[k]:sub(1,1)=="\"" and listB[k]:sub(-1,-1)=="\"" then
			assign.vals[#assign.vals+1]=listB[k]:sub(2,-2)
		elseif listB[k]=="true" then
			assign.vals[#assign.vals+1]=true
		elseif listB[k]=="false" then
			assign.vals[#assign.vals+1]=false
		elseif listB[k]:match("[%w_]+")==listB[k] then
			assign.vals[#assign.vals+1]="\1"..listB[k]
		elseif listB[k]:match("[_%$%w%+%-/%*%^%(%)%.%%%s]+")==listB[k] then
			mathTest=true
			workit = self:compileFuncInExpr(listB[k],name)
			self:compileExpr(listA[k],workit,name)
		else
			self:pushError("Invalid Systax:",listB[k])
		end
		if not mathTest and not parsetest then
			assign.vars[#assign.vars+1]=pieceAssign(listA[k],self,name)
		else
			self:debug(assignA,assignB,name)
		end
	end
	table.insert(self.chunks[name],assign)
end
function parseManager:compileCondition(condition,iff,elsee,name)
	self:compileLogic(condition,iff,elsee,name)
end
function parseManager:compileExpr(eql,expr,name)
	local cmds={}
	expr=expr:gsub("([%W])(%-%d)",function(b,a)
		return b.."(0-"..a:match("%d+")..")"
	end)
	local mathAss=1
	function packFunc(l,o,r)
		local l=tonumber(l) or l
		local o=tonumber(o) or o
		local r=tonumber(r) or r
		if type(l)=="string" and l:match("[%w_]") then
			l="\1"..l
		end
		if type(r)=="string" and r:match("[%w_]") then
			r="\1"..r
		end
		if type(o)=="string" and o:match("[%w_]") then
			o="\1"..o
		end
		if l=="@" then
			l=r
			r=""
		end
		if type(l)=="string" then
			if l:find("\3") then
				if type(o)=="number" then
					cmds[#cmds+1]={Func=l:match("\3(.+)"),args={o}}
				else
					if o=="@" then o="" end
					if o=="" then o=nil end
					cmds[#cmds+1]={Func=l:match("\3(.+)"),o}
				end
				return
			end
		end
		if l=="@" then -- Fancy movement of math
			local n=#cmds
			cmds[n]["vars"]={"\1%"..string.char(mathAss+64)}
			l="\1%"..string.char(mathAss+64)
			mathAss=mathAss+1
			cmds[n+1]["vars"]={"\1%"..string.char(mathAss+64)}
			r="\1%"..string.char(mathAss+64)
			mathAss=mathAss+1
		end
		if r=="@" then -- Fancy movement of math
			local n=#cmds
			cmds[n]["vars"]={"\1%"..string.char(mathAss+64)}
			r="\1%"..string.char(mathAss+64)
			mathAss=mathAss+1
			-- cmds[n]["vars"]={"\1%"..string.char(mathAss+64)}
			-- l="\1%"..string.char(mathAss+64)
			-- mathAss=mathAss+1
		end
		if r=="" then
			local n=#cmds
			cmds[n]["vars"]={"\1%"..string.char(mathAss+64)}
			r=l
			l="\1%"..string.char(mathAss+64)
			mathAss=mathAss+1
		end
		if o=="+" then
			cmds[#cmds+1]={Func="ADD",args={l,(r or "")}}
		elseif o=="-" then
			cmds[#cmds+1]={Func="SUB",args={l,(r or "")}}
		elseif o=="/" then
			cmds[#cmds+1]={Func="DIV",args={l,(r or "")}}
		elseif o=="*" then
			cmds[#cmds+1]={Func="MUL",args={l,(r or "")}}
		elseif o=="^" then
			cmds[#cmds+1]={Func="POW",args={l,(r or "")}}
		elseif o=="%" then
			cmds[#cmds+1]={Func="MOD",args={l,(r or "")}}
		else
			self:pushError("Something went wrong!",tostring(l)..","..tostring(o)..","..tostring(r))
		end
	end
	function parseManager:pieceExpr(expr)
		local count=0
		for i,v in pairs(self.methods) do
			expr=expr:gsub(i.."(%b())",function(a)
				a=a:sub(2,-2)
				if a:sub(1,1)=="-" then
					a="0"..a
				end
				packFunc("\3"..i,self:pieceExpr(a))
				return "@"
			end)
		end
		for i,v in pairs(self.cFuncs) do
			expr=expr:gsub(i.."(%b())",function(a)
				a=a:sub(2,-2)
				if a:sub(1,1)=="-" then
					a="0"..a
				end
				packFunc("\3"..i,self:pieceExpr(a))
				return "@"
			end)
		end--self.cFuncs
		expr=expr:gsub("%b()",function(a)
			return self:pieceExpr(a:sub(2,-2))
		end)
		local loop
		for l,o,r in expr:gmatch("(.*)([%+%^%-%*/%%])(.*)") do
			loop=true
			if l:match("[%+%^%-%*/%%]") then
				packFunc(self:pieceExpr(l),o,r)
			else
				packFunc(l,o,r)
			end
		end
		if loop then
			return "@"
		else
			return expr
		end
	end
	if expr:match("[!%$%s&_%w%+%-/%*%.%^%(%)%%]+")==expr then
		expr = expr:gsub("%s","")
		parseManager:pieceExpr(expr)
		cmds[#cmds]["vars"]={"\1"..eql}
		for i=1,#cmds do
			if cmds[i].vars then
				cmds[i].Type="fwr"
			else
				cmds[i].Type="fwor"
			end
			if not name then
				--self:pushError("Unknown Error:",name)
			else
				table.insert(self.chunks[name],cmds[i])
			end
		end
	else
		--self:pushError("Invalid math Expression!",expr)
	end
end
function parseManager:compileFWR(FWR,vars,args,name)
	vars=pieceAssign(vars,self,name)
	if type(vars)=="string" then
		vars={vars}
	end
	table.insert(self.chunks[name],{
		Type="fwr",
		Func=FWR,
		vars=vars,
		args=pieceList(args,self,name),
	})
end
function parseManager:compileFWOR(FWOR,args,name)
	table.insert(self.chunks[name],{
		Type="fwor",
		Func=FWOR,
		args=pieceList(args,self,name),
	})
end
function parseManager:compileLabel(label,name)
	self.chunks[name].labels[label]=#self.chunks[name]+1 -- store this inside the chunk
	table.insert(self.chunks[name],{
		Type="label",
		pos=#self.chunks[name]+1,
		label=label,
	})
end
function parseManager:compileLine(line,name)
	table.insert(self.chunks[name],{
		Type="text",
		text=line
	})
end
function parseManager:compileLogic(condition,iff,elsee,name)
	local cmds={}
	local function pieceLogic(conds)
		conds=conds.." or 1==0"
		conds=conds:gsub(" and ","\4")
		conds=conds:gsub(" or ","\5")
		local count=0
		local mathass=0
		_conds=conds:gsub("%s*\5".."1==0","")
		local cmds={}
		for l,eq,r in conds:gmatch("(.-)([=~!><][=]*)(.-)%s*[\4\5]") do
			charL=string.char(count+65)
			charM=string.char(mathass+65)
			count=count+1
			cmds={
				Type="fwr",
				Func="COMPARE",
				args={[3]=eq},
				vars={"\1!"..charL},
			}
			local l,r=(l:gsub("[\4\5\6]*%(","")),(r:gsub("%)",""))
			if l=="true" then
				cmds.args[1]=true
			elseif l=="false" then
				cmds.args[1]=false
			elseif tonumber(l) then
				cmds.args[1]=tonumber(l)
			elseif l:match("[%w_]+")==l then
				cmds.args[1]="\1"..l
			elseif l:match("[%._%w%+%-/%*%^%(%)%%]+")==l then
				self:compileExpr("&"..charM,l,name)
				cmds.args[1]="\1&"..charM
				mathass=mathass+1
			elseif l:sub(1,1)=="\"" and l:sub(-1,-1) then
				cmds.args[1]=l:sub(2,-2)
			else
				self:pushError("Invalid Syntax in logical expression!",l)
			end
			r=r:gsub("%s*\5".."1==0","")
			charM=string.char(mathass+65)
			if r=="true" then
				cmds.args[2]=true
			elseif r=="false" then
				cmds.args[2]=false
			elseif tonumber(r) then
				cmds.args[2]=tonumber(r)
			elseif r:match("[%w_]+")==r then
				cmds.args[2]="\1"..r
			elseif r:match("[_%w%+%-/%*%^%(%)%%]+")==r then
				self:compileExpr("&"..charM,r,name)
				cmds.args[2]="\1&"..charM
				mathass=mathass+1
			elseif r:sub(1,1)=="\"" and r:sub(-1,-1) then
				cmds.args[2]=r:sub(2,-2)
			else
				self:pushError("Invalid Syntax in logical expression!",r)
			end
			l=l:gsub("%%","%%%%");r=r:gsub("%%","%%%%");l=l:gsub("%+","%%%+");r=r:gsub("%+","%%%+");l=l:gsub("%*","%%%*");r=r:gsub("%*","%%%*");l=l:gsub("%-","%%%-");r=r:gsub("%-","%%%-");l=l:gsub("%^","%%%^");r=r:gsub("%^","%%%^");l=l:gsub("%$","%%%$");r=r:gsub("%$","%%%$");l=l:gsub("%.","%%%.");r=r:gsub("%.","%%%.");l=l:gsub("%[","%%%[");r=r:gsub("%[","%%%[");l=l:gsub("%]","%%%]");r=r:gsub("%]","%%%]");l=l:gsub("%?","%%%?");r=r:gsub("%?","%%%?");l=l:gsub("%(","%%%(");r=r:gsub("%(","%%%(");l=l:gsub("%)","%%%)");r=r:gsub("%)","%%%)")
			_conds=_conds:gsub(l.."%s*"..eq.."%s*"..r,"!"..charL)
			table.insert(self.chunks[name],cmds)
		end
		_conds=_conds:gsub("\4","*")
		_conds=_conds:gsub("\5","+")
		if not _conds:find("%*") and not _conds:find("%+") then
			cmds.vars[1]="\1L$"
		else
			self:compileExpr("L$",_conds,name)
		end
		table.insert(self.chunks[name],{
			Type="fwor",
			Func="CSIM",
			args={"\1L$"},
		})
		FWORi,argsi=iff:match("^([%w_]+)%s*%((.*)%)")
		FWORe,argse=elsee:match("^([%w_]+)%s*%((.*)%)")
		if FWORi=="SKIP" then
			self:compileFWOR(FWORi,tostring(tonumber(argsi)+1),name)
		else
			self:compileFWOR(FWORi,argsi,name)
		end
		self:compileFWOR(FWORe,argse,name)
	end
	pieceLogic(condition)
end
local function trim1(s)
	return (s:gsub("^%s*(.-)%s*$", "%1"))
end
function parseManager:compile(name,ctype,data)
	local isFBlock,FBArgs=ctype:match("(f)unction%((.*)%)")
	--Check if we are dealing with a FBlock
	if isFBlock=="f" then
		self.cFuncs[name]=true
		-- if self.methods[name] then
			-- self:pushError("You cannot create a method with the same name as a standard method or duplicate method names!",name)
		-- end
		self.methods[name]=function(...)
			self:Invoke(name,...)
		end
		self.__INTERNAL[name] = true
		-- if not self.variables.__internal then
			-- self.variables.__internal = {}
		-- end
		-- self.variables.__internal[name] = true
		self.mainENV[name]=self.methods[name]
		table.insert(self.chunks[name],{
			Type="funcblock",
			args=pieceList(FBArgs,self,name)
		})
	end
	self:debug("COMPILING Block: "..name)
	local data=bin.new(data):lines()
	local choiceBlock=false
	local choice={}
	for i=1,#data do
		data[i]=trim1(data[i])
		if data[i]~="" then
			if data[i]:match(".-\"<%s*") then
				choiceBlock=true
				choice={}
				j=0
			end
			if choiceBlock then
				if data[i]:find(">") then
					choiceBlock=false
					table.insert(self.chunks[name],choice)
				else
					dat=data[i]:gsub("<","")
					if j==0 then
						choice.Type="choice"
						choice.prompt=dat:sub(2,-2)
						j=1
					else
						local a,b=dat:match("\"(.-)\"%s*(.+)")
						if b then
							local f,ag=b:match("^([%w_]+)%s*%((.*)%)")
							if ag~="" then
								choice[#choice+1]={a,{
									Type="fwor",
									Func=f,
									args=pieceList(ag,self,name),
								}}
							else
								choice[#choice+1]={a,{
									Type="fwor",
									Func=f,
									args={},
								}}
							end
						end
					end
				end
			else
				local cmd={}
				local Return,RETArgs=data[i]:match("(return)%s*(.*)$")
				local line=data[i]:match("^\"(.+)\"")
				local assignA,assignB=data[i]:match("^([%w,%[%]\"_%(%)%+%-%*%%%./]+)%s*=%s*(.+)")
				local vars,FWR,args=data[i]:match("([\"%[%]%w_,]+)%s*=%s*([%w_]+)%s*%((.*)%)$")
				local FWOR
				if not args then
					FWOR,args=data[i]:match("^([%w_]+)%s*%((.*)%)$")
				end
				local label=data[i]:match("::(.*)::")
				local condition,iff,elsee=data[i]:match("if%s*(.+)%s*then%s*(.-%))%s*|%s*(.+%))")
				------
				local vars2,FWR2,args2=data[i]:match("([%[%]\"%w_,]+)%s*=%s*([%.:%w_]+)%s*%((.*)%)$")
				if not args2 then
					FWOR2,args2=data[i]:match("^([%.:%w_]+)%s*%((.*)%)$")
				end
				------
				if line then
					self:compileLine(line,name)
				elseif condition then
					self:compileCondition(condition,iff,elsee,name)
				elseif FWR then
					self:compileFWR(FWR,vars,args,name)
				elseif FWOR then
					self:compileFWOR(FWOR,args,name)
				elseif FWR2 then
					local dict,dot,sym=FWR2:match("([%w_]-)([%.:])(.+)")
					if dot==":" then
						args2=dict..","..args2
					end
					self:compileFWR({dict,sym,IsALookup=true},vars2,args2,name)
				elseif FWOR2 then
					local dict,dot,sym=FWOR2:match("([%w_]-)([%.:])(.+)")
					if dot==":" then
						args2=dict..","..args2
					end
					self:compileFWOR({dict,sym,IsALookup=true},args2,name)
				elseif assignA then
					self:compileAssign(assignA,assignB,name)
				elseif label then
					self:compileLabel(label,name)
				elseif Return and isFBlock then
					table.insert(self.chunks[name],{
						Type="return",
						RETArgs=pieceList(RETArgs,self,name)
					})
				elseif Return and not(isFBlock) then
					self:pushError("Attempt to call return in a non function block!",data[i])
				else
					table.insert(self.chunks[name],{
						Type="customdata",
						data=data[i],
					})
				end
			end
		end
	end
end
function parseManager:testDict(dict)
	if type(dict[1])=="string" then
		if dict[1]:sub(1,1)=="\1" and dict.IsALookup then
			return true
		end
	else
		return
	end
end
function parseManager:dataToValue(name,envF,b) -- includes \1\
	envF=envF or self.currentENV
	local tab=name
	if type(name)=="string" then
		if tonumber(name) then return tonumber(name) end
		local ret
		if name:sub(1,1)=="\1" then
			return self:parseHeader(envF[name:sub(2)])
		elseif b then
			return self:parseHeader2(name)
		else
			return self:parseHeader(name)
		end
	elseif type(name)=="table" then
		if name.__index then
			return name
		end
		if self:testDict(name) then
			return envF[name[1]:sub(2,-1)][self:dataToValue(name[2],envF)]
		else
			tab={}
			for i=1,#name do
				tab[i]=self:dataToValue(name[i],envF)
			end
		end
	end
	return tab or {}
end
function parseManager:define(t)
	for i,v in pairs(t) do
		self.methods[i]=v
	end
end
function push(s,n)
	table.insert(s,n)
end
function pop(s)
	return table.remove(s)
end
function peek(s)
	return s[#s]
end
function parseManager:Invoke(func,vars,...)
	local name=func
	local func=self.chunks[func]
	if func then
		if func.type:sub(1,1)=="f" then
			local returndata={}
			self.fArgs={...}
			if #self.fArgs==0 then
				self.fArgs={self.lastCall}
			end
			push(self.stack,{chunk=self.currentChunk,pos=self.currentChunk.pos,env=self.currentENV,vars=vars})
			self.currentENV = self:newENV()
			self.methods.JUMP(self,name)
			return
		else
			self:pushError("Attempt to call a non function block!",name)
		end
	else
		self:pushError("Attempt to call a non existing function!",name)
	end
end
function round(num, numDecimalPlaces)
	local mult = 10^(numDecimalPlaces or 0)
	return math.floor(num * mult + 0.5) / mult
end
function parseManager:parseHeader2(data)
	dat = data:sub(2,-2)
	if dat:find(":") and not dat:find("%[") then
		local var,num = dat:match("(.-):(.+)")
		local num = tonumber(num)
		if type(self.currentENV[var])=="number" then
			return round(self.currentENV[var],num)
		else
			self:pushError("Attempt to round a non number!")
		end
	elseif dat:find("%[") then
		if not type(self.currentENV[dat])=="table" then
			self:pushError("Attempt to index a non table object!")
			return
		else
			if dat:find(":") then
				local var,inwards = dat:match("(.-)%[(.+)%]")
				local ind = parseManager.split(inwards,":")
				if #ind==2 then
					local a,b = tonumber(ind[1]),tonumber(ind[2])
					if b <= #self.currentENV[var] then
						local str={}
						for i=1,b do
							table.insert(str,self.currentENV[var][i])
						end
						return str
					else
						self:pushError("Attempt to index a table at a non existing location!")
					end
				end
			else
				local var,inwards = dat:match("(.-)%[(.+)%]")
				local num = tonumber(inwards)
				local ind = self.currentENV[inwards]
				local sind = self.currentENV[var][inwards]
				if num then
					return self.currentENV[var][num]
				elseif ind then
					return self.currentENV[var][ind]
				elseif sind then
					return sind
				else
					self:pushError("Invalid index: "..inwards.."!")
				end
			end
		end
	else
		-- regular strings
		self:debug("PARSE DATA: "..tostring(self.currentENV[dat]))
		if self.currentENV[dat]~=nil then
			if type(self.currentENV[dat])=="table" then
				local str={}
				for i=1,#self.currentENV[dat] do
					table.insert(str,self.currentENV[dat][i])
				end
				return str
			else
				return self.currentENV[dat]
			end
		else
			return nil
		end
	end
end
function parseManager:parseHeader(data)
	if type(data)=="string" then
		data=data:gsub("%$([%w_,:%.%[%]%-\"']+)%$",function(dat)
			self:debug("PARSE: "..dat)
			if dat:find(":") and not dat:find("%[") then
				local var,num = dat:match("(.-):(.+)")
				local num = tonumber(num)
				if type(self.currentENV[var])=="number" then
					local str = ""
					local n = num
					num = round(self.currentENV[var],num)
					if n>0 and math.floor(num)==num then -- This only for string version
						str = "."..string.rep("0",n)
					elseif n>0 then
						local s = tostring(num)
						str = string.rep("0",n-(#s-s:find("%.")))
					end
					return num..str
				else
					self:pushError("Attempt to round a non number!")
				end
			elseif dat:find("%[") then
				if not type(self.currentENV[dat])=="table" then
					self:pushError("Attempt to index a non table object!")
					return
				else
					if dat:find(":") then
						local var,inwards = dat:match("(.-)%[(.+)%]")
						local ind = parseManager.split(inwards,":")
						if #ind==2 then
							local a,b = tonumber(ind[1]),tonumber(ind[2])
							if b <= #self.currentENV[var] then
								local str=""
								for i=1,b do
									str=str..tostring(self.currentENV[var][i])..","
								end
								str=str:sub(1,-2)
								return "["..str.."]"
							else
								self:pushError("Attempt to index a table at a non existing location!")
							end
						end
					else
						local var,inwards = dat:match("(.-)%[(.+)%]")
						local num = tonumber(inwards)
						local ind = self.currentENV[inwards]
						local sind = self.currentENV[var][inwards]
						if num then
							return tostring(self.currentENV[var][num])
						elseif ind then
							return tostring(self.currentENV[var][ind])
						elseif sind then
							return tostring(sind)
						else
							self:pushError("Invalid index: "..inwards.."!")
						end
					end
				end
			else
				-- regular strings
				self:debug("PARSE DATA: "..tostring(self.currentENV[dat]))
				if self.currentENV[dat]~=nil then
					if type(self.currentENV[dat])=="table" then
						local str=""
						for i=1,#self.currentENV[dat] do
							str=str..tostring(self.currentENV[dat][i])..","
						end
						str=str:sub(1,-2)
						return "["..str.."]"
					else
						return tostring(self.currentENV[dat])
					end
				else
					return "nil"
				end
			end
		end)
	end
	return data
end
function parseManager:pairAssign(vars,vals,envF)
	for i=1,#vars do
		self:debug("ASSIGN NAME: "..tostring(vars[i]))
		self:debug("ASSIGN DATA: "..tostring(self:dataToValue(vals[i],envF)))
		if type(vars[i])=="table" then
			if type(self.currentENV[vars[i][1]])~="table" then
				self:pushError("Attempt to index a non table object:",vars[i][1].."[\""..vars[i][2].."\"]")
			end
			self.currentENV[vars[i][1]][self:dataToValue(vars[i][2])]=self:dataToValue(vals[i],envF)
		else
			self.currentENV[vars[i]:sub(2,-1)]=self:dataToValue(vals[i],envF)
		end
	end
end
function parseManager:next(block,choice)
	if self.entry then
		block = block or self.entry
		self.entry = nil
	end
	local chunk = self.currentChunk or self.chunks[block] or self.chunks["START"]
	self.currentChunk=chunk
	if choice then
		local c=self.choiceData[choice][2]
		local args=self:dataToValue(c.args)
		if not self.methods[c.Func] then
			self.lastCall=self:Invoke(c.Func,"lastCall",unpack(args))
		else
			self.lastCall=self.methods[c.Func](self,unpack(args))
		end
		return {Type="method"}
	end
	local ret
	local data=chunk[chunk.pos]
	if not data then return end
	if data.Type=="label" then
		chunk.pos=chunk.pos+1
		data=chunk[chunk.pos]
	end
	chunk.pos=chunk.pos+1
	self:debug("TYPE: "..data.Type)
	if data.Type=="text" then
		self.lastCall=nil
		return {Type="text",text=self:parseHeader(data.text)}
	elseif data.Type=="funcblock" then
		local env=self.currentENV
		self.currentENV=self:newENV()
		self:pairAssign(data.args,self.fArgs,env)
		return {Type="FBLOCK"}
	elseif data.Type=="return" then
		local obj=pop(self.stack)
		local chunk=obj.chunk
		local pos=obj.pos
		local env=obj.env
		local vars=obj.vars
		local name=chunk.name
		local env=self.currentENV
		chunk.pos=pos
		self.currentENV=env
		self:pairAssign(vars,data.RETArgs,env)
		self.currentChunk=chunk
		return {Type="method"}
	elseif data.Type=="fwr" then
		local args=self:dataToValue(data.args,nil,data.Func == "__PUSHPARSE")
		local rets={}
		local Func
		local Ext=false
		if type(data.Func)=="table" then
			Ext=true
			Func=self.currentENV[data.Func[1]][data.Func[2]]
		else
			Func=self.methods[data.Func]
		end
		if Ext then
			rets={Func(unpack(args))}
		elseif self.__INTERNAL[data.Func] then
			self:Invoke(data.Func,data.vars,unpack(args))
		else
			if type(Func)~="function" then
				rets={self:Invoke(data.Func,data.vars,unpack(args))}
				return {Type="method"}
			else
				rets={Func(self,unpack(args))}
			end
		end
		if #rets~=0 then
			self:pairAssign(data.vars,rets)
		end
		self.lastCall=nil
		return {Type="method"}
	elseif data.Type=="fwor" then
		local args=self:dataToValue(data.args)
		local Func
		local Ext=false
		if type(data.Func)=="table" then
			Ext=true
			Func=self.currentENV[data.Func[1]][data.Func[2]]
		else
			Func=self.methods[data.Func]
		end
		if Ext then
			self.lastCall=Func(unpack(args))
		else
			if type(Func)~="function" then
				self.lastCall=self:Invoke(data.Func,"lastCall",unpack(args))
				return {Type="method"}
			else
				self.lastCall=Func(self,unpack(args))
			end
		end
		return {Type="method"}
	elseif data.Type=="choice" then
		self.choiceData=data
		local CList={}
		for i=1,#data do
			CList[#CList+1]=self:parseHeader(data[i][1])
		end
		self.lastCall=nil
		return {Type="choice",prompt=self:parseHeader(data.prompt),CList}
	elseif data.Type=="assign" then
		self:pairAssign(data.vars,data.vals)
		self.lastCall=nil
		return {Type="assign"}
	else
		self.lastCall=nil
		return {Type="Custom Syntax"}
	end
	return rets
end
require("parseManager.standardDefine")
