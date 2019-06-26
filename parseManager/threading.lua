if parseManager.threadingLoaded then return false end
local multi, bin, GLOBAL,sThread
local loaded, err = pcall(function()
	multi = require("multi")
	local plat = multi:getPlatform()
	if plat == "lanes" then
		GLOBAL, sThread = require("multi.integration.lanesManager").init()
	elseif plat == "love2d" then
		GLOBAL, sThread = require("multi.integration.loveManager").init()
	end
	bin = require("bin")
end)
function parseManager:threading()
	parseManager.threadingLoaded = true
	if not loaded then self:pushWarning("Could not load the threading module!") print(err) end
	local tc = 1
	self.mainENV=GLOBAL
	self.currentENV=GLOBAL
	self:define{
		WATCH=function(self,...)
			if self.watchvars then return end
			self.watchvars = {...}
		end,
		newThread = function(self,block,name)
			multi:newSystemThread(name or "NewThread"..tc,function(blck,path,name)
				local bin = require("bin")
				local multi = require("multi")
				require("parseManager")
				if multi:getPlatform()=="love2d" then
					GLOBAL=_G.GLOBAL
					sThread=_G.sThread
				end
				local test=parseManager:load(path)
				test.entry = blck
				test.mainENV = GLOBAL
				test.currentENV = GLOBAL
				test:define{
					sleep = function(self,n)
						thread.sleep(n)
					end,
					title = function(self,t)
						os.execute("title "..t)
					end
				}
				local active = true
				multi:newThread("Thread",function()
					while active do
						test:think()
					end
				end)
				multi:mainloop()
			end,block,self.currentChunk.path,name or "NewThread"..tc)
			tc=tc+1
		end,
	}
end
multi.OnError(function(...)
	print(...)
end)
