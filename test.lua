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
		print(t.prompt)
		for i=1,#t[1] do
			print(i..". "..t[1][i])
		end
		io.write("Choose#: ")
		cm=tonumber(io.read())
		t=test:next(nil,cm)
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
--[[
MAIN:
  1:
    Type: assign
    vals:
      1: 1
    vars:
      1: x
  2:
    Type: label
    pos: 2
    label: FORA
  3:
    Type: fwor
    Func: print
    args:
      1: x
      2: y
  4:
    Func: ADD
    Type: fwr
    vars:
      1: x
    args:
      1: x
      2: 1
  5:
    Type: assign
    vals:
    vars:
  6:
    Type: fwr
    vars:
      1: L$
    Func: COMPARE
    args:
      1: x
      2: 11
      3: ==
  7:
    Type: fwor
    Func: CSIM
    args:
      1: L$
  8:
    Type: fwor
    Func: GOTO
    args:
      1: FORENDA
  path: test.dms
  pos: 1
  11:
    Type: text
    text: Tests
  labels:
    FORA: 2
    FORENDA: 10
  type: BLOCK
  10:
    Type: label
    pos: 10
    label: FORENDA
  name: MAIN
  9:
    Type: fwor
    Func: GOTO
    args:
      1: FORA
]]
