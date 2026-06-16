class_name TreeChopDetector
extends RefCounted

## 从玩家位置与朝向查找最近可砍伐目标（大树或树桩）。

static func find_chop_target(
	player: Node2D,
	facing: Vector2,
	max_range: float
) -> Node:
	if player == null:
		return null

	var best: Node = null
	var best_score: float = INF
	var direction: Vector2 = facing.normalized()
	if direction == Vector2.ZERO:
		direction = Vector2.DOWN

	for group_name: StringName in [&"choppable_tree", &"tree_stump"]:
		for node: Node in player.get_tree().get_nodes_in_group(group_name):
			if not node is Node2D:
				continue

			var target: Node2D = node as Node2D
			var to_target: Vector2 = target.global_position - player.global_position
			var distance: float = to_target.length()
			if distance > max_range:
				continue

			var chop_range: float = max_range
			if target.has_method(&"is_in_chop_range"):
				if not target.is_in_chop_range(player.global_position):
					continue
			else:
				if distance > chop_range:
					continue

			# 优先面向方向上的目标
			var facing_dot: float = -1.0
			if distance > 0.01:
				facing_dot = direction.dot(to_target.normalized())

			var score: float = distance - facing_dot * 24.0
			if score < best_score:
				best_score = score
				best = target

	return best
