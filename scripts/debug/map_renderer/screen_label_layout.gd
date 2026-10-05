class_name ScreenLabelLayout
extends RefCounted

## Shared native-pixel font measurement and restrained nearby placement.
static func place(font: Font, text: String, size: int, anchor: Vector2, radius: float, occupied: Array[Rect2], viewport: Rect2, ratio: float, extra_distance: float = 0) -> Dictionary:
	var extent := Vector2(ceilf(font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,size).x),ceilf(font.get_ascent(size)+font.get_descent(size)))
	var gap := 4*ratio
	var offsets := [Vector2(radius+gap,-extent.y/2),Vector2(-extent.x/2,-radius-gap-extent.y),Vector2(-extent.x/2,radius+gap),Vector2(-radius-gap-extent.x,-extent.y/2),Vector2(radius+gap,-radius-gap-extent.y),Vector2(-radius-gap-extent.x,-radius-gap-extent.y),Vector2(radius+gap,radius+gap),Vector2(-radius-gap-extent.x,radius+gap)]
	var original_count := offsets.size()
	if extra_distance > 0:
		for distance in [12.0,24.0,48.0,64.0]:
			if distance > extra_distance: break
			offsets.append(Vector2(-extent.x/2,-radius-gap-extent.y-distance*ratio))
			offsets.append(Vector2(radius+gap+distance*ratio,-extent.y/2))
			offsets.append(Vector2(-extent.x/2,radius+gap+distance*ratio))
	var index := -1
	for offset in offsets:
		index += 1
		var rect := Rect2((anchor+offset).round(),extent).grow(2*ratio)
		if not viewport.grow(-2*ratio).encloses(rect): continue
		var clear := true
		for other in occupied:
			if other.grow(2*ratio).intersects(rect): clear = false; break
		if clear:
			occupied.append(rect)
			return {"rect":rect,"baseline":rect.position+Vector2(2*ratio,2*ratio+font.get_ascent(size)),"size":size,"text":text,"extended":index >= original_count}
	return {}
