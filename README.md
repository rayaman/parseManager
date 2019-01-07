# parseManager

A module for making advance config files. This library depends on my multi library and my bin library

Here is an example, this would be its own file called parsetest.txt

There have been massive changes to syntax and how the library works. I will include a notepad++ file for syntax highlighting. I will eventually update the C# version of this script.
```
ENTRY START
[START]{
	::name::
		name = getInput("Enter your name: ")
		if name=="" then GOTO("name")|SKIP(0)
	::good::
		print("Player Name: $name$")
		choice = getInput("Is this name correct? (y/n): ")
		if choice=="y" then SKIP(0)|GOTO("name")
	print("Let's play $name$!")
	list=["r","p","s"]
	list2=["rock","paper","scissors"]
	list3=[]
	list3["r"]="rock"
	list3["p"]="paper"
	list3["s"]="scissors"
	::gameloop::
		cpus_mov=random(1,3)
		cpus_move=$list[cpus_mov]$
		player_move = getInput("Enter 'r' 'p' or 's': ")
		if player_move=="r" or player_move=="p" or player_move=="s" then SKIP(0)|GOTO("gameloop")
		a=$list2[cpus_mov]$
		b=$list3[player_move]$
		if player_move==cpus_move then print("We both played $b$, no one won...")|SKIP(0)
		if cpus_move=="r" and player_move=="s" then print("I won $name$, you lose! You know $a$ beats $b$")|SKIP(0)
		if cpus_move=="p" and player_move=="r" then print("I won $name$, you lose! You know $a$ beats $b$")|SKIP(0)
		if cpus_move=="s" and player_move=="p" then print("I won $name$, you lose! You know $a$ beats $b$")|SKIP(0)
		b=$list2[cpus_mov]$
		a=$list3[player_move]$
		if player_move=="r" and cpus_move=="s" then print("$name$ you won wow! I guess my $b$ was no match for your $a$")|SKIP(0)
		if player_move=="p" and cpus_move=="r" then print("$name$ you won wow! I guess my $b$ was no match for your $a$")|SKIP(0)
		if player_move=="s" and cpus_move=="p" then print("$name$ you won wow! I guess my $b$ was no match for your $a$")|SKIP(0)
		::choice::
			cho=getInput("That was a fun game! Do you want to play again? (y/n): ")
			if cho=="y" then GOTO("gameloop")|SKIP(0)
			if cho=="n" then print("Thanks for playing!")|SKIP(0)
}
```
