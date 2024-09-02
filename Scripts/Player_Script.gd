extends CharacterBody2D
class_name Player
#-------------------------------------------------------------------------------
enum PLAYER_STATE{IDLE}
enum COLLISION_STATE{GROUND, AIR, WALL}
enum GROUND_STATE{STAND, MOVE}
enum HORIZONTAL_STATE{MIDDLE, LEFT, RIGHT}
enum JUMP_STATE{LIGHT_JUMP, HEAVY_JUMP, FALL, TERMINAL_VELOCITY}
#region VARIABLES
#-------------------------------------------------------------------------------
# State Machine
var myPLAYER_STATE : PLAYER_STATE = PLAYER_STATE.IDLE
var myCOLLISION_STATE : COLLISION_STATE = COLLISION_STATE.GROUND
var myGROUND_STATE : GROUND_STATE = GROUND_STATE.MOVE
var myHORIZONTAL_STATE : HORIZONTAL_STATE = HORIZONTAL_STATE.RIGHT
var myJUMP_STATE : JUMP_STATE = JUMP_STATE.FALL
#-------------------------------------------------------------------------------
# Flags
var leftWallCol : Array[Node2D]
var rightWallCol : Array[Node2D]
#-------------------------------------------------------------------------------
# Nodes
@export var camera_2d : Camera2D
@export var cameraMarker : Marker2D
@export var sprite_2d : Sprite2D
@export var leftWall_Area2D: Area2D
@export var rightWall_Area2D: Area2D
const velocityLimitX_Wall : float = 0.1		#Evita reentrar a wall cuando se salto en paredes
var deltaTimeScale: float = 1
#-------------------------------------------------------------------------------
# Inputs
var movementInput : Vector2 = Vector2.ZERO
const jump_Input : String = "Input_Jump"
#-------------------------------------------------------------------------------
# Jump State Variables
const jumpPower : float = -300.0
const terminalVelocity : float = 200.0
const terminalWallVelocity : float = 60.0
#-------------------------------------------------------------------------------
# Speeds
const ground_Speed : float = 150.0
const lightJump_Speed : float = 150.0
const heavyJump_Speed : float = 150.0
const fall_Speed : float = 150.0
const terminalVelocity_Speed : float = 150.0
#-------------------------------------------------------------------------------
# Wight
const ground_Weight : float = 0.3
const lightJump_Weight : float = 0.15
const heavyJump_Weight : float = 0.15
const fall_Weight : float = 0.15
const terminalVelocity_Weight : float = 0.15
#-------------------------------------------------------------------------------
# Gravity Scale
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
const lightJump_GravityScale : float = 0.8
const heavyJump_GravityScale : float = 1.6
const fall_GravityScale : float = 1.2
#-------------------------------------------------------------------------------
# Anim Name
@export var animation_tree : AnimationTree
@onready var playback : AnimationNodeStateMachinePlayback = animation_tree.get("parameters/StateMachine/playback")
const animName_Idle : String = "Idle"
const animName_Run : String = "Run"
const animName_Jump : String = "Jump"
const animName_Fall : String = "Fall"
const animName_Wall : String = "Wall"
#endregion
#-------------------------------------------------------------------------------
#region MONOVEHAVIOUR
func _ready() -> void:
	pass
