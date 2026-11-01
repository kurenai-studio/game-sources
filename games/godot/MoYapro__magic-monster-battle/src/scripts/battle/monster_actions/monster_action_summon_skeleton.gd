class_name MonsterActionSummonSkeleton extends MonsterActionSummonEnemy


func _init() -> void:
	super("Raise Fallen", "skeleton", func() -> EnemyData: return Skeleton.new())
