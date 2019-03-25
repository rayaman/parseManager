package.path="?/init.lua;lua/?/init.lua;lua/?.lua;"..package.path
local bin = require("bin")
local multi = require("multi")
require("parseManager")
test=parseManager:load("test.dms")--load("StoryTest/init.dms")
print(test:dump())
--Code would happen here anyway
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
