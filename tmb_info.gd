class_name TMBInfo
# extends Node

# { bar, length, start_pitch, delta_pitch, end_pitch } all floats
enum {
	NOTE_BAR,
	NOTE_LENGTH,
	NOTE_PITCH_START,
	NOTE_PITCH_DELTA,
	NOTE_PITCH_END
}
enum {
	EVENT_SECONDS,
	EVENT_ID,
	EVENT_BEAT
}
enum LoadResult {
	SUCCESS,
	TMB_INVALID,
	FILE_ACCESS_ERROR,
}
var notes := []
# { bar:float, lyric:string }
var lyrics := []
var improv_zones := []
var bgdata := []
var color_events := []
var title		:= ""
var shortName	:= ""
var author		:= ""
var genre		:= ""
var description := ""
var trackRef    := ""
var year		: int = 1999
var tempo		: float = 120
var endpoint	: int = 4
var timesig 	: int = 2
var difficulty	: int = 5
var savednotespacing : int = 120

func has_note_touching_endpoint() -> bool:
	if notes.is_empty(): return false
	var last_note = notes[-1]
	return (last_note[NOTE_BAR] + last_note[NOTE_LENGTH] == endpoint)


static func load_result_string(result:int) -> String:
	match result:
		LoadResult.SUCCESS: return "Loaded successfully"
		LoadResult.TMB_INVALID: return "Invalid TMB"
		LoadResult.FILE_ACCESS_ERROR: return "File access error (see console)"
		_: return "Unknown error %d" % result


func find_all_notes_in_section(start:float,length:float) -> Array:
	var result := []
	var note_array = notes.duplicate(true)
	var is_in_section := func(bar:float) -> bool:
		return (bar > start && bar < start + length)
	for note in note_array:
		var bar = note[NOTE_BAR]
		var end = bar + note[NOTE_LENGTH]
		if !is_in_section.call(bar) && !is_in_section.call(end): continue
		note[NOTE_BAR] -= start
		result.append(note)
	return result

func find_all_color_events_in_section(start:float,length:float) -> Array:
	var result := []
	var event_array = color_events.duplicate(true)
	var is_in_section := func(bar:float) -> bool:
		return (bar > start && bar < start + length)
	var count = len(event_array)
	for i in range(count):
		var event = event_array[i]
		var bar = Global.time_to_beat(event.time)
		if !is_in_section.call(bar): continue
		event.time = bar - start
		result.append(event)
	return result

func clear_section(start:float,length:float):
	var is_in_section := func(bar:float) -> bool:
		return (bar > start && bar < start + length)
	print("Clear section %d - %d" % [start,length + start])
	var note_array = notes.duplicate(true)
	
	var any_notes_left : bool = true
	while any_notes_left:
		for note in note_array:
			var bar = note[NOTE_BAR]
			var end = bar + note[NOTE_LENGTH]
			# print("%d notes left" % note_array.size())
			if is_in_section.call(bar) || is_in_section.call(end):
				# print("Erase note @ %.3f" % bar)
				note_array.erase(note)
				if note_array.is_empty(): any_notes_left = false
				break # start from the beginning of the array
			
			if note == note_array.back(): any_notes_left = false
	notes = note_array

func clear_color_events_section(start:float,length:float):
	var is_in_section := func(bar:float) -> bool:
		return (bar > start && bar < start + length)
	print("Clear section %d - %d" % [start,length + start])
	var event_array = color_events.duplicate(true)
	
	var any_events_left : bool = true
	while any_events_left:
		for i in len(event_array):
			var event = event_array[i]
			var bar = Global.time_to_beat(event.time)
			# print("%d notes left" % event_array.size())
			if is_in_section.call(bar):
				# print("Erase event @ %.3f" % bar)
				event_array.erase(event)
				if event_array.is_empty(): any_events_left = false
				break # start from the beginning of the array
			
			if event == event_array.back(): any_events_left = false
	color_events = event_array

func sort_id_ascending(a, b):
	if a["id"] < b["id"]:
		return true
	return false

func auto_sort_color_events():
	# aims to sort events vertically in instances where that metadata is unavailable
	var grouped_events = {}
	var sorted_array = []
	for event in color_events:
		var events = grouped_events.get_or_add(str(event.time), [])
		events.append(event)
		grouped_events[str(event.time)] = events
	
	var keys = grouped_events.keys()
	keys.sort()
	for time in keys:
		var events = grouped_events[time]
		events.sort_custom(sort_id_ascending)
		var count = events.size()
		var events_sorted = []
		for i in range(count):
			var event = events[i]
			event["pitch"] = clamp(137.5 - (Global.SEMITONE * i), Global.SEMITONE * -13, Global.SEMITONE * 13)
			events_sorted.append(event)
		sorted_array.append(events_sorted)
	
	color_events = sorted_array

