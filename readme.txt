               The Keyboard Corrector for DOOM
           Copyright (C) 1995 by FRIENDS Software
                  Written by Maxim Masiutin


   This small utility simplifies keyboard handling in the DOOM II
game released by id Software in 1994. To be specific, it does the
following:

1. Inverts the state of the Shift key (at the beginning of the
     game, press once to initialize the utility), so you do not
     need to hold the Shift key all the time for the game character
     (Doomguy) to run.
2. Allows you to switch weapons with KeyPad (7-gun, 9-machine gun,
     5-grenades, 1-plasma, 3-BFG).

   To use this utility, you need to patch DOOM2.EXE so that the
value of the scan code was taken not from the I/O port, but from our
interrupt handler, that is, replace the instruction "in al, edx" to
our "int 0CAh". To do that, find the sequence of bytes
"BA 60 00 00 00 29 C0 EC" (mov edx, 60h; sub eax, eax; in al, edx)
and replace the last 3 bytes in that sequence (29 C0 EC) to
"CD CA 90" (int 0CAh; nop). You can also patch this way the game
Heretic by Raven Software in 1994.

   Before starting DOOM2.EXE, the "SH.COM" TSR (terminate and stay
resident) program must be loaded into memory.

Programmer's note:

The source code is also included, so if you have good imagination,
you can implement many useful features, for example, AutoFire, etc.
Therefore, just in case, as an illustration, I have also provided
a utility that inverts SHIFT through the QEMM API, but that works
only in DOS real mode.
