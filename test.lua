package.path="?/init.lua;lua/?/init.lua;lua/?.lua;"..package.path
local bin = require("bin")
local multi = require("multi")
require("parseManager")
test=parseManager:compileToFile("test.dms","test.dmsc")--load("StoryTest/init.dms")
--~ test = parseManager:loadCompiled("test.dmsc")
print(test:dump())
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
		print(t.prompt)
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