#-------------------------------------------------------------------------------
func _physics_process(_delta:float) -> void:
	deltaTimeScale = Engine.time_scale
	movementInput = Vector2(Input.get_axis("ui_left", "ui_right"), Input.get_axis("ui_up", "ui_down")).normalized()
	camera_2d.position = lerp(camera_2d.position, cameraMarker.global_position, 0.1 * deltaTimeScale)
	leftWallCol = leftWall_Area2D.get_overlapping_bodies()
	rightWallCol = rightWall_Area2D.get_overlapping_bodies()
	#-------------------------------------------------------------------------------
	match(myPLAYER_STATE):
		PLAYER_STATE.IDLE:
			match(myCOLLISION_STATE):
				COLLISION_STATE.GROUND:
					match(myGROUND_STATE):
						GROUND_STATE.STAND:
							Horizontal_Input(_delta, ground_Speed, ground_Weight)
							RotateSprite_To_GroundNormal()
							move_and_slide()
							#-------------------------------------------------------------------------------
							if(!is_on_floor()):
								EnterFall()
								return
							if(Input.is_action_just_pressed(jump_Input)):
								GroundJump()
								return
							if(movementInput.x < 0.0):
								myGROUND_STATE = GROUND_STATE.MOVE
								PlayAnimation(animName_Run)
								FlipSpriteLeft()
								return
							if(movementInput.x > 0.0):
								myGROUND_STATE = GROUND_STATE.MOVE
								PlayAnimation(animName_Run)
								FlipSpriteRight()
								return
						#-------------------------------------------------------------------------------
						GROUND_STATE.MOVE:
							match(myHORIZONTAL_STATE):
								HORIZONTAL_STATE.LEFT:
									Horizontal_Input(_delta, ground_Speed, ground_Weight)
									RotateSprite_To_GroundNormal()
									move_and_slide()
									#-------------------------------------------------------------------------------
									if(!is_on_floor()):
										EnterFall()
										return
									if(Input.is_action_just_pressed(jump_Input)):
										GroundJump()
										return
									if(movementInput.x >= 0.0):
										myGROUND_STATE = GROUND_STATE.STAND
										PlayAnimation(animName_Idle)
										return
								#-------------------------------------------------------------------------------
								HORIZONTAL_STATE.RIGHT:
									Horizontal_Input(_delta, ground_Speed, ground_Weight)
									RotateSprite_To_GroundNormal()
									move_and_slide()
									#-------------------------------------------------------------------------------
									if(!is_on_floor()):
										EnterFall()
										return
									if(Input.is_action_just_pressed(jump_Input)):
										GroundJump()
										return
									if(movementInput.x <= 0.0):
										myGROUND_STATE = GROUND_STATE.STAND
										PlayAnimation(animName_Idle)
										return
								#-------------------------------------------------------------------------------
						#-------------------------------------------------------------------------------
					#-------------------------------------------------------------------------------
				#-------------------------------------------------------------------------------
				COLLISION_STATE.AIR:
					match(myJUMP_STATE):
						JUMP_STATE.LIGHT_JUMP:
							match(myHORIZONTAL_STATE):
								HORIZONTAL_STATE.LEFT:
									Horizontal_Input(_delta, lightJump_Speed, lightJump_Weight)
									ApplyGravity(_delta, lightJump_GravityScale)
									move_and_slide()
									#-------------------------------------------------------------------------------
									if(Input.is_action_just_released(jump_Input)):
										myJUMP_STATE = JUMP_STATE.HEAVY_JUMP
										return
									if(leftWallCol && velocity.x <= velocityLimitX_Wall):
										EnterLeftWall()
										return
									if(rightWallCol && velocity.x >= -velocityLimitX_Wall):
										EnterRightWall()
										return
									if(velocity.y >= 0.0):
										PlayAnimation(animName_Fall)
										myJUMP_STATE = JUMP_STATE.FALL
										return
									if(velocity.x > 0.0):
										FlipSpriteRight()
										return
								#-------------------------------------------------------------------------------
								HORIZONTAL_STATE.RIGHT:
									Horizontal_Input(_delta, lightJump_Speed, lightJump_Weight)
									ApplyGravity(_delta, lightJump_GravityScale)
									move_and_slide()
									#-------------------------------------------------------------------------------
									if(Input.is_action_just_released(jump_Input)):
										myJUMP_STATE = JUMP_STATE.HEAVY_JUMP
										return
									if(leftWallCol && velocity.x <= velocityLimitX_Wall):
										EnterLeftWall()
										return
									if(rightWallCol && velocity.x >= -velocityLimitX_Wall):
										EnterRightWall()
										return
									if(velocity.y >= 0.0):
										PlayAnimation(animName_Fall)
										myJUMP_STATE = JUMP_STATE.FALL
										return
									if(velocity.x < 0.0):
										FlipSpriteLeft()
										return
								#-------------------------------------------------------------------------------
							#-------------------------------------------------------------------------------
						#-------------------------------------------------------------------------------
						JUMP_STATE.HEAVY_JUMP:
							match(myHORIZONTAL_STATE):
								HORIZONTAL_STATE.LEFT:
									Horizontal_Input(_delta, heavyJump_Speed, heavyJump_Weight)
									ApplyGravity(_delta, heavyJump_GravityScale)
									move_and_slide()
									#-------------------------------------------------------------------------------
									if(leftWallCol && velocity.x <= velocityLimitX_Wall):
										EnterLeftWall()
										return
									if(rightWallCol && velocity.x >= -velocityLimitX_Wall):
										EnterRightWall()
										return
									#if(Input.is_action_just_pressed(jump_Input)):
										#GroundJump()
										#return
									if(velocity.y >= 0.0):
										PlayAnimation(animName_Fall)
										myJUMP_STATE = JUMP_STATE.FALL
										return
									if(velocity.x > 0.0):
										FlipSpriteRight()
										return
								#-------------------------------------------------------------------------------
								HORIZONTAL_STATE.RIGHT:
									Horizontal_Input(_delta, heavyJump_Speed, heavyJump_Weight)
									ApplyGravity(_delta, heavyJump_GravityScale)
									move_and_slide()
									#-------------------------------------------------------------------------------
									if(leftWallCol && velocity.x <= velocityLimitX_Wall):
										EnterLeftWall()
										return
									if(rightWallCol && velocity.x >= -velocityLimitX_Wall):
										EnterRightWall()
										return
									#if(Input.is_action_just_pressed(jump_Input)):
										#GroundJump()
										#return
									if(velocity.y >= 0.0):
										PlayAnimation(animName_Fall)
										myJUMP_STATE = JUMP_STATE.FALL
										return
									if(velocity.x < 0.0):
										FlipSpriteLeft()
										return
								#-------------------------------------------------------------------------------
							#-------------------------------------------------------------------------------
						#-------------------------------------------------------------------------------
						JUMP_STATE.FALL:
							match(myHORIZONTAL_STATE):
								HORIZONTAL_STATE.LEFT:
									Horizontal_Input(_delta, fall_Speed, fall_Weight)
									ApplyGravity(_delta, fall_GravityScale)
									move_and_slide()
									#-------------------------------------------------------------------------------
									if(is_on_floor()):
										EnterGround()
										return
									if(leftWallCol && velocity.x <= velocityLimitX_Wall):
										velocity.y = terminalWallVelocity
										EnterLeftWall()
										return
									if(rightWallCol && velocity.x >= -velocityLimitX_Wall):
										velocity.y = terminalWallVelocity
										EnterRightWall()
										return
									#if(Input.is_action_just_pressed(jump_Input)):
										#GroundJump()
										#return
									if(velocity.y > terminalVelocity):
										velocity.y = terminalVelocity
										myJUMP_STATE = JUMP_STATE.TERMINAL_VELOCITY
										return
								#-------------------------------------------------------------------------------
								HORIZONTAL_STATE.RIGHT:
									Horizontal_Input(_delta, fall_Speed, fall_Weight)
									ApplyGravity(_delta, fall_GravityScale)
									move_and_slide()
									#-------------------------------------------------------------------------------
									if(is_on_floor()):
										EnterGround()
										return
									if(leftWallCol && velocity.x <= velocityLimitX_Wall):
										velocity.y = terminalWallVelocity
										EnterLeftWall()
										return
									if(rightWallCol && velocity.x >= -velocityLimitX_Wall):
										velocity.y = terminalWallVelocity
										EnterRightWall()
										return
									#if(Input.is_action_just_pressed(jump_Input)):
										#GroundJump()
										#return
									if(velocity.y > terminalVelocity):
										velocity.y = terminalVelocity
										myJUMP_STATE = JUMP_STATE.TERMINAL_VELOCITY
										return
									if(velocity.x < 0.0):
										FlipSpriteLeft()
										return
								#-------------------------------------------------------------------------------
						JUMP_STATE.TERMINAL_VELOCITY:
							match(myHORIZONTAL_STATE):
								HORIZONTAL_STATE.LEFT:
									Horizontal_Input(_delta, terminalVelocity_Speed, terminalVelocity_Weight)
									move_and_slide()
									#-------------------------------------------------------------------------------
									if(is_on_floor()):
										EnterGround()
										return
									if(leftWallCol && velocity.x <= velocityLimitX_Wall):
										velocity.y = terminalWallVelocity
										EnterLeftWall()
										return
									if(rightWallCol && velocity.x >= -velocityLimitX_Wall):
										velocity.y = terminalWallVelocity
										EnterRightWall()
										return
									#if(Input.is_action_just_pressed(jump_Input)):
										#GroundJump()
										#return
									if(velocity.y < terminalVelocity):
										myJUMP_STATE = JUMP_STATE.FALL
										return
									if(velocity.x > 0.0):
										FlipSpriteRight()
										return
								#-------------------------------------------------------------------------------
								HORIZONTAL_STATE.RIGHT:
									Horizontal_Input(_delta, terminalVelocity_Speed, terminalVelocity_Weight)
									move_and_slide()
									#-------------------------------------------------------------------------------
									if(is_on_floor()):
										EnterGround()
										return
									if(leftWallCol && velocity.x <= velocityLimitX_Wall):
										velocity.y = terminalWallVelocity
										EnterLeftWall()
										return
									if(rightWallCol && velocity.x >= -velocityLimitX_Wall):
										velocity.y = terminalWallVelocity
										EnterRightWall()
										return
									#if(Input.is_action_just_pressed(jump_Input)):
										#GroundJump()
										#return
									if(velocity.y < terminalVelocity):
										myJUMP_STATE = JUMP_STATE.FALL
										return
									if(velocity.x < 0.0):
										FlipSpriteLeft()
								#-------------------------------------------------------------------------------
							#-------------------------------------------------------------------------------
						#-------------------------------------------------------------------------------
					#-------------------------------------------------------------------------------
				#-------------------------------------------------------------------------------
				COLLISION_STATE.WALL:
					match(myJUMP_STATE):
						JUMP_STATE.LIGHT_JUMP:
							match(myHORIZONTAL_STATE):
								HORIZONTAL_STATE.LEFT:
									Horizontal_Input(_delta, lightJump_Speed, lightJump_Weight)
									ApplyGravity(_delta, lightJump_GravityScale)
									move_and_slide()
									if(Input.is_action_just_released(jump_Input)):
										myJUMP_STATE = JUMP_STATE.HEAVY_JUMP
										return
									if(!leftWallCol):
										ExitLeftWall()
										return
									if(velocity.y >= 0.0):
										myJUMP_STATE = JUMP_STATE.FALL
										return
								#-------------------------------------------------------------------------------
								HORIZONTAL_STATE.RIGHT:
									Horizontal_Input(_delta, lightJump_Speed, lightJump_Weight)
									ApplyGravity(_delta, lightJump_GravityScale)
									move_and_slide()
									if(Input.is_action_just_released(jump_Input)):
										myJUMP_STATE = JUMP_STATE.HEAVY_JUMP
										return
									if(!rightWallCol):
										ExitRightWall()
										return
									if(velocity.y >= 0.0):
										myJUMP_STATE = JUMP_STATE.FALL
										return
								#-------------------------------------------------------------------------------
							#-------------------------------------------------------------------------------
						#-------------------------------------------------------------------------------
						JUMP_STATE.HEAVY_JUMP:
							match(myHORIZONTAL_STATE):
								HORIZONTAL_STATE.LEFT:
									Horizontal_Input(_delta, heavyJump_Speed, heavyJump_Weight)
									ApplyGravity(_delta, heavyJump_GravityScale)
									move_and_slide()
									if(Input.is_action_just_pressed(jump_Input)):
										LeftWallJump()
										return
									if(!leftWallCol):
										ExitLeftWall()
										return
									if(velocity.y >= 0.0):
										myJUMP_STATE = JUMP_STATE.FALL
										return
								#-------------------------------------------------------------------------------
								HORIZONTAL_STATE.RIGHT:
									Horizontal_Input(_delta, heavyJump_Speed, heavyJump_Weight)
									ApplyGravity(_delta, heavyJump_GravityScale)
									move_and_slide()
									if(Input.is_action_just_pressed(jump_Input)):
										RightWallJump()
										return
									if(!rightWallCol):
										ExitRightWall()
										return
									if(velocity.y >= 0.0):
										myJUMP_STATE = JUMP_STATE.FALL
										return
								#-------------------------------------------------------------------------------
						JUMP_STATE.FALL:
							match(myHORIZONTAL_STATE):
								HORIZONTAL_STATE.LEFT:
									Horizontal_Input(_delta, fall_Speed, fall_Weight)
									ApplyGravity(_delta, fall_GravityScale)
									move_and_slide()
									if(Input.is_action_just_pressed(jump_Input)):
										LeftWallJump()
										return
									if(is_on_floor()):
										EnterGround()
										return
									if(!leftWallCol):
										ExitLeftWall()
										return
									if(velocity.y > terminalWallVelocity):
										velocity.y = terminalWallVelocity
										myJUMP_STATE = JUMP_STATE.TERMINAL_VELOCITY
										return
								#-------------------------------------------------------------------------------
								HORIZONTAL_STATE.RIGHT:
									Horizontal_Input(_delta, fall_Speed, fall_Weight)
									ApplyGravity(_delta, fall_GravityScale)
									move_and_slide()
									if(Input.is_action_just_pressed(jump_Input)):
										RightWallJump()
										return
									if(is_on_floor()):
										EnterGround()
										return
									if(!rightWallCol):
										ExitRightWall()
										return
									if(velocity.y > terminalWallVelocity):
										velocity.y = terminalWallVelocity
										myJUMP_STATE = JUMP_STATE.TERMINAL_VELOCITY
										return
								#-------------------------------------------------------------------------------
							#-------------------------------------------------------------------------------
						#-------------------------------------------------------------------------------
						JUMP_STATE.TERMINAL_VELOCITY:
							match(myHORIZONTAL_STATE):
								HORIZONTAL_STATE.LEFT:
									Horizontal_Input(_delta, terminalVelocity_Speed, terminalVelocity_Weight)
									move_and_slide()
									if(Input.is_action_just_pressed(jump_Input)):
										LeftWallJump()
										return
									if(is_on_floor()):
										EnterGround()
										return
									if(!leftWallCol):
										ExitLeftWall()
										return
									if(velocity.y < terminalWallVelocity):
										myJUMP_STATE = JUMP_STATE.FALL
										return
								#-------------------------------------------------------------------------------
								HORIZONTAL_STATE.RIGHT:
									Horizontal_Input(_delta, terminalVelocity_Speed, terminalVelocity_Weight)
									move_and_slide()
									if(Input.is_action_just_pressed(jump_Input)):
										RightWallJump()
										return
									if(is_on_floor()):
										EnterGround()
										return
									if(!rightWallCol):
										ExitRightWall()
										return
									if(velocity.y < terminalWallVelocity):
										myJUMP_STATE = JUMP_STATE.FALL
										return
								#-------------------------------------------------------------------------------
							#-------------------------------------------------------------------------------
						#-------------------------------------------------------------------------------
					#-------------------------------------------------------------------------------
				#-------------------------------------------------------------------------------
			#-------------------------------------------------------------------------------
		#-------------------------------------------------------------------------------
	#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
