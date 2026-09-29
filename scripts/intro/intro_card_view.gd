class_name IntroCardView
extends VBoxContainer

@onready var title_label: Label = %TitleLabel
@onready var body_label: Label = %BodyLabel


func display_card(card: Dictionary) -> void:
	var title := str(card.get("title", ""))
	title_label.text = title
	title_label.visible = not title.is_empty()
	body_label.text = str(card.get("body", ""))


func display_end_message() -> void:
	title_label.visible = false
	body_label.text = "END OF INTRO"
