class_name GhostSlideHelper
extends SlideHelper

func get_matching_note_on(time:float, exclude:Array = []): # -> Note or null
	for note in chart.get_children():
		if !(note is GhostNote) || (note in exclude): continue
		if abs(note.bar - time) < 0.01: return note
	return null
func get_matching_note_off(time:float, exclude:Array = []): # -> Note or null
	for note in chart.get_children():
		if !(note is GhostNote) || (note in exclude): continue
		if abs(note.end - time) < 0.01: return note
	return null