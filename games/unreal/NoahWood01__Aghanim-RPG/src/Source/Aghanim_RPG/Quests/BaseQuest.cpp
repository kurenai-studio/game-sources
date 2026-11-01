// Copyright (c) 2022 Noah Wood


#include "BaseQuest.h"

UBaseQuest::UBaseQuest()
{
	name = "Default Quest";
	description = "This is the Default Quest";

	reward.rewardType = EQuestReward::E_Default;
	reward.experience = 100.0f;
	reward.item = nullptr;
}

void UBaseQuest::setQuestDetails(FString _name, FString _description)
{
	name = _name;
	description = _description;
}

void UBaseQuest::setUpObjective(int _objectiveNum, TSubclassOf<ABasicEnemy> _enemy, TSubclassOf<ADefaultItem> _item, FString _description1, FString _description2, int _numRequired)
{
	if (_objectiveNum < objectives.Num())
	{
		if (_enemy != nullptr)
		{
			objectives[_objectiveNum].clearType = EClearCondition::E_Slay;
			objectives[_objectiveNum].enemyToSlay = _enemy;
		}
		else if (_item != nullptr)
		{
			objectives[_objectiveNum].clearType = EClearCondition::E_Collect;
			objectives[_objectiveNum].itemToCollect = _item;
		}


		objectives[_objectiveNum].objectiveID = _objectiveNum;
		objectives[_objectiveNum].numRequired = _numRequired;

		// create complete description
		objectives[_objectiveNum].description.Append(_description1 + " ");
		objectives[_objectiveNum].description.AppendInt(_numRequired);
		objectives[_objectiveNum].description.Append(" " + _description2);
	}
}

void UBaseQuest::setNumObjective(int _numObjectives)
{
	objectives.SetNum(_numObjectives);
}

void UBaseQuest::updateQuest()
{

}

void UBaseQuest::updateObjective(int _objectiveNum, int _updateValue)
{
	if (_objectiveNum < objectives.Num())
	{
		objectives[_objectiveNum].numRequired -= _updateValue;

		UE_LOG(LogTemp, Warning, TEXT("You need to perform action %d more times."), objectives[_objectiveNum].numRequired);

		if (objectives[_objectiveNum].numRequired <= 0)
		{
			finishObjective(_objectiveNum);
		}
	}
}

void UBaseQuest::finishObjective(int _objectiveNum)
{
	if (_objectiveNum < objectives.Num())
	{
		objectives[_objectiveNum].isComplete = true;
		UE_LOG(LogTemp, Warning, TEXT("You need have completed objective %d."), _objectiveNum);
		int numFinished = 0;

		for (int i = 0; i < objectives.Num(); ++i)
		{
			if (objectives[i].isComplete)
			{
				++numFinished;
			}
		}

		if (numFinished >= objectives.Num())
		{
			finishQuest();
		}
	}
}

void UBaseQuest::finishQuest()
{

}