function table.print(tbl, indent)
	if type(tbl)~="table" then return end
	if not indent then indent = 0 end
	for k, v in pairs(tbl) do
		formatting = string.rep('  ', indent) .. k .. ': '
		if type(v) == 'table' then
			print(formatting)
			table.print(v, indent+1)
		else
			print(formatting .. tostring(v))
		end
	end
end
local special = {["("]=true,[")"]=true,["+"]=true,["-"]=true,["/"]=true,["*"]=true,["%"]=true,["^"]=true}
function parse(e)
	local cmds = {}
	local state = 0
	local group = ""
	local nonSP = false
	local wasNum = false
	for i in e:gmatch(".") do
		if state == 0 then
			if i==" " then
				--
			elseif i=="(" and nonSP then
--~ 				state = 1
				nonSP = false
				cmds[#cmds+1] = {Type="fwor",Func=group,args={{Type="ref",ref=true}}}
				group = ""
				cmds[#cmds+1]=i
			elseif i == "(" and wasNum and not nonSP then
				wasNum = false
				cmds[#cmds+1] = {Type="fwor",Func="MUL",args={{Type="const",val=group},{Type="ref",ref=true}}}
				group = ""
				cmds[#cmds+1]=i
			elseif tostring(tonumber(i))==i or i=="." then
				wasNum = true
				group = group .. i
			elseif special[i] then
				if not(group=="") and (nonSP or not wasNum) then
					cmds[#cmds+1] = {Type="var",data = group}
					group = ""
					cmds[#cmds+1]=i
				else
					if group~="" then
						cmds[#cmds+1] = group
						group = ""
						cmds[#cmds+1]=i
						nonSP = false
					else
						cmds[#cmds+1]=i
						nonSP = false
					end
				end
			else
				nonSP = true
				group = group .. i
			end
		elseif state == 1 then
			if i==")" then
				cmds[#cmds+1]=parse(group)
				group = ""
				state = 0
			else
				group = group .. i
			end
		end
	end
	if nonSP or not wasNum then
		cmds[#cmds+1] = {Tpye="const",data = group}
	else
		cmds[#cmds+1] = group
	end
	if cmds[1]=="" then table.remove(cmds,1) end
	if cmds[#cmds]=="" then table.remove(cmds) end
	return cmds
end
------------------
expr = "test(2.4+20)/sqrt(100) + food"
c=parse(expr)
table.print(c)
