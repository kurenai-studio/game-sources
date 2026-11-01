class_name MonsterActionSummonGoblin extends MonsterActionSummonEnemy


func _init() -> void:
	super("Call Reinforcements", "goblin", func() -> EnemyData: return Goblin.new())
