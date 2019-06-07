package.path="?/init.lua;lua/?/init.lua;lua/?.lua;"..package.path
package.cpath="?.dll;"..package.cpath
local bin = require("bin")
local multi = require("multi")
require("parseManager")
require("multi")
test=parseManager:load("test.dms")--parseManager:compileToFile("test.dms","test.dmsc")--
test:define{
	external = function()
		return multi
	end
}
--~ test = parseManager:loadCompiled("test.dmsc")
function parseManager:Call(func,...)
	local env = {}
	local temp = parseManager:load(self.path)
--~ 	local temp = {}
--~ 	setmetatable(temp,{__index = self})
	temp.fArgs = {...}
	local t = temp:next(func)
	while t do
		if t.Type=="text" then
			io.write(t.text.."\n")
			t=temp:next()
		elseif t.Type=="condition" then
			t=temp:next()
		elseif t.Type=="assignment" then
			t=temp:next()
		elseif t.Type=="label" then
			t=temp:next()
		elseif t.Type=="method" then
			env = temp:dataToEnv(t.RetArgs)
			t=temp:next()
		elseif t.Type=="choice" then
			_print(t.prompt)
			io.write("Choose#: ")
			cm=tonumber(1,#t[1])
			t=temp:next(nil,cm)
		elseif t.Type=="end" then
			print("Something went wrong!")
		elseif t.Type=="error" then
			error(t.text)
		else
			t=temp:next()
		end
	end
	return unpack(env)
end
--~ print(test.methods.DoMe(test,1,2))
t=test:next()
while t do
	if t.Type=="text" then
		io.write(t.text)
		io.read()
		t=test:next()
	elseif t.Type=="condition" then
		t=test:next()
	elseif t.Type=="assignment" then
		t=test:next()
	elseif t.Type=="label" then
		t=test:next()
	elseif t.Type=="method" then
		t=test:next()
	elseif t.Type=="choice" then
		_print(t.prompt)
		for i=1,#t[1] do
			print(i..". "..t[1][i])
		end
		io.write("Choose#: ")
		cm=tonumber(io.read())
		t=test:next(nil,cm)
	elseif t.Type=="end" then
		if t.text=="leaking" then
			t=test:next()
		else
			os.exit()
		end
	elseif t.Type=="error" then
		error(t.text)
	else
		t=test:next()
	end
end
multi:mainloop{
	protect = true
}