#endregion
#-------------------------------------------------------------------------------
#region STATEMACHINE FUNCTIONS
func ApplyGravity(_delta:float, _scale:float) -> void:
	velocity.y += gravity * _scale * _delta
#-------------------------------------------------------------------------------
func Horizontal_Input(_delta:float, _speed:float, _wight:float) -> void:
	var _f: float = _wight * deltaTimeScale
	if(movementInput.x):
		velocity.x = lerp(velocity.x, movementInput.x * _speed, _f)
	else:
		velocity.x = lerp(velocity.x, 0.0, _f)
#-------------------------------------------------------------------------------
func FlipSpriteLeft() -> void:
	myHORIZONTAL_STATE = HORIZONTAL_STATE.LEFT
	sprite_2d.scale.x = -1
#-------------------------------------------------------------------------------
func FlipSpriteRight() -> void:
	myHORIZONTAL_STATE = HORIZONTAL_STATE.RIGHT
	sprite_2d.scale.x = 1
#-------------------------------------------------------------------------------
func RotateSprite_To_GroundNormal() -> void:
	var _a := Vector2.UP
	sprite_2d.rotation = _a.angle_to(get_floor_normal())
#-------------------------------------------------------------------------------
func GroundJump() -> void:
	velocity.y = jumpPower
	JumpCommon()
