# parseManager

A module for making advance config files. This library depends on my multi library and my bin library

Here is an example, this would be its own file called parsetest.txt
```lua
ENTRY START
ENABLE forseelabels
DISABLE leaking
ENABLE customcommands -- WIP
USING EBIM -- Allows for multilined commands
[START]{
	--Defualt enviroment is the GLOBAL one, you can create and swap between them whenever you want. You can have as many as you want as well
	a=100
	b=7
	c=21
	"$a$ $b$ $c$"
	env=createENV()
	setENV(env)
	a=15
	b=150
	"$a$ $b$ $c$"
	env=getENV("GLOBAL")
	setENV(env)
	"$a$ $b$ $c$"
	test=a<-env -- get var a from an env and set it to test
	"Test $test$"
	test=51
	a=test->env  -- set var a in env to test
	"$a$ $b$ $c$"
	setENV(env) -- lets go back to the modified enviroment
	"$a$ $b$ $c$"
	test2=stringLEN("$a$ $b$ $c$")
	"Test2 $test2$"
	string test5: -- no need for quotes, everything in the block is considered a string... Also no escaping is needed; however, endstring is not useable as a part of the string...
		Yo I am able to make a multilined string if i want
		Now I am at the next line lol!
	endstring
	list test6: -- create a multilined list
		"elem1"
		2
		3
		true
		false
		"elem6"
		env
	endlist
	dict test7:
		name: "Ryan"
		age: 21
		job: "BUM"
		list: test6
	enddict
	"Test5 $test5$"
	list=[1,2,3,4]
	test4=list[2]
	env["a"]=10
	test3=env["a"]
	"Test3 $test3$"
	"List $test6[1]$"
	"List $test6[2]$"
	"List $test6[3]$"
	"List $test6[4]$"
	"List $test6[5]$"
	"List $test6[6]$"
	"List $test6[7]$"
	"Dict $test7[name]$"
	"Dict $test7[age]$"
	"Dict $test7[job]$"
	test9="name"
	test8=test7[test9]
	"Test8 $test8$"
	data=test7[list]
	data2=data[1]
	"Test9 $data2$"
	data=tester2(1,2,3)
	"Now what are these $a$ $b$ $c$"
	"$data[name]$"
	"$data[me]$"
	::choices::
	"Pick?"<
		"test1" JUMP(C1)
		"test2" JUMP(C2)
		"test3" JUMP(C3)
	>
	-- if name=="bob" or name=="ryan":
		-- "ADMINS"
	-- elseif name=="Joe"
		-- "NOT ADMIN"
	-- else
		-- "Something else"
	-- endif
}
[C1]{
	"Hello1"
	GOTO(choices)
}
[C2]{
	"Hello2"
	GOTO(choices)
}
[C3]{
	"Hello3"
	GOTO(choices)
}
[@:construct]{ -- l is left arg r is the right arg
    ret=l*(r/100)
    return(ret)
}
[tester:function]{
	"lets go"
	nest="hey"
}
[tester2:function(a,b,c)]{ -- functions return enviroments which can be indexed
	"Interesting: $a$ $b$ $c$"
	name="Ryan"
	age=15
	yo=tester()
	me=yo["nest"]
}
```

parsetest2.txt
```lua
ENTRY START
[START]{
	"Hello It is now time to do some tests!"
	a=15
	"a = $a$"
	b=a@25
	test2="Yo $a$ $b$" -- create a string with a and b vars
	"$test2$"
	"b = $b$"
	c=5
	"c = $c$"
	cf=10+(5!)+10
	test=(5~5)+5
	"c! = $cf$ test = $test$"
	"All done"
	JUMP(NOVAR)
}
[@:construct]{ -- get % out of 100
	ret=l/(r/100)
    return(ret)
}
[~:construct]{ -- negate variable
	if r~=NONE then GOTO(sub)|GOTO(neg)
	::sub::
		ret=l-r
		return(ret)
		GOTO(end)
	::neg::
		ret=0-r
		return(ret)
	::end::
}
-- You dont have too many symbols left to use though. For now a symbol is only 1 char long so you are limited
[fact:function(n)]{
	count=1
	stop=n
	::loop:: -- for loop kinda, can become a stateloop as well
		n=n*count
		count=count+1
		if count==stop then GOTO(end)|GOTO(loop)
	::end::
		ret=n
}
[neg:function(n)]{
	ret=n*(0-1)
}
--Bind the fact function to the symbol '!'
[!:construct]{
	env=fact(l)
	ret=ret<-env
	return(ret)
}
[NOVAR]{
	::go::
		"I AM HERE!!!"
		NOVAR="TEST"
		JUMP(START)
}
[TEST]{
	"We are now here"
}
```

