# Copyright (c) 2018 Ville Laine
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

extends KinematicBody

const DEAD_ZONE = 0.2 * 0.2
const ZERO_ANGLE = Vector2(-1, 0)

const NATURAL_TEMP_RISE = 4.0
const NATURAL_TEMP_DECREASE = 0.5
const COOLDOWN_TEMP_DECREASE_MAX = 10.0

enum Mode{
	IDLE
	WALK
	COOLDOWN
}


onready var mObject = $Spatial

var Dead setget ,isDead
func isDead():
	return Dead

var mMode
var mTemperature
var mCooldownTimer
var mSupercharged
onready var mLabel = get_node("../Label")


func Init():
	mMode = Mode.IDLE
	Dead = false
	mTemperature = 20.0
	mSupercharged = false
	mLabel.text = str(mTemperature)

func _ready():
	Init()

func _physics_process(delta):
	if Dead:
		return
	
	if Input.is_action_just_pressed("cooldown"):
		# TODO: Play cooldown animation
		print("anim cooldown")
		mMode = Mode.COOLDOWN
		mCooldownTimer = 0
	if Input.is_action_just_released("cooldown"):
		# TODO: Play cooldown off animation
		print("anim cooldown off")
		mMode = Mode.IDLE
	
	if mMode == Mode.IDLE || mMode == Mode.WALK:
		var mvec = Vector3()
		if Input.is_action_pressed("move_north"):
			mvec.z -= 1
		if Input.is_action_pressed("move_south"):
			mvec.z += 1
		if Input.is_action_pressed("move_east"):
			mvec.x += 1
		if Input.is_action_pressed("move_west"):
			mvec.x -= 1
		
		var axis = Vector2(Input.get_joy_axis(0, JOY_ANALOG_LX), Input.get_joy_axis(0, JOY_ANALOG_LY))
		if axis.length_squared() >= DEAD_ZONE:
			mvec.x = axis.x
			mvec.z = axis.y
		mvec = mvec.normalized() * 4.0
		if mvec.length_squared() != 0:
			if mMode != Mode.WALK:
				# TODO: Play anim walk
				print("anim walk")
				mMode = Mode.WALK
			move_and_slide(mvec)
			mObject.rotation.y = Vector2(mvec.x, mvec.z).angle_to(ZERO_ANGLE)
		else:
			if mMode != Mode.IDLE:
				# TODO: Play anim idle
				print("anim idle")
				mMode = Mode.IDLE
	
	# Temperature control
	if mMode == Mode.WALK:
		mTemperature += NATURAL_TEMP_RISE * delta
	elif mMode == Mode.IDLE:
		if !mSupercharged:
			mTemperature -= NATURAL_TEMP_DECREASE * delta
	elif mMode == Mode.COOLDOWN:
		mCooldownTimer += delta * .2
		# TODO: Add nifty effect here
		mTemperature -= min(mCooldownTimer, COOLDOWN_TEMP_DECREASE_MAX)
	
	if mTemperature <= 0:
		# TODO: Play anim death
		print("anim death")
		Dead = true
		# TODO: Broadcast death
	mTemperature = clamp(mTemperature, 0, 100)
	
	if mTemperature >= 100:
		if !mSupercharged:
			# TODO: Play anim supercharge
			print("anim supercharge")
		mSupercharged = true
	else:
		if mSupercharged:
			# TODO: Play anim supercharge off
			print("anim supercharge off")
		mSupercharged = false
	
	mLabel.text = str(mTemperature)

