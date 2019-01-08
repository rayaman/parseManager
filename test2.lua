io.flush()
i = io.input()
i:seek("cur")
i:read(2)
print(i)
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
