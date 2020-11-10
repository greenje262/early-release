extends Spatial

const DOOR_ONE = Vector3(9, 0, 4)
const THRESH = Vector3(19, 0, 2)
const KEYS = Vector3(37, 0, 8)
const DOOR_TWO = Vector3(9, 0, 0)
const EXIT = Vector3(-5, 0, 2)

onready var game_started = false
onready var objective
onready var phase
onready var audio = $Prisoner/AudioStreamPlayer3D
onready var tween = $Prisoner/AudioStreamPlayer3D/VoiceTween

var room_enter = false
var hall_enter = false
var key_close = false
var key_get = false
var win = false

func _ready():
	yield(get_tree(), "idle_frame")
	phase = 0
	speaks(phase)

func _process(delta):	
	if Input.is_action_just_pressed("start_game") && $Player.start == false:
		$Player.start = true
		yield(get_tree().create_timer(1), "timeout")
		phase = 1
		speaks(phase)
		
		objective = DOOR_ONE
		
		yield(get_tree().create_timer(9), "timeout")
		phase = 2
		speaks(phase)
		
		yield(get_tree().create_timer(1), "timeout")
		$HelpTimer.start()
	
	if Input.is_action_just_pressed("quit"):
		get_tree().quit()
	
	if Input.is_action_just_pressed("interact"):
		if abs($Walls/Key.translation.x - $Player.translation.x) < 3 && abs($Walls/Key.translation.z - $Player.translation.z) < 3 && key_get == false:
			key_get = true
			objective = DOOR_TWO
			phase = 5
			speaks(phase)
		
		if abs($Doors/JailDoor.translation.x - $Player.translation.x) < 3 && abs($Doors/JailDoor.translation.z - $Player.translation.z) < 3 && key_get == true:
			objective = EXIT
			$Doors/PrisonDoor.queue_free()
			phase = 6
			speaks(phase)
			yield(get_tree().create_timer(6), "timeout")
			$Prisoner.translation = Vector3(-7, 0, 2)

func _physics_process(delta):
	if $Player.translation.z < 4 && hall_enter == false:
		objective = THRESH
		hall_enter = true
	
	if $Player.translation.x > 19 && room_enter == false:
		objective = KEYS
		room_enter = true
		phase = 3
		speaks(phase)
	
	if $Walls/Key.translation.x - $Player.translation.x < 4 && $Walls/Key.translation.z - $Player.translation.z < 4 && key_close == false:
		key_close = true
		phase = 4
		speaks(phase)
	
	if $Player.translation.x < -5 && win == false:
		win = true
		phase = 7
		speaks(phase)
		yield(get_tree().create_timer(6), "timeout")
		win()

func _on_HelpTimer_timeout():
	$Player.transform.orthonormalized()
	if audio.playing == false:
		help_bark()

func help_bark():
	randomize()
	var sub = $Player/Spatial/Subtitle
	var clip
	var back_subs = ["Uh, it's behind you.",
		"You'll have to turn around.",
		"It's the other way.",
		"You're facing the wrong way."]
	var back_clips = ["res://audio/back1.ogg", "res://audio/back2.ogg", "res://audio/back3.ogg", "res://audio/back4.ogg"]
	var front_subs = ["That's it, straight ahead.",
		"You're facing straight toward it now.",
		"You're going the right way now.",
		"You're looking right at it."]
	var front_clips = ["res://audio/front1.ogg", "res://audio/front2.ogg", "res://audio/front3.ogg", "res://audio/front4.ogg"]
	
	var sub_type
	var index
	var obj_vec = $Player.translation.direction_to(objective)
	var look_vec = $Player.transform.basis.z
	
	if obj_vec.dot(look_vec) > -0.6:
		sub_type = "back"
	else:
		sub_type = "front"
	
	match sub_type:
		"back":
			index = randi() % len(back_subs)
			sub.text = back_subs[index]
			clip = back_clips[index]
		"front":
			index = randi() % len(front_subs)
			sub.text = front_subs[index]
			clip = front_clips[index]
	
	sub.show()
	say_something(clip)
	
	yield(get_tree().create_timer($Prisoner/AudioStreamPlayer3D.stream.get_length() + 1), "timeout")
	
	sub.hide()

func say_something(clip):
	if audio.playing == true:
		audio.stop()
	
	audio.unit_db = 80
	audio.stream = load(clip)
	audio.play(0)

func win():
	get_tree().quit()

func speaks(phase):
	var sub = $Player/Spatial/Subtitle
	var clip
	var phase_subs = ["Welcome to Early Release. You can use WASD to move, the mouse to look. Press J to interact with keys and doors. Press Escape to quit. You can begin the game anytime by pressing the space bar.",
		"Hey you, you're finally awake. Can you stand? Can you walk?",
		"Great, great, great. Okay, listen to me - we need to get out of here, and we don't have much time. Your cell door is open. All you need to do is walk through the next room and grab the ring of keys on the table. I'll guide you over there.",
		"Okay, you're in the next room. The keys are on a table in the far corner.",
		"That's it, the keys are right there on the table! Grab them and let's get out of here.",
		"Yes, finally, finally! Hurry on back - I'll help you out if you need it.",
		"Thank you friend, thank you, thank you. I'll take those keys and unlock the door ahead. Come with me!",
		"Well done. Now let's get out of here."]
	var phase_clip = ["res://audio/clip00.ogg", "res://audio/clip01.ogg", "res://audio/clip02.ogg", "res://audio/clip03.ogg", "res://audio/clip04.ogg", "res://audio/clip05.ogg", "res://audio/clip06.ogg", "res://audio/clip07.ogg"]
	
	sub.text = phase_subs[phase]
	sub.show()
	
	clip = phase_clip[phase]
	say_something(clip)
	
	yield(get_tree().create_timer($Prisoner/AudioStreamPlayer3D.stream.get_length() + 1), "timeout")
	
	sub.hide()
