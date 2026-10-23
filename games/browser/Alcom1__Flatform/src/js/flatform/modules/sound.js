//ff
var ff = ff || {};

//Module that plays and manages sounds.
ff.managerSound = (function()
{
    //Soft pauser for repeating sounds. Helps to pause repeating sounds within a preset interval of quiet moments.
    var pauserSoft; 
	
	//Init
	function init(element, volume)
	{
        //Set global volume.
        var sounds = element.children;
        for(var i = 0; i < sounds.length; i++)
        {
            sounds[i].volume = volume;
        }
	}
    
    //Update the sound module.
    function update()
    {
        //Soft pauser action
        if(pauserSoft != undefined)
        {
            var sound = document.querySelector("#" + pauserSoft[0]);
            if(Math.floor(sound.currentTime * 1000) % pauserSoft[1] > pauserSoft[1] * pauserSoft[2])
            {
                sound.pause();
                pauserSoft = undefined;
            }
        }
    }
    
    //Play sound by ID and disrupt option.
    function playSound(id, disrupt)
    {
        var sound = document.querySelector("#" + id);
        if(disrupt)
        {
            sound.pause();
            sound.currentTime = 0;
        }
        sound.play();
        pauserSoft = undefined;
    }
    
    //Set a sound to be paused by its id, the length of its steps, and the threshold magnitude.
    function pauseSoundSoft(id, step, mag)
    {
        pauserSoft = [id, step, mag];
    }
    
    //Pause a sound immediately.
    function pauseSoundHard(id)
    {
        document.querySelector("#" + id).pause();
        pauserSoft = undefined;
    }
	
	//Return
	return {
		init : init,
        update : update,
        playSound : playSound,
        pauseSoundSoft : pauseSoundSoft,
        pauseSoundHard : pauseSoundHard,
    }
    
}());