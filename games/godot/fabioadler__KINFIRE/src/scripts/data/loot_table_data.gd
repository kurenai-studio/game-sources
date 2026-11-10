class_name LootTableData
extends Resource
## Tabela de loot por raridade de monstro (REGRAS #6 - "drops garantidos").
## Selecionada por (inimigo x raridade): a raridade escolhe a tabela-base
## (DB.loot_tables, índice = Enemy.Rarity); o eixo por inimigo vem do
## EnemyData (dados tuned no caso do chefe + `unique_drop` opcional).

@export var gold_chance := 0.4          ## chance de dropar ouro
@export var gold_mult := 1              ## multiplicador do valor (REGRAS #6, coluna XP/Ouro)
@export var globe_chance := 0.12        ## chance de globo de vida
@export var item_chance := 0.09         ## chance de um item de roll aleatório
@export var item_magic := 0.0           ## bônus de raridade no roll aleatório
@export var guaranteed: Array[int] = [] ## raridades de item GARANTIDAS, em ordem (Item.Rarity)
@export var legend_chance := 0.0        ## chance extra de um Lendário
@export var essence_chance := 0.0       ## chance de essência (REGRAS #9: só Campeão+)
@export var essence_amount := 1         ## essência por drop concedido
@export var unique_chance := 0.0        ## chance de item único (lendário nomeado)
