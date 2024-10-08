extends Node


@onready var chart : Control = %Chart
@onready var settings : Settings = %Settings
@onready var player : AudioStreamPlayer = %TrombPlayer
@onready var metronome : AudioStreamPlayer = %MetronomePlayer
@onready var StreamPlayer : AudioStreamPlayer = %TrackPlayer
var is_playing : bool = false
var song_position : float = -1.0
var elapsed_time : float = -1.0
var tmb : TMBInfo


func _ready(): pass


func _do_preview():
	if chart.tmb == null:
		print("null tmb")
		return
	else: tmb = chart.tmb
	if is_playing:
		is_playing = false
		%PreviewButton.text = "Preview"
		return
	is_playing = true
	
	var bpm : float = tmb.tempo
	var time : float
	@warning_ignore("unused_variable")
	var previous_time : float
	var last_position : float
	var initial_time : float = Time.get_ticks_msec() / 1000.0
	var startpoint_in_stream : float = Global.beat_to_time(settings.playhead_pos)
	var start_beat : float = settings.playhead_pos
	if settings.section_length:
		startpoint_in_stream = Global.beat_to_time(settings.section_start)
		start_beat = settings.section_start
	var slide_start : float
	var get_note_ons = func() -> Array[float]:
		var arr : Array[float] = []
		for note in tmb.notes: arr.append(note[TMBInfo.NOTE_BAR])
		return arr
	var note_ons : Array[float] = get_note_ons.call()
	var last_events = []
	var last_color_events = []

	%EventsAPI.stop_all_events()
	%EventsAPI.reset_color_events()
	StreamPlayer.play(startpoint_in_stream)
	%PreviewButton.text = "Stop"
	while is_playing:
		time = Time.get_ticks_msec() / 1000.0
		elapsed_time = time - initial_time
		
		song_position = elapsed_time * (bpm / 60.0) + start_beat
		if (settings.section_length && song_position > settings.section_start + settings.section_length):
			break
		if song_position >= settings.length.value:
			break
		
		if int(last_position) != int(song_position) && %MetroChk.button_pressed:
			metronome.play()
		last_position = song_position

		var events = _find_background_event(start_beat)
		if events:
			if events != last_events:
				for event in events:
					%EventsAPI.send_event(event[TMBInfo.EVENT_ID])
				last_events = events
		
		var color_events = _find_color_event(start_beat)
		if color_events:
			if color_events != last_color_events:
				for event in color_events:
					var color = Color(event["r"], event["g"], event["b"], event["a"])
					%EventsAPI.send_color_event(event["id"], event["time"], event["duration"], color)
				last_color_events = color_events

		
		var note : Array = _find_note_overlapping_bar(song_position)
		if note.is_empty():
			player.stop()
			await(get_tree().process_frame)
			continue
		
		var pitch = Global.pitch_to_scale(note[TMBInfo.NOTE_PITCH_START] / Global.SEMITONE)
		var end_pitch = note[TMBInfo.NOTE_PITCH_START] + note[TMBInfo.NOTE_PITCH_DELTA]
		end_pitch = Global.pitch_to_scale(end_pitch / Global.SEMITONE)
		
		var pos_in_note = (song_position - note[TMBInfo.NOTE_BAR]) / note[TMBInfo.NOTE_LENGTH]
		# i don't know why, but using smoothstep in setting pitch_scale doesn't work
		# so we do it out here
		pos_in_note = Global.smootherstep(0, 1, pos_in_note)
		
		# sort of kind of emulate the audible slide limit in the actual game
		player.pitch_scale = clamp(lerp(pitch,end_pitch,pos_in_note),
				Global.pitch_to_scale(slide_start - 12.0),
				Global.pitch_to_scale(slide_start + 12.0)
				)
		if !player.playing:
			player.play()
			slide_start = note[TMBInfo.NOTE_PITCH_START] / Global.SEMITONE
#			print(slide_start)
		previous_time = time
		await(get_tree().process_frame)
	
	is_playing = false
	%PreviewButton.text = "Preview"
	
	StreamPlayer.stop()
	player.stop()

	last_events = []
	last_color_events = []
	%EventsAPI.stop_all_events()
	%EventsAPI.reset_color_events()

	if !settings.section_length:
		settings.playhead_pos = song_position
	
	song_position = -1.0
	chart.queue_redraw()


func _find_note_overlapping_bar(time:float):
	for note in tmb.notes:
		# we sort the array by note-on every time we make an edit, so we can break early
		if time < note[TMBInfo.NOTE_BAR]: break
		var end_bar = note[TMBInfo.NOTE_BAR] + note[TMBInfo.NOTE_LENGTH]
		if time >= note[TMBInfo.NOTE_BAR] && time <= end_bar: return note
	return []

func _find_background_event(start_time: float):
	var final_events = []
	for event in tmb.bgdata:
		if song_position < event[TMBInfo.EVENT_BEAT]: break
		if start_time > event[TMBInfo.EVENT_BEAT]: continue
		if song_position >= event[TMBInfo.EVENT_BEAT]:
			# For overlapping events
			if final_events:
				if event[TMBInfo.EVENT_BEAT] == final_events[0][TMBInfo.EVENT_BEAT]:
					final_events.append(event)
				else:
					final_events = [event]
			else:
				final_events = [event]
	return final_events

func _find_color_event(start_time: float):
	var final_events = []
	start_time = Global.beat_to_time(start_time)
	var song_pos = Global.beat_to_time(song_position)
	for event in tmb.color_events:
		if song_pos < event["time"]: break
		if start_time > event["time"]: continue
		if song_pos >= event["time"]:
			# For overlapping events
			if final_events:
				if event["time"] == final_events[0]["time"]:
					final_events.append(event)
				else:
					final_events = [event]
			else:
				final_events = [event]
	return final_events

func _find_matching_by_note_on(note_ons:Array[float],time:float):
	for i in note_ons.size():
		var on = note_ons[i]
		if time < on: break
		var end_bar = on + tmb.notes[i][TMBInfo.NOTE_LENGTH]
		if time >= on && time <= end_bar: return tmb.notes[i]
	return []
