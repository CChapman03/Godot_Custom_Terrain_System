extends Node3D

func _ready():
	#Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	$Terrain.player_transform = $Player.transform
	$Terrain.player_head_transform = $Player/Head.transform

func _input(event):
	if event.is_action_pressed('ui_cancel'):
		get_tree().quit()

func _process(delta):
	if Engine.get_process_frames() % 2 == 0:
		$Terrain.player_transform = $Player.transform
		$Terrain.player_head_transform = $Player/Head.transform
