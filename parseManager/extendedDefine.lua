function parseManager:extendedDefine()
	self:define{
		newThread = function()
			-- We allow for thread creation
		end,
		testfunc = function()
			print("It worked")
		end,
	}
end
