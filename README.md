# Asteroid Blaster

A Game Project in Verilog with the DE1-SOC FPGA chip. 

This was made in collaboration with Chin Hou Ren (Github: @chinhouren) for Computational Organization at the University of Toronto. Note that this was written in verilog, a hardware descriptive language designed for FPGAs. This game, essentially, is equivalent of assembling logic gates with a virtual logic board from scratch. 

Grade received for this project: 100%.

Resolution: 160x120 @ 50Mhz clock speed
Colour: 3-bits

To run:

- First, get your hands on some FPGA chip that is able to run verilog, the descriptive hardware language (De1-Soc was used in this project)

- Connect a keyboard to the FPGA

- Run this project on Quartus, importing all .v files into a project and run ab.v (ab.v is the top module)

To play:

- Press space to syncronous reset.***

***IMPORTANT! Otherwise, linear-feedback register will not work and the "random" aspect of the game is omitted.

- Press enter to start the game.

- Controls are listed on the side bar of the main game, using W for Shoot, A for left-move, D for right-move.

- You must dodge the asteroids, or shoot them. Shoot has an ammo cooldown.

- Once you have been hit by an asteroid, you will lose a life shown among the 5 total lives you have on the right side of the screen.

- If you lose all lives, the game is over. To play again, simply press the space bar again to reset.