func load_from_file(filename:String) -> int:
	var f = FileAccess.open(filename,FileAccess.READ)
	var err = f.get_open_error()
	if err:
		print(error_string(err))
		return LoadResult.FILE_ACCESS_ERROR
	
	var j = JSON.new()
	err = j.parse(f.get_as_text())
	if err:
		print("%s\t| line %d\t| %s" % [
				error_string(err), j.get_error_line() + 1, j.get_error_message()
		])
		return LoadResult.TMB_INVALID
	
	var data = j.data
	if typeof(data) != TYPE_DICTIONARY:
		print("JSON got back object of type %s" % typeof(data))
		return LoadResult.TMB_INVALID
	
	notes		= data.notes as Array[Dictionary]
	lyrics		= data.lyrics as Array[Dictionary]
	
	title		= data.name
	shortName	= data.shortName
	author		= data.author
	genre		= data.genre
	description = data.description
	trackRef    = data.trackRef
	
	year		= int(data.year)
	tempo		= data.tempo
	endpoint	= data.endpoint
	timesig 	= data.timesig
	difficulty	= data.difficulty
	savednotespacing = data.savednotespacing

	if data.has('bgdata'):
		bgdata = data.bgdata
	else:
		bgdata = []
	if data.has('improv_zones') && data['improv_zones'] is Array:
		improv_zones = data.improv_zones
	else:
		improv_zones = []
	if data.has('color_events'):
		color_events = data.color_events
	else:
		color_events = []
	
	if data.has("note_color_start"):
		Global.settings.use_custom_colors = true
		Global.settings.start_color = Color(
			data["note_color_start"][0],
			data["note_color_start"][1],
			data["note_color_start"][2]
		)
		Global.settings.end_color = Color(
			data["note_color_end"][0],
			data["note_color_end"][1],
			data["note_color_end"][2]
		)
	
	var m = FileAccess.open(filename + ".chartermeta",FileAccess.READ)
	if m:
		var meta_err = m.get_open_error()
		if !meta_err:
			var metajson = JSON.new()
			err = metajson.parse(m.get_as_text())
			if err:
				auto_sort_color_events()
			else:
				var metadata = metajson.data
				if typeof(metadata) == TYPE_DICTIONARY:
					# convert old format, TODO: remove this when it's no longer needed
					if not metadata.get("color_pos"):
						auto_sort_color_events()
					elif metadata.color_pos is Array:
						for i in len(color_events):
							# var event = color_events[i]
							# var pos = metadata.color_pos[i]
							# var positions = color_event_pos.get(str(event.time), [])
							# positions.append([event.id, pos])
							# color_event_pos[str(event.time)] = positions
							var event = color_events[i]
							event["pitch"] = metadata.color_pos[i]
							color_events[i] = event
					else:
						for i in range(color_events.size()):
							var event = color_events[i]
							event["pitch"] = 137.5
							var positions = metadata.color_pos.get(str(event.time), [])
							if positions:
								for position in positions:
									if position[0] == event.id:
										event["pitch"] = position[1]
				else:
					auto_sort_color_events()
		else:
			auto_sort_color_events()
	
	return LoadResult.SUCCESS


func save_to_file(filename : String) -> int:
	print("try save tmb to %s" % filename)
	var f = FileAccess.open(filename,FileAccess.WRITE)
	if f == null:
		var err = FileAccess.get_open_error()
		print(error_string(err))
		return err
	
	var dict := to_dict()
	# gdscript doesn't support keyword parameters 👎
	f.store_string(JSON.stringify(dict, "", false))
	print("finished saving")

	# TODO: save this data as custom data in the new TMB format
	if color_events:
		var m = FileAccess.open(filename + ".chartermeta",FileAccess.WRITE)
		if m == null:
			var err = FileAccess.get_open_error()
			print(error_string(err))
		else:
			var metadict := {}
			metadict["color_pos"] = {}
			for event in color_events:
				var position = metadict["color_pos"].get_or_add(str(event.time), [])
				position.append([event.id, event.pitch])
				metadict["color_pos"][str(event.time)] = position
			m.store_string(JSON.stringify(metadict))
			print("finished saving charter metadata")
	return OK

func to_dict() -> Dictionary:
	var dict := {}
	
	for value in Global.settings.values:
		if !(value is TextField || value is NumField): continue
		dict[value.json_key] = value.value
	
	for note in notes: if (note[NOTE_BAR] + note[NOTE_LENGTH]) > endpoint: notes.erase(note)
	for lyric in lyrics: if lyric.bar > endpoint: lyrics.erase(lyric)
	dict["description"] = description
	dict["notes"] = notes
	dict["lyrics"] = lyrics
	dict["improv_zones"] = improv_zones
	dict["bgdata"] = bgdata
	dict["color_events"] = color_events
	dict["UNK1"] = 0
	
	if Global.settings.use_custom_colors:
		var start_color =  Global.settings.start_color
		var end_color =  Global.settings.end_color
		dict["note_color_start"] = [
			start_color[0],
			start_color[1],
			start_color[2],
		]
		dict["note_color_end"] = [
			end_color[0],
			end_color[1],
			end_color[2],
		]
	
	return dict