#-------------------------------------------------------------------------------
func LeftWallJump() -> void:
	WallJump(-1.5, 1.0)
	sprite_2d.scale.x = 1
#-------------------------------------------------------------------------------
func RightWallJump() -> void:
	WallJump(1.5, 1.0)
	sprite_2d.scale.x = -1
#-------------------------------------------------------------------------------
func WallJump(_x : float, _y : float) -> void:
	velocity = Vector2(_x, _y) * jumpPower
	JumpCommon()
#-------------------------------------------------------------------------------
func JumpCommon():
	sprite_2d.rotation = 0.0
	PlayAnimation(animName_Jump)
	myCOLLISION_STATE = COLLISION_STATE.AIR
	myJUMP_STATE = JUMP_STATE.LIGHT_JUMP
#-------------------------------------------------------------------------------
func EnterFall() -> void:
	PlayAnimation(animName_Fall)
	sprite_2d.rotation = 0.0
	myCOLLISION_STATE = COLLISION_STATE.AIR
	myJUMP_STATE = JUMP_STATE.FALL
#-------------------------------------------------------------------------------
func EnterGround() -> void:
	myCOLLISION_STATE = COLLISION_STATE.GROUND
	if(movementInput.x == 0.0):
		myGROUND_STATE = GROUND_STATE.STAND
		PlayAnimation(animName_Idle)
	else:
		myGROUND_STATE = GROUND_STATE.MOVE
		PlayAnimation(animName_Run)
