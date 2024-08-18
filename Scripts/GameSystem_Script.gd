extends Node
class_name GameSystem
#region VARIABLES
@export var player : Player
@export var playerText : Label
@export var pauseLabel : Label
#endregion
#-------------------------------------------------------------------------------
#region MONOVEHAVIOUR
func _ready():
	PauseOff()
#-------------------------------------------------------------------------------
func _process(_delta: float):
	playerText.text = player.ShowPlayerInfo()
	playerText.text += "fps: " + str(Engine.get_frames_per_second())   
	Set_FullScreen()
	Set_Vsync()
	ResetGame()
	PauseGame()
#endregion
#-------------------------------------------------------------------------------
#region FUNCTIONS
func Set_FullScreen() -> void:
	if(Input.is_action_just_pressed("Debug_FullScreen")):
		var _wm: DisplayServer.WindowMode = DisplayServer.window_get_mode()
		if(_wm == DisplayServer.WINDOW_MODE_FULLSCREEN):
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
#-------------------------------------------------------------------------------
func Set_Vsync() -> void:
	if(Input.is_action_just_pressed("Debug_Vsync")):
		var _vs: DisplayServer.VSyncMode = DisplayServer.window_get_vsync_mode()
		if(_vs == DisplayServer.VSYNC_DISABLED):
			DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
		elif(_vs == DisplayServer.VSYNC_ENABLED):
			DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
#-------------------------------------------------------------------------------
func ResetGame() -> void:
	if(Input.is_action_just_pressed("Debug_Reset")):
		get_tree().reload_current_scene()
#-------------------------------------------------------------------------------
func PauseGame() -> void:
	if(Input.is_action_just_pressed("Input_Pause")):
		if(get_tree().paused):
			PauseOff()
		else:
			pauseLabel.show()
			get_tree().set_deferred("paused", true)
#-------------------------------------------------------------------------------
func PauseOff():
	pauseLabel.hide()
	get_tree().set_deferred("paused", false)
#endregion
#-------------------------------------------------------------------------------
