local bin = require("bin")
local clock = os.clock
parseManager:define{
	__PUSHPARSE = function(self,dat)
		return dat
	end,
	getInput = function(self,prompt)
		if prompt then
			io.write(prompt)
		end
		return io.read()
	end,
	print=function(self,...)
		_print(...)
	end,
	WATCH=function(self,...)
		if self.watchvars then return end
		self.watchvars = {...}
	end,
	SAVE=function(self,fn)
		local file = bin.new()
		local data = {}
		for i=1,#self.watchvars do
			data[self.watchvars[i]] = self.currentENV[self.watchvars[i]]
		end
		data["__CHUNK"] = self.methods.getCurrentChunk(self)
		data["__POSITION"] = self.methods.getCurrentPosition(self)
		file:addBlock(data)
		file:tofile(fn or "save.dat")
	end,
	LOAD=function(self,fn)
		if not bin.fileExists(fn or "save.dat") then return false end
		local file = bin.load(fn or "save.dat")
		t = file:getBlock("t")
		local c,p = t.__CHUNK,t.__POSITION
		t.__CHUNK,t.__POSITION = nil,nil
		for i,v in pairs(t) do
			self.mainENV[i] = v
		end
		if self.stats.statesave then
			self.methods.JUMP(self,c, p)
		end
		return true,c,p
	end,
	EXECUTE = function(self,cmd)
		os.execute(cmd)
	end,
	error=function(self,msg)
		self:pushError(msg,"\2")
	end,
	setGlobalVar=function(self,var,val)
		self.mainENV[var]=val
	end,
	getGlobalVar=function(self,var,val)
		self.mainENV[var]=val
	end,
	len=function(self,t)
		return #t
	end,
	QUIT=function()
		os.exit()
	end,
	getCurrentChunk = function(self)
		for i,v in pairs(self.chunks) do
			if self.currentChunk == v then
				return i
			end
		end
	end,
	getCurrentPosition = function(self)
		return self.currentChunk.pos-1
	end,
	sleep=function(self,n)
		local t0 = clock()
		while clock() - t0 <= n do end
	end,
	JUMP=function(self,block,pos)
		if self.chunks[block] then
			self.chunks[block].pos=pos or 1
			self.currentChunk=self.chunks[block]
		else
			self:pushError("Attempt to jump to a non existing block:","\2")
		end
	end,
	SKIP=function(self,n)
		if type(n)~="number" then self:pushError("Number expected got: "..type(n),"SKIP( ? )") end
		self.currentChunk.pos=self.currentChunk.pos+n
	end,
	GOTO=function(self,label)
		if self.currentChunk.labels[label] then
			self.currentChunk.pos=self.currentChunk.labels[label]
		else
			self:pushError("Attempt to goto a non existing label:","\2")
		end
	end,
	GOTOE=function(self,label)
		local chunks=self.chunks
		for i,v in pairs(chunks) do
			if chunks[i].labels[label] then
				self.currentChunk=chunks[i]
				self.currentChunk.pos=chunks[i].labels[label]
				return
			end
		end
		self:pushError("Attempt to goto a non existing label:","\2")
	end,
	ADD=function(self,a,b)
		if type(self.lastCall)=="number" and type(a)=="number" then
			return self.lastCall+a
		elseif type(a)=="number" and type(b)=="number" then
			return a+b
		else
			self:pushError("Invalid Arguments!","ADD("..tostring(a)..","..tostring(b)..")")
		end
	end,
	SUB=function(self,a,b)
		if type(self.lastCall)=="number" and type(a)=="number" then
			return self.lastCall-a
		elseif type(a)=="number" and type(b)=="number" then
			return a-b
		else
			self:pushError("Invalid Arguments!","SUB("..tostring(a)..","..tostring(b)..")")
		end
	end,
	MUL=function(self,a,b)
		if type(self.lastCall)=="number" and type(a)=="number" then
			return self.lastCall*a
		elseif type(a)=="number" and type(b)=="number" then
			return a*b
		else
			self:pushError("Invalid Arguments!","MUL("..tostring(a)..","..tostring(b)..")")
		end
	end,
	DIV=function(self,a,b)
		if type(self.lastCall)=="number" and type(a)=="number" then
			return self.lastCall/a
		elseif type(a)=="number" and type(b)=="number" then
			return a/b
		else
			self:pushError("Invalid Arguments!","DIV("..tostring(a)..","..tostring(b)..")")
		end
	end,
	POW=function(self,a,b)
		if type(self.lastCall)=="number" and type(a)=="number" then
			return self.lastCall^a
		elseif type(a)=="number" and type(b)=="number" then
			return a^b
		else
			self:pushError("Invalid Arguments!","POW("..tostring(a)..","..tostring(b)..")")
		end
	end,
	sqrt=function(self,a)
		if type(self.lastCall)=="number" then
			return math.sqrt(self.lastCall)
		elseif type(a)=="number" then
			return math.sqrt(a)
		else
			self:pushError("Invalid Arguments!","\2")
		end
	end,
	cos=function(self,a)
		if type(self.lastCall)=="number" then
			return math.cos(self.lastCall)
		elseif type(a)=="number" then
			return math.cos(a)
		else
			self:pushError("Invalid Arguments!","\2")
		end
	end,
	sin=function(self,a)
		if type(self.lastCall)=="number" then
			return math.sin(self.lastCall)
		elseif type(a)=="number" then
			return math.sin(a)
		else
			self:pushError("Invalid Arguments!","\2")
		end
	end,
	tan=function(self,a)
		if type(self.lastCall)=="number" then
			return math.tan(self.lastCall)
		elseif type(a)=="number" then
			return math.tan(a)
		else
			self:pushError("Invalid Arguments!","\2")
		end
	end,
	log=function(self,a)
		if type(self.lastCall)=="number" then
			return math.log(self.lastCall)
		elseif type(a)=="number" then
			return math.log(a)
		else
			self:pushError("Invalid Arguments!","\2")
		end
	end,
	acos=function(self,a)
		if type(self.lastCall)=="number" then
			return math.acos(self.lastCall)
		elseif type(a)=="number" then
			return math.acos(a)
		else
			self:pushError("Invalid Arguments!","\2")
		end
	end,
	tanh=function(self,a)
		if type(self.lastCall)=="number" then
			return math.tanh(self.lastCall)
		elseif type(a)=="number" then
			return math.tanh(a)
		else
			self:pushError("Invalid Arguments!","\2")
		end
	end,
	deg=function(self,a)
		if type(self.lastCall)=="number" then
			return math.deg(self.lastCall)
		elseif type(a)=="number" then
			return math.deg(a)
		else
			self:pushError("Invalid Arguments!","\2")
		end
	end,
	cosh=function(self,a)
		if type(self.lastCall)=="number" then
			return math.cosh(self.lastCall)
		elseif type(a)=="number" then
			return math.cosh(a)
		else
			self:pushError("Invalid Arguments!","\2")
		end
	end,
	sinh=function(self,a)
		if type(self.lastCall)=="number" then
			return math.sinh(self.lastCall)
		elseif type(a)=="number" then
			return math.sinh(a)
		else
			self:pushError("Invalid Arguments!","\2")
		end
	end,
	randomseed=function(self,a)
		if type(self.lastCall)=="number" then
			return math.randomseed(self.lastCall)
		elseif type(a)=="number" then
			return math.randomseed(a)
		else
			self:pushError("Invalid Arguments!","\2")
		end
	end,
	random = function(self,a,b)
		return math.random(a,b)
	end,
	ceil=function(self,a)
		if type(self.lastCall)=="number" then
			return math.ceil(self.lastCall)
		elseif type(a)=="number" then
			return math.ceil(a)
		else
			self:pushError("Invalid Arguments!","\2")
		end
	end,
	floor=function(self,a)
		if type(self.lastCall)=="number" then
			return math.floor(self.lastCall)
		elseif type(a)=="number" then
			return math.floor(a)
		else
			self:pushError("Invalid Arguments!","\2")
		end
	end,
	rad=function(self,a)
		if type(self.lastCall)=="number" then
			return math.rad(self.lastCall)
		elseif type(a)=="number" then
			return math.rad(a)
		else
			self:pushError("Invalid Arguments!","\2")
		end
	end,
	abs=function(self,a)
		if type(self.lastCall)=="number" then
			return math.abs(self.lastCall)
		elseif type(a)=="number" then
			return math.abs(a)
		else
			self:pushError("Invalid Arguments!","\2")
		end
	end,
	asin=function(self,a)
		if type(self.lastCall)=="number" then
			return math.asin(self.lastCall)
		elseif type(a)=="number" then
			return math.asin(a)
		else
			self:pushError("Invalid Arguments!","\2")
		end
	end,
	log10=function(self,a)
		if type(self.lastCall)=="number" then
			return math.log10(self.lastCall)
		elseif type(a)=="number" then
			return math.log10(a)
		else
			self:pushError("Invalid Arguments!","\2")
		end
	end,
	atan2=function(self,a)
		if type(self.lastCall)=="number" then
			return math.atan2(self.lastCall)
		elseif type(a)=="number" then
			return math.atan2(a)
		else
			self:pushError("Invalid Arguments!","\2")
		end
	end,
	exp=function(self,a)
		if type(self.lastCall)=="number" then
			return math.exp(self.lastCall)
		elseif type(a)=="number" then
			return math.exp(a)
		else
			self:pushError("Invalid Arguments!","\2")
		end
	end,
	atan=function(self,a)
		if type(self.lastCall)=="number" then
			return math.atan(self.lastCall)
		elseif type(a)=="number" then
			return math.atan(a)
		else
			self:pushError("Invalid Arguments!","\2")
		end
	end,
	max=function(self,a,b)
		if type(self.lastCall)=="number" and type(a)=="number" then
			return max(self.lastCall,a)
		elseif type(a)=="number" and type(b)=="number" then
			return max(a,b)
		else
			self:pushError("Invalid Arguments!","\2")
		end
	end,
	mod=function(self,a,b)
		if type(self.lastCall)=="number" and type(a)=="number" then
			return mod(self.lastCall,a)
		elseif type(a)=="number" and type(b)=="number" then
			return mod(a,b)
		else
			self:pushError("Invalid Arguments!","\2")
		end
	end,
	COMPARE=function(self,v1,v2,sym)
		if sym==nil then self:pushError("Unexpected Error has occurred!","non-existing variable!") end
		if sym=="==" then
			if v1==v2 then return 1 else return 0 end
		elseif sym==">=" then
			if v1 == nil or v2 == nil then
				self:pushError("Conditional mathematical args are non-existing!")
			end
			if v1>=v2 then return 1 else return 0 end
		elseif sym=="<=" then
			if v1 == nil or v2 == nil then
				self:pushError("Conditional mathematical args are non-existing!")
			end
			if v1<=v2 then return 1 else return 0 end
		elseif sym==">" then
			if v1 == nil or v2 == nil then
				self:pushError("Conditional mathematical args are non-existing!")
			end
			if v1>v2 then return 1 else return 0 end
		elseif sym=="<" then
			if v1 == nil or v2 == nil then
				self:pushError("Conditional mathematical args are non-existing!")
			end
			if v1<v2 then return 1 else return 0 end
		elseif sym=="~=" or sym=="!=" then
			if v1 == nil or v2 == nil then
				self:pushError("Conditional mathematical args are non-existing!")
			end
			if v1~=v2 then return 1 else return 0 end
		else
			self:pushError("Invalid Symbol!",sym)
		end
	end,
	CSIM=function(self,i)
		if i==0 then
			self.methods.SKIP(self,1)
		end
	end,
}
