package.path="?/init.lua;lua/?/init.lua;lua/?.lua;"..package.path
local bin = require("bin")
local multi = require("multi")
require("parseManager")
require("bit")
test=parseManager:load("test.dms")
print(test:dump())
--Code would happen here anyway
local runner = function(block,t)
	if not t then return nil end
	if t.Type=="text" then
		io.write(t.text)
		io.read()
		t=self:next()
	elseif t.Type=="condition" then
		t=self:next()
	elseif t.Type=="assignment" then
		t=self:next()
	elseif t.Type=="label" then
		t=self:next()
	elseif t.Type=="method" then
		t=self:next()
	elseif t.Type=="choice" then
		print(t.text)
		for i=1,#t.choices do
			print(i..". "..t.choices[i])
		end
		io.write("Choose#: ")
		cm=tonumber(io.read())
		t=self:next(nil,cm,nil,t)
	elseif t.Type=="end" then
		if t.text=="leaking" then -- go directly to the block right under the current block if it exists
			t=self:next()
		else
			os.exit()
		end
	elseif t.Type=="error" then
		error(t.text)
	else
		t=self:next()
	end
	return  t
end
test.mainRunner = runner
test.active = false
multi:newThread("Parse Manager Main State",function()
	local dat = self:mainRunner(nil,self:next())
	while dat do
		thread.skip()
		dat = self:mainRunner(nil,dat)
	end
end)
function test:run()
	multi:mainloop()
end
test:define{
	sleep = function(self,n)
		thread.sleep(n)
	end,
	newLightThread = function(self,block)
		local state = parseManager:load(self.currentChunk.path)
		state.mainENV = self.mainENV
		state.mainRunner = runner
		multi:newThread("Parse Manager State",function()
			local dat = state:mainRunner(nil,state:next())
			while dat do
				thread.skip()
				dat = state:mainRunner(nil,dat)
			end
		end)
	end
}
--End of injecting
--~ test:run()
multi:newThread("",function()
	print("Threading works")
end)
multi:mainloop()
