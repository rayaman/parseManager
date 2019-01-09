package.path="?/init.lua;lua/?/init.lua;lua/?.lua;"..package.path
local bin = require("bin")
--~ local multi = require("multi")
require("parseManager")
require("bit")
--~ parseManager:define({
--~ 	rshift=function(self,a,b)
--~ 		return bit.rshift(a,b)
--~ 	end,
--~ 	lshift=function(self,a,b)
--~ 		return bit.lshift(a,b)
--~ 	end,
--~ 	testfunc=function(self,a,b,c)
--~ 		print(tostring(a).." "..tostring(b).." "..tostring(c))
--~ 	end
--~ })
test=parseManager:load("textadventure.dms")
print(test:dump())
t=test:next()
while true do
	if not t then break end
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
		print(t.text)
		for i=1,#t.choices do
			print(i..". "..t.choices[i])
		end
		io.write("Choose#: ")
		cm=tonumber(io.read())
		t=test:next(nil,cm,nil,t)
	elseif t.Type=="end" then
		if t.text=="leaking" then -- go directly to the block right under the current block if it exists
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
--["vars"]={"\1%"..string.char(mathAss+64)}
--cmds[#cmds+1]={Func="MOD",args={l,(r or "")}}
--
