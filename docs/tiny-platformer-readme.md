TINY PLATFORMER
===============

A Pico-8 example game by Eli Piilonen

With special thanks to David Carney,
and to all of our magnificent testers


### INTRO

Hello!  Thanks for buying Tiny Platformer.
This is a full Pico-8 project which is intended
to show some possible answers to common questions
that people have when making a 2D runny-jumpy game.

It might sound obvious, but I tried to make a
piece of tutorial content where the end result
is "actually fun."  The most invigorating
tutorial I ever saw was the source code for
"Madness Interactive" by Max Abernethy, and it
was primarily because the game was SUPER FUN.

I can only hope to evoke that kind of
excitement for you, too!

If you don't own Pico-8, you'll need a copy to
load and run the project:

https://www.lexaloffle.com/pico-8.php

Pico-8 is lovely, and I can't recommend it enough.

...If you're reading this, then I sincerely
hope you already have it, for several reasons.

### LICENSING

Here are the licensing rules for Tiny Platformer:

1.  The "no comments" version of the game can
	be edited, and you can export/share stuff
	that you make with it. You are not permitted
	to share the source code, though.  This means
	that if you want to upload a mod to the Pico-8
	BBS, you'll need to minify it first (see note,
	below). These mods may not be monetized.
2.  The "empty" version of the game can be edited
	and exported, and you are permitted to
	monetize your work.  Generally, you can sell
	your stuff as long as you don't use my map
	or the bossfight. The same rules about not-
	sharing-the-unminified-source still apply.

ABOUT MINIFYING THE CODE:
Google "picotool" for a python utility that
lets you minify/obfuscate a cartridge's code.

Note - after I run picotool's "luamin" function on
the cart, I get an error when I run the game.  It
says that a certain function is undefined - this
function is supposed to be time(). If the missing
function is called "gu" then you can fix it by
doing this:

gu=time

(Just put that line at the top of your minified code.
If you get a different missing function name, use
that instead, but still assign it as time)

### QUESTIONS

If you would like any clarification about
anything contained in the game, send me
a tweet or DM on Twitter:

@2DArray

If enough people ask about a topic, I'll
try to make a piece of video content to
discuss it in detail.

And now, the rest of this document will be
a few quick tips about some built-in features.

### CREATING MOVING PLATFORMS

There are two ways to create a moving platform:

1.  Place "mover marker" tiles in the map
2.  Call the "makemover()" function

Sprite 32 (the purple box) is a mover-marker.
If you place a rectangular group of these
anywhere in the map, the game will convert it
into a single rectangular platform during _init().
You can have any number of these, and the
generator uses a flood-fill to detect rectangles,
so it will combine multiple neighboring tiles
into one overall bounding box (concave shapes
don't work - all movers are rectangles).

After they're loaded, if you want to get a
reference to one of these auto-spawned movers...

mymover = moverlookup[mx][my]

...where mx and my are map-space coordinates.
All connected marker positions will return a
reference to their same combined platform,
so you can use any point that's contained
in the box to find it.

If you call the makemover() function instead,
it takes four parameters:

cx,cy,w,h

cx and cy are the center-point of the block.
w and h are the total width and height.

...I'm pretty sure that makemover() gives
a slightly inaccurate size (off-by-one?), so
you might want to take a look at it if you're
having a problem getting something sized just-so.

If you want to attach a mover to another one (to
build compound shapes), you can use the setparent()
function.

Nested parenting is not officially supported, but
it might work anyway (with some latency).

### DYNAMIC MUSIC

This game uses a system which lets it mute
different channels of the music loop during
different segments of the game.

By default, this is controlled by placing
a "music marker" tile next to any checkpoint.
The music markers are Sprites 48-55, and each
of them has some number of white bars. These
represent which music channels are enabled
(the song only has 3 channels).

If you'd like to edit the music channels in
a different way, you can alter the global
"musicmask" variable manually.  This is a
3-bit mask where the lowest bit is the
music channel on the left of the editor.

-- play all 3 channels
musicmask=7

-- play channel 1
musicmask=1

-- play channel 3
musicmask=4

-- play channels 1+3
musicmask=5

Due to the way that pico8 handles music
data, muting and unmuting only occurs at
the start of a new measure/pattern.