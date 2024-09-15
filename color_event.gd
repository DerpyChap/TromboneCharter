class_name ColorEvent
extends BGEvent

@onready var _color_picker : ColorPickerButton = $UI/ColorPickerButton
@onready var _duration_spinbox : SpinBox = $UI/Duration
@onready var _ui : Control = $UI
@onready var color : Color:
    set(value):
        color = value
        if _color_picker:
            _color_picker.color = value
@onready var color_editor : ColorEventsEditor = get_parent()

var pitch : float:
    set(value):
        pitch = value
        if _ui && chart:
            _ui.position.y = chart.pitch_to_height(value)

@onready var duration : float:
    set(value):
        duration = value
        if _duration_spinbox:
            _duration_spinbox.value = value

func set_label():
    match id:
        0:
            label.text = "FarLeftLight"
        1:
            label.text = "MidLeftLight"
        2:
            label.text = "MidRightLight"
        3:
            label.text = "FarRightLight"
        10:
            label.text = "FarLeftFloorLight"
        11:
            label.text = "MidLeftFloorLight"
        12:
            label.text = "MidRightFloorLight"
        13:
            label.text = "FarRightFloorLight"
        _:
            label.text = ""

func _process(_delta):
    if !dragging: return
    if !Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
        dragging = false
        bar = chart.x_to_bar(position.x)
        Global.working_tmb.color_events = color_editor.package_events()
        return
    var pos = chart.get_local_mouse_position() - Vector2(0, 20)
    var snapped_pos = chart.to_snapped(pos)
    print("%s %s" % [pos, snapped_pos])
    bar = snapped_pos.x
    pitch = snapped_pos.y

func _draw():
    draw_polyline_colors([Vector2.ZERO,Vector2(0, size.y)],
            [Color.YELLOW,Color.TRANSPARENT],2.0
        )

func _on_delete_button_pressed():
    queue_free()
    Global.working_tmb.color_events = color_editor.package_events()
    color_editor._refresh_events()

func _on_spin_box_value_changed(new_id):
    if id != new_id:
        id = new_id
        Global.working_tmb.color_events = color_editor.package_events()
        queue_redraw()

func _on_color_picker_button_ready() -> void:
    $UI/ColorPickerButton.color = color

func _on_color_picker_button_popup_closed() -> void: 
    if _color_picker.color != color:
        color = _color_picker.color
        color_editor.last_color = color
        Global.working_tmb.color_events = color_editor.package_events()

func _on_duration_value_changed(value: float) -> void:
    if duration != value:
        duration = value
        Global.working_tmb.color_events = color_editor.package_events()
