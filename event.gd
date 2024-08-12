class_name BGEvent
extends Lyric

@onready var spin_box : SpinBox = $SpinBox
@onready var label : Label = $EventName

var id : int:
	set(value):
		if Global.EVENTS_EDITOR_MODE == 1 && id in [-100, -101] && value not in [-100, -101]:
			spin_box.value = id
			# stops lane switch mode from setting non-lane switch ids
			return
		id = value
		if label:
			set_label()
		if Global.EVENTS_EDITOR_MODE == 1 && id not in [-100, -101]:
			set_visible(false)
		else:
			set_visible(true)

func set_label():
	match id:
		-1:
			label.text = "PlayConfetti"
		-2:
			label.text = "PlaySongColorConfetti"
		-3:
			label.text = "PlayStartColorConfetti"
		-4:
			label.text = "PlayEndColorConfetti"
		-10:
			label.text = "PlayFireworks"
		-11:
			label.text = "PlayFireworkComet"
		-12:
			label.text = "PlayFireworkPion"
		-13:
			label.text = "PlayFireworkPalm"
		-14:
			label.text = "PlayFireworkCrossover"
		-15:
			label.text = "PlayFireworkFlare"
		-20:
			label.text = "PlayAurora"
		-21:
			label.text = "PlaySongColorAurora"
		_:
			label.text = ""

func _ready():
	spin_box.value = id
	set_label()
	position.x = chart.bar_to_x(bar)
	# this is a silly workaround to spinboxes not having a submit event
	line_edit = spin_box.get_line_edit()
	line_edit.connect("text_submitted", _on_text_submitted)
	Global.events_mode_changed.connect(_on_event_mode_changed)

func _on_text_submitted(_text:String):
	line_edit.release_focus()

func _process(_delta):
	if !dragging: return
	if !Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		dragging = false
		bar = chart.x_to_bar(position.x)
		Global.working_tmb.bgdata = editor.package_events()
		return
	var pos = chart.get_local_mouse_position()
	bar = chart.to_snapped(pos).x


func _draw():
	match id:
		-100:
			draw_polyline_colors([Vector2.ZERO,Vector2(0, size.y)],
				[Color.RED,Color.TRANSPARENT],4.0
			)
		-101:
			draw_polyline_colors([Vector2.ZERO,Vector2(0, size.y)],
				[Color.BLUE,Color.TRANSPARENT],4.0
			)
		_:
			draw_polyline_colors([Vector2.ZERO,Vector2(0, size.y)],
				[Color.GREEN,Color.TRANSPARENT],2.0
			)

func _on_delete_button_pressed():
	queue_free()
	Global.working_tmb.bgdata = editor.package_events()
	editor._refresh_events()

func _on_spin_box_value_changed(new_id):
	id = new_id
	Global.working_tmb.bgdata = editor.package_events()
	queue_redraw()

func _on_event_mode_changed(mode: int):
	match mode:
		1:
			if id in [-100, -101]:
				set_visible(true)
			else:
				set_visible(false)
		2:
			if not visible:
				set_visible(true)
