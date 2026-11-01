// Fill out your copyright notice in the Description page of Project Settings.


#include "CreditsWidget.h"
#include <Containers/Array.h>
#include <Kismet/GameplayStatics.h>
#include "FUCreditsDataStruct.h"

void UCreditsWidget::NativeConstruct() {
	Super::NativeConstruct();

	if (Data && VerticalBox && CreditsEntryClass) {
		TArray<FUCreditsDataStruct*> rows;
		Data->GetAllRows<FUCreditsDataStruct>(FString("context"), rows);

		for (int32 i = 0; i < rows.Num(); i++) {
			FUCreditsDataStruct* row = rows[i];
			if (row) {
				if (row->Value.IsEmpty()) {
					auto creditsHeader = CreateWidget<UCreditsHeader>(UGameplayStatics::GetPlayerController(GetWorld(), 0), CreditsHeaderClass);
					if (creditsHeader) {
						creditsHeader->setLabel(row->Label);
						VerticalBox->AddChildToVerticalBox(creditsHeader);
					}
				} else {
					auto creditsEntry = CreateWidget<UCreditsEntry>(UGameplayStatics::GetPlayerController(GetWorld(), 0), CreditsEntryClass);
					if (creditsEntry) {
						creditsEntry->setLabel(row->Label);
						creditsEntry->setValue(row->Value);
						VerticalBox->AddChildToVerticalBox(creditsEntry);
					}
				}
			}
		}
	}
}

void UCreditsWidget::NativeTick(const FGeometry& MyGeometry, float InDeltaTime) {
	Super::NativeTick(MyGeometry, InDeltaTime);

	if (ScrollBox && VerticalBox//&& ScrollBox->GetScrollOffset()<VerticalBox->GetDesiredSize().Y
		) {
		ScrollBox->SetScrollOffset(ScrollBox->GetScrollOffset() + ScrollSpeed * InDeltaTime);
	}
}
