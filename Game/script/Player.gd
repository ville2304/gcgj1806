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

const PlayerAttackDamage = preload("res://PlayerAttackDamage.tscn")
const PlayerSuperAttackDamage = preload("res://PlayerSuperAttackDamage.tscn")


const DEAD_ZONE = 0.2 * 0.2
const ZERO_ANGLE = Vector2(-1, 0)
const WALKING_SPEED = 4.0

const NATURAL_TEMP_RISE = 2.0
const ATTACK_TEMP_RISE = 10.0
const DASH_TEMP_RISE = 10.0
const NATURAL_TEMP_DECREASE = 1.0
const SUPER_TEMP_DECREASE = 50.0
const BLOCK_TEMP_DECREASE = 10.0
const COOLDOWN_TEMP_DECREASE_MAX = 10.0

const DASH_COOLDOWN_TIME = 1.0
const BLOCK_COOLDOWN_TIME = 0.5

enum Mode{
	IDLE
	WALK
	COOLDOWN
	ATTACK1
	ATTACK2
	ATTACK3
	SUPER_ATTACK
	DASH
	DASH_ATTACK
	BLOCK
	DAMAGE
}


onready var mObject = $Spatial
onready var mAnimationPlayer = $Spatial/AnimationPlayer

var Dead setget ,isDead
func isDead():
	return Dead

var mMode
var mTemperature
var mTemperatureBuffer
var mCooldownTimer
var mSupercharged
var mAttackComplete
var mDashCooldown
var mBlockCooldown
onready var mLabel = get_node("../../Label")


func Init(pos):
	translation = pos
	mMode = Mode.IDLE
	Dead = false
	mTemperature = 20.0
	mTemperatureBuffer = 0.0
	mAttackComplete = true
	mSupercharged = false
	mDashCooldown = 0.0
	mBlockCooldown = 0.0
	mLabel.text = str(mTemperature, " ", mTemperatureBuffer)

func OnDamage(amount, push, origin):
	if mMode == Mode.SUPER_ATTACK:
		# We are immune here
		return
	if mMode == Mode.BLOCK:
		amount *= .2
		push *= .5
	elif mMode in [Mode.IDLE, Mode.WALK, Mode.COOLDOWN]:
		# Note how damage disrupts cooldown
		# TODO: Play anim
		print("anim damage")
		mMode = Mode.DAMAGE
		mMode = Mode.IDLE
	mTemperature -= amount

func _OnAnimationFinished(animName):
	if Dead:
		# TODO: Broadcast death
		print("Game over!")
		return
	if mMode in [Mode.ATTACK1, Mode.ATTACK2, Mode.ATTACK3, Mode.SUPER_ATTACK]:
		if mAttackComplete:
			# TODO: Play anim
			print("anim idle")
			mMode = Mode.IDLE
	elif mMode in [Mode.DASH, Mode.DASH_ATTACK]:
		mDashCooldown = DASH_COOLDOWN_TIME
		# TODO: Play anim
		print("anim idle")
		mMode = Mode.IDLE
	elif mMode == Mode.BLOCK:
		mBlockCooldown = BLOCK_COOLDOWN_TIME
		# TODO: Play anim
		print("anim idle")
		mMode = Mode.IDLE
	elif mMode == Mode.DAMAGE:
		# TODO: Play anim
		print("anim idle")
		mMode = Mode.IDLE

func _OnAttack(a):
	mAttackComplete = true
	if a <= 3:
		mTemperatureBuffer+= ATTACK_TEMP_RISE * a
		var dmg = PlayerAttackDamage.instance()
		dmg.amount = 5 * a * mTemperature
		dmg.translation = translation
		dmg.rotation = mObject.rotation
		if a == 3:
			dmg.tremor = .4
		get_parent().add_child(dmg)
	elif a == 10:
		# Super attack
		mTemperature -= SUPER_TEMP_DECREASE
		var dmg = PlayerSuperAttackDamage.instance()
		dmg.translation = translation
		dmg.amount = 50 * mTemperature
		get_parent().add_child(dmg)
	elif a == 11:
		# Dash attack
		mTemperatureBuffer+= ATTACK_TEMP_RISE * 2
		var dmg = PlayerAttackDamage.instance()
		dmg.amount = 10 * mTemperature
		dmg.translation = translation
		dmg.rotation = mObject.rotation
		if a == 3:
			dmg.tremor = .3
		get_parent().add_child(dmg)

func _ready():
	Init(Vector3())

func _physics_process(delta):
	if Dead:
		return
	mDashCooldown = max(0, mDashCooldown - delta)
	mBlockCooldown = max(0, mBlockCooldown - delta)
	
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
		mvec = mvec.normalized() * WALKING_SPEED
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
	if mTemperatureBuffer > 0:
		var value = min(mTemperatureBuffer, mTemperatureBuffer * delta * .5)
		mTemperatureBuffer-= value
		mTemperature+= value
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
	
	mLabel.text = "%.2f %.2f" % [mTemperature, mTemperatureBuffer]
	
	# Block
	if Input.is_action_just_pressed("block") && (mMode == Mode.IDLE || mMode == Mode.WALK):
		if mBlockCooldown > 0:
			# TODO: Add cue
			pass
		else:
			mTemperature -= BLOCK_TEMP_DECREASE
			mAnimationPlayer.play("Block")
			mMode = Mode.BLOCK
	
	# Dash
	if Input.is_action_just_pressed("dash") && (mMode == Mode.IDLE || mMode == Mode.WALK):
		_Dash()
	
	# Attack
	if Input.is_action_just_pressed("attack"):
		if mMode == Mode.DASH:
			# No supercharge attacks here
			mAnimationPlayer.queue("AttackDash")
			mMode = Mode.DASH_ATTACK
		elif mMode == Mode.IDLE || mMode == Mode.WALK:
			if mSupercharged:
				_SuperAttack(false)
			else:
				mAttackComplete = false
				mAnimationPlayer.play("Attack1")
				mMode = Mode.ATTACK1
		elif mMode == Mode.ATTACK1:
			if mAttackComplete:
				if mSupercharged:
					_SuperAttack(true)
				else:
					mAttackComplete = false
					mAnimationPlayer.queue("Attack2")
					mMode = Mode.ATTACK2
		elif mMode == Mode.ATTACK2:
			if mAttackComplete:
				if mSupercharged:
					_SuperAttack(true)
				else:
					mAttackComplete = false
					mAnimationPlayer.queue("Attack3")
					mMode = Mode.ATTACK3

func _SuperAttack(queue):
	mAttackComplete = false
	if queue:
		mAnimationPlayer.queue("AttackSuper")
	else:
		mAnimationPlayer.play("AttackSuper")
	mMode = Mode.SUPER_ATTACK

func _Dash():
	if mDashCooldown > 0:
		# TODO: Add cue
		return
	mTemperatureBuffer += DASH_TEMP_RISE
	var angle = mObject.rotation.y
	var direction = Vector3(-cos(angle), 0, sin(angle))
	move_and_collide(direction * 5)
	mAnimationPlayer.play("Dash")
	mMode = Mode.DASH


