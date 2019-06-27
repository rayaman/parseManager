package.path="?/init.lua;lua/?/init.lua;lua/?.lua;"..package.path
package.cpath="?.dll;"..package.cpath
local bin = require("bin")
local multi = require("multi")
require("parseManager")
require("multi")
test=parseManager:load("audiotest.dms")--parseManager:compileToFile("test.dms","test.dmsc")--
test:define{
	external = function(self)
		return multi
	end,
	tester = function()
		print("!")
	end
}
parseManager.print(test:dump())
print(test:dump())
local active = true
while active do
	active = test:think()
end
