# riderquest
Official game repository of Rider Quest, Ludum Dare #41 entry.

# Project Strucutre
The Game was programmed in Unity using C#, files are organized as such. The maps we're created using Bjorn's awesome tool [Tiled](https://www.mapeditor.org/), which, if you haven't, you should DEFINITELY check out. It's an amazing tool for editing maps together. All the Tiled maps were imported using Seanba's [Tiled2Unity](http://www.seanba.com/introtiled2unity.html), another amazing tool if you want to use Tiled with Unity.
+ **Assets** folder contains all the Unity assets (most should be on the Resources folder, but we're bad at Unity).
	+ **Scenes**: .scene files.
	+ **Scripts**: C# script files.
	+ **Music**: OGG music files.
	+ **Sound**: WAV sound files.
	+ **Sprites**: Messy images folder.
	+ Tiled2Unity folder contains all the prefabs created by importing the maps.
+ **Story.txt** has the complete story writen without any standards whatsoever (read at risk).
+ **Credits.txt** has a link to the resources we used in the game. Please let me know if anything is missing!
+ **Maps** folder has all the Tiled maps and tileset files. Please ignore the hard coded collisions, I know they're utter trash, wrong, and stay away material, but they were quicker to do.

## TL;DR
We messed up. Heavily. Game sucks, but it was a very fun experience. Everything is open source, code is under MIT license, and artistic work (sounds and music) are CC, use as you like.

## Links
+ Source can be found on [GitHub](https://github.com/mp-pinheiro)
+ Download of the game can be found on the [Release Page](https://github.com/mp-pinheiro/riderquest/releases/tag/0.0.1). Just download "riderquest-0.0.1.7z", extract it, and play it.
+ The Battle Theme Song can be listened to on [BandCamp](https://yfritgames.bandcamp.com/track/riderquest-battle-theme). It's free to download and use!

## Disclaimers
+ This is a highly unfinished game. See post below for more info.
+ Play on a high resolution (1280x720 or higher). Messages won't show on lower resolutions.
+ We used CC licensed graphics, so this is out of the Graphics category.

### Sad, but happy
This was a fun ride, for sure, but as our first Jam, so many mistakes were made. I wanted to write this blog post to at least let it written to my future self (and everyone interested, of course) all the things that me and my friend did on this project.

### The theme
The theme was very hard to build on, in my opinion. We spend some good 40 minutes trying to figure out what to do, and the awesome idea we had was also our doom. We decided to mix JRPG with Racing to create this comedic disgrace of a NES Final Fantasyish style game, but with the gimmick that everyone in the game is riding a car. We decided to opt out of the graphics category, as we wanted something that look okay, and both myself and my friend have artistic skills tending zero. I spent some good 8 hours writing a JRPG cliche story that I honestly love, but that is ridiculously long for such a limited amount of time (we couldn't do overnights, and I had an exam today, so we had roughly 2 days). 

### The game
As of now, we have the bare minimum implemented. Our turn-based battle system works and is structured for various monsters and party members, but characters only do normal attacks, have only HP and Damage as attributes and can't use items. The UI is a massive place holder, with the default font and a weird purple color to allow reading.   

Our "driving" system on the overworld works and is really fun, but we don't explore it whatsoever. Sure it's fun to drive around hitting things, but there's nothing else to it. Some collisions don't exist, as we intended to do some perspective work on the graphics, like passing behind things such as trees and houses to give a sense of perspective, is completely bug and you WILL ghost through plants.

The main story goes as far as 1/4 of the way. I wrote a prologue and 4 chapters. As of now, the game goes until close to the end of Chapter 1. Characters are fun, and have nice JRPG personalities (the "hero"protagonist, the "goofy" thief and so on, but none of them have actual names, as I was coming up with them and intended, as a joke to create very fantasy like names, since the concept of a car walking around introducing itself as "Arkatosh" is very funny to me.

Sound track is the biggest shame here. I love this theme and genre, and I wanted to do so much with it, but in the end there was no time. We have two complete songs that even though I like, there is so much that can be done to improve on them. The remaining songs were rushed pieces of thrash that have 20 seconds max.

### On our work
Taking all of that into consideration, and also the fact that we used a lot of CC graphics, we decided to make the code open source and license it under MIT. Music and sounds (I have no idea who'd want to use the awful sounds I created, but hey, they're there) are also CC, and you can do whatever you want with them. Hit me up on my email if you do anything cool, though, I'd love to see it!

### Mistakes, mistakes
Our biggest mistake for sure was not playing to our strengths. I like to think of myself as an okay programmer and composer. My friend Lucas is a very creative guy who comes up with the most insane game ideas and mechanics (see our Steam game [Dual Snake](http://store.steampowered.com/app/752600/Dual_Snake/) and you'll know what I'm talking about). But, in the end, I spent hours writing the story and designing maps, the first I'm bad at and the second I hate. 

### Final words
Well, that's all that. I'm not sure if anyone is going to read all this crap, but I wanted to take it out of my system. There was definitely a lot of learning involved, it was an amazing experience that I'll never forget. I'm happy that we took part in it, and I'm happy with the things that we made, but I'm also very determined to do a way better job next time. There was probably more I could have done on these 2 remaining hours, but I feel very unmotivated to keep working on this after 2 whole days.

Anyways... thank you very much if you read it up to this point, or if you gave our Frankenstein a try. Loved being part of this awesome event, the community was amazing! Seeing everybody's work on the screenshots and blog posts was really cool. Lucas and I will surely be here on the next ones.

That's all folks. 
Bye!