Here is the luacode using the library. NOTE: I was doing tests so the test code has blocks of code that should be within the module itself!
main.lua
```lua
require("bin")
require("multi.all")
require("parseManager")
function parseManager:RunCode(code,entry,sel,env) -- returns an env or selectVarName
	local file = bin.new("ENTRY "..(entry or "START").."\n"..code)
	local run=parseManager:load(file)
	run._methods = self._methods
	run.defualtENV=self.defualtENV
	run.defualtENV=self.defualtENV
	for i,v in pairs(env or {}) do
		run.defualtENV[i]=v
	end
	local t=run:start()
	while true do
		if t.Type=="text" then
			print(t.text)
			t=run:next()
		elseif t.Type=="condition" then
			t=run:next()
		elseif t.Type=="assignment" then
			t=run:next()
		elseif t.Type=="label" then
			t=run:next()
		elseif t.Type=="method" then
			t=run:next()
		elseif t.Type=="choice" then
			t=run:next(nil,math.random(1,#t.choices),nil,t)
		elseif t.Type=="end" then
			if t.text=="leaking" then -- go directly to the block right under the current block if it exists
				t=run:next()
			else
				return (run.defualtENV[sel] or run.defualtENV)
			end
		elseif t.Type=="error" then
			error(t.text)
		else
			t=run:next()
		end
	end
end
parseManager.symbols={} -- {sym,code}
function parseManager:registerSymbol(sym,code)
	self.symbols[#self.symbols+1]={sym,code}
end
function parseManager:populateSymbolList(o)
	local str=""
	for i=1,#self.symbols do
		str=self.symbols[i][1]..str
	end
	return str
end
function parseManager:isRegisteredSymbol(o,r,v)
	for i=1,#self.symbols do
		if self.symbols[i][1]==o then
			return parseManager:RunCode(self.symbols[i][2],"CODE","ret-urn",{["l"]=r,["r"]=v,["mainenv"]=self.defualtENV})
		end
	end
	return false --self:pushError("Invalid Symbol "..o.."!")
end
function parseManager:evaluate(cmd,v)
	v=v or 0
	local loop
	local count=0
	local function helper(o,v,r)
		if type(v)=="string" then
			if v:find("%D") then
				v=self:varExists(v)
			end
		end
		if type(r)=="string" then
			if r:find("%D") then
				r=self:varExists(r)
			end
		end
		local r=tonumber(r) or 0
		local gg=self:isRegisteredSymbol(o,r,v)
		if gg then
			return gg
		elseif o=="+" then
			return r+v
		elseif o=="-" then
			return r-v
		elseif o=="/" then
			return r/v
		elseif o=="*" then
			return r*v
		elseif o=="^" then
			return r^v
		end
	end
	for i,v in pairs(math) do
		cmd=cmd:gsub(i.."(%b())",function(a)
			a=a:sub(2,-2)
			if a:sub(1,1)=="-" then
				a="0"..a
			end
			return v(self:evaluate(a))
		end)
	end
	cmd=cmd:gsub("%b()",function(a)
		return self:evaluate(a:sub(2,-2))
	end)
	for l,o,r in cmd:gmatch("(.*)([%+%^%-%*/"..self:populateSymbolList().."])(.*)") do
		loop=true
		count=count+1
		if l:find("[%+%^%-%*/]") then
			v=self:evaluate(l,v)
			v=helper(o,r,v)
		else
			if count==1 then
				v=helper(o,r,l)
			end
		end
	end
	if not loop then return self:varExists(cmd) end
	return v
end
parseManager.constructType=function(self,name,t,data,filename)
	if t~="construct" then return end
	--print(name,t,"[CODE]{"..data.."}")
	self:registerSymbol(name,"[CODE]{"..data.."}")
end
parseManager.OnExtendedBlock(parseManager.constructType)
test=parseManager:load("parsetest2.txt") -- load the file

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
```
# Output if using parsetest.txt
```
100 7 21
15 150 21
100 7 21
Test 15
100 7 21
51 150 21
Test2 9
Test5 Yo I am able to make a multilined string if i want
Now I am at the next line lol!
Test3 10
List elem1
List 2
List 3
List true
List false
List elem6
List table: 00B53B98
Dict Ryan
Dict 21
Dict BUM
Test8 Ryan
Test9 data[1]
Interesting: 1 2 3
lets go
Now what are these 51 150 21
Ryan
hey
Pick?
1. test1
2. test2
3. test3
Choose#: 2
Hello2
Pick?
1. test1
2. test2
3. test3
Choose#: 3
Hello3
Pick?
1. test1
2. test2
3. test3
Choose#: 1
Hello1
Pick?
1. test1
2. test2
3. test3
Choose#: Pick?
1. test1
2. test2
3. test3
Choose#: 
... Would continue forever
```
# Output if running parsetest2.txt
```
Hello It is now time to do some tests!
a = 15
Yo 15 60
b = 60
c = 5
c! = 140 test = 5
All done
I AM HERE!!!
Hello It is now time to do some tests!
a = 15
Yo 15 60
b = 60
c = 5
c! = 140 test = 5
All done
We are now here
```
