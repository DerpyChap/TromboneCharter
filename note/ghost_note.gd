class_name GhostNote
extends Note

func _init():
    modulate = Color(1, 1, 1, 0.5)
    set_process_input(false)

func _gui_input(_event):
    return 0

func _on_handle_input(_event, _which_handle):
    return 0