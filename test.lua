package.path="?/init.lua;lua/?/init.lua;lua/?.lua;"..package.path
require("bin")
require("multi.all")
require("parseManager")
--~ require("Library")
require("bit")
parseManager:define({
	rshift=function(self,a,b)
		return bit.rshift(a,b)
	end,
	lshift=function(self,a,b)
		return bit.lshift(a,b)
	end,
	testfunc=function(self,a,b,c)
		print("> "..tostring(a).." "..tostring(b).." "..tostring(c))
	end
})
test=parseManager:load("parsetest2.txt")
t=test:start()
while true do
	if t.Type=="text" then
		print(t.text)
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
