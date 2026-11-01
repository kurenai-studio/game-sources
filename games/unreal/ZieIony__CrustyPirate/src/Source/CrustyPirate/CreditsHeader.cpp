// Fill out your copyright notice in the Description page of Project Settings.


#include "CreditsHeader.h"

void UCreditsHeader::setLabel(const FString& label) {
	if (LabelText) {
		LabelText->SetText(FText::FromString(label));
	}
}
