extends Node3D

func _ready():
	#Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	$Player_3RD.transform.origin.y = $Terrain.get_height($Player_3RD.transform.origin.x, $Player_3RD.transform.origin.z)
	
	#print($Terrain.get_height($Player_3RD.transform.origin.x, $Player_3RD.transform.origin.z))
	
	$Terrain.player_transform = $Player_3RD.transform
	$Terrain.player_head_transform = $Player_3RD.transform

func _input(event):
	if event.is_action_pressed('ui_cancel'):
		get_tree().quit()
	#pass

func _process(delta):
	if Engine.get_process_frames() % 4 == 0:
		$Terrain.player_transform = $Player_3RD.transform
		$Terrain.player_head_transform = $Player_3RD.transform