#-------------------------------------------------------------------------------
func EnterLeftWall() -> void:
	myHORIZONTAL_STATE = HORIZONTAL_STATE.LEFT
	EnterWall()
	sprite_2d.scale.x = -1
#-------------------------------------------------------------------------------
func EnterRightWall() -> void:
	myHORIZONTAL_STATE = HORIZONTAL_STATE.RIGHT
	EnterWall()
	sprite_2d.scale.x = 1
#-------------------------------------------------------------------------------
func EnterWall() -> void:
	myCOLLISION_STATE = COLLISION_STATE.WALL
	PlayAnimation(animName_Wall)
#-------------------------------------------------------------------------------
func ExitLeftWall() -> void:
	ExitWall()
	if(velocity.x > 0):
		myHORIZONTAL_STATE = HORIZONTAL_STATE.RIGHT
		sprite_2d.scale.x = 1
#-------------------------------------------------------------------------------
func ExitRightWall() -> void:
	ExitWall()
	if(velocity.x < 0):
		myHORIZONTAL_STATE = HORIZONTAL_STATE.LEFT
		sprite_2d.scale.x = -1
#-------------------------------------------------------------------------------
func ExitWall() -> void:
	myCOLLISION_STATE = COLLISION_STATE.AIR
	if(velocity.y < 0.0):
		PlayAnimation(animName_Jump)
	else:
		PlayAnimation(animName_Fall)
