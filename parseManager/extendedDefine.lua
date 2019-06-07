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
function parseManager:extendedDefine()
	if not loaded then self:pushWarning("Could not load the extendedDefine module!") print(err) end
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
				t=test:next(blck)
				multi:newThread(name,function()
					while true do
						thread.skip(0)
						if not t then error("Thread ended!") end
						if t.Type=="text" then
							log(t.text,name)
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
							t=test:next(nil,math.random(1,#t.choices),nil,t)
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
