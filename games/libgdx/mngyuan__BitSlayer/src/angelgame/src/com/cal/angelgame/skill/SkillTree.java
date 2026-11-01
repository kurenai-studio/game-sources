package com.cal.angelgame.skill;

import com.cal.angelgame.player.PlayerCharacter;

public class SkillTree {
	/**
	 * The skills that the character can obtain divided into a tree
	 */
	
	String SkillTree[] = new String[9];
	
	public void makeSkillTree(PlayerCharacter character){
		if (character.characterType == "warrior"){ //even indexes are fast attributes
			SkillTree[0] = "SpeedStrUp";		   //odd indexes are tank attributes
			SkillTree[1] = "DefStrUp";
			SkillTree[2] = "DoubleStrike";
			SkillTree[3] = "GroundPound";
			SkillTree[4] = "Three-Hit-Combo";
			SkillTree[5] = "DoubleSwing";
			SkillTree[6] = "StealthHealth";
			SkillTree[7] = "HealthRegen";
			SkillTree[8] = "InstantKill";
		}
		else if (character.characterType == "ranger"){
			
		}
		else if (character.characterType == "rogue"){
			
		}
		else if (character.characterType == "mage"){
			
		}
	}
}