#-------------------------------------------------------------------------------
func ShowPlayerInfo() -> String:
	var _s : String
	_s = "Player State: "
	_s += PLAYER_STATE.keys()[myPLAYER_STATE] + " "
	_s += COLLISION_STATE.keys()[myCOLLISION_STATE] + " "
	_s += GROUND_STATE.keys()[myGROUND_STATE] + " "
	_s += JUMP_STATE.keys()[myJUMP_STATE] + " "
	_s += HORIZONTAL_STATE.keys()[myHORIZONTAL_STATE] + "\n"
	_s += "Scale X: " + str(sprite_2d.scale.x) + "\n"
	_s += "Player Velocity: " + str(velocity) + "\n"
	_s += "Movement Input: " + str(movementInput) + "\n"
	_s += "Left Wall Flag: "+IsArrayEmpty(leftWallCol) + "\n"
	_s += "Right Wall Flag: "+IsArrayEmpty(rightWallCol) + "\n"
	return _s
#-------------------------------------------------------------------------------
func IsArrayEmpty(_array: Array[Node2D]) -> String:
	if(_array):
		return "true"
	else:
		return "false"
#-------------------------------------------------------------------------------
#endregion
#-------------------------------------------------------------------------------
func PlayAnimation(_s: String):
	#playback.travel(_s)
	playback.call_deferred("travel", _s)
#-------------------------------------------------------------------------------
