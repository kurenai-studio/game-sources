// Fill out your copyright notice in the Description page of Project Settings.


#include "CreditsEntry.h"
#include <Internationalization/Text.h>

void UCreditsEntry::setLabel(const FString& label) {
	if (LabelText) {
		LabelText->SetText(FText::FromString(label));
	}
}

void UCreditsEntry::setValue(const FString& value) {
	if (ValueText) {
		ValueText->SetText(FText::FromString(value));
	}
}
