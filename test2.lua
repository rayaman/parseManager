--~ local GLOBAL, sThread = require("multi.integration.lanesManager").init()
--~ GLOBAL["Test"]=true
--~ multi:newSystemThread("NewThread",function(blck,path,name)
--~ 	print(GLOBAL["Test"])
--~ end)
--~ io.flush()
--~ i = io.input()
--~ i:seek("cur")
--~ i:read(2)
--~ print(i)
--~ g={}
--~ while t~="q" do
--~ 	g[#g+1]=t
--~ 	io.flush()
--~ 	t=io.read(1)
--~ 	io.write("\b")
--~ end
--~ print("done")
--~ io.write("\b")
--~ io.flush()
--~ io.read()
bool = true
function test()
	local t = {}
	return bool and t
end
print(test())
