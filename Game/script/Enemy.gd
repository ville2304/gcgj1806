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

const EnemyAttackDamage = preload("res://EnemyAttackDamage.tscn")
const TEXTURES = [
	preload("res://textures/IceGolemD3.png"),
	preload("res://textures/IceGolemD3.png"),
	preload("res://textures/IceGolemD2.png"),
	preload("res://textures/IceGolemD1.png"),
	preload("res://textures/IceGolem.png")
]


const ZERO_ANGLE = Vector2(-1, 0)
const WALKING_SPEED = 3.0 # Slightly lower than players'
const VISION_SQ = 5.0 * 5.0
const HALF_FOV = PI * .5
const MAX_SEARCH_TIME = 5.0
const MAX_DISTANCE_FROM_HOME_SQ = 3.0 * 3.0
const ATTACK_RANGE_SQ = 1.5 * 1.5
const ESCAPE_HP = 100
const HP_REGEN = 1.0
const ATTACK_COOLDOWN = 1.0

enum Mode{
	NONE
	IDLE
	WALK
	ALERT
	DAMAGE
	DEATH
	ATTACK
	FALL
}


var Target
var Dead

var mHome
var mEngaged
var mEscaping
var mSearchTime
var mTimer
var mAttackCooldown
var mMode
var mHP
var mMaxHP
var mDestination
var mMaterial

onready var mRaycast = $RayCast
onready var mObject = $Spatial
onready var mAnimationPlayer = $Spatial/Char/AnimationPlayer


func Init(pos):
	mHome = pos
	translation = pos
	
	Target = null
	mEngaged = false
	mEscaping = false
	mSearchTime = 0.0
	mTimer = 0.0
	mAttackCooldown = 0.0
	mMode = Mode.NONE
	
	mMaxHP = 500.0
	mHP = mMaxHP
	mDestination = null
	
	mObject.rotation.y = rand_range(0, 2 * PI)
	mMaterial = load("res://models/IceGolem.material")
	$Spatial/Char/IceGolemRig/Skeleton/IceGolem.material_override = mMaterial
	
	mAnimationPlayer.connect("animation_finished", self, "_OnAnimationFinished")

func OnDamage(amount, push, origin):
	if Dead:
		return
	mHP -= amount
	if !mMode in [Mode.IDLE, Mode.WALK]:
		return
	mAnimationPlayer.play("Damage")
	if !mEngaged:
		# Turn towards attacker
		mDestination = origin
	mMode = Mode.DAMAGE

func OnFall(origin):
	Dead = true
	translation = origin
	mAnimationPlayer.play("Fall")
	set_process(false)
	set_physics_process(false)
	mMode = Mode.FALL

func _OnAnimationFinished(animName):
	if Dead:
		get_parent().DestroyCharacter(self)
		return
	if mMode in [Mode.ALERT, Mode.DAMAGE]:
		mAnimationPlayer.play("Idle-loop")
		mMode = Mode.IDLE
	if mMode == Mode.ATTACK:
		mAttackCooldown = ATTACK_COOLDOWN
		mAnimationPlayer.play("Idle-loop")
		mMode = Mode.IDLE

func _OnAttack():
	var dmg = EnemyAttackDamage.instance()
	dmg.translation = translation
	dmg.rotation = mObject.rotation
	get_parent().add_child(dmg)

func _process(delta):
	if !Dead && mHP <= 0:
		Dead = true
		mAnimationPlayer.play("Die")
		mMode = Mode.DEATH
		set_process(false)
		set_physics_process(false)
		return
	mMaterial.albedo_texture = TEXTURES[clamp(int((mHP / mMaxHP) * TEXTURES.size()-1), 0, TEXTURES.size()-1)]
	_SearchTarget()

func _physics_process(delta):
	# For some reason axis locks do not work properly
	translation.y = 0
	
	mSearchTime = max(0, mSearchTime - delta)
	mTimer = max(0, mTimer - delta)
	mAttackCooldown = max(0, mAttackCooldown - delta)
	mHP = min(mHP + HP_REGEN * delta, mMaxHP)
	
	if mMode == Mode.ALERT || mMode == Mode.DAMAGE || mMode == Mode.ATTACK:
		return
		
	if mEngaged:
		_Engage()
	else:
		if mSearchTime > 0:
			# Just idle and turn around
			if mMode != Mode.IDLE:
				mAnimationPlayer.play("Idle-loop")
				mMode = Mode.IDLE
				mTimer = rand_range(0, 1)
			if mTimer <= 0:
				mObject.rotation.y = rand_range(0, 2 * PI)
				mTimer = rand_range(0, 1)
		else:
			_Loiter()

func _SearchTarget():
	mRaycast.enabled = false
	if mEscaping:
		return
	if Target != null && !Target.Dead:
		var tt = Target.translation
		var dvec = (tt - translation)
		dvec = Vector2(dvec.x, dvec.z)
		var angle = mObject.rotation.y
		var facing = Vector2(-cos(angle), sin(angle))
		if translation.distance_squared_to(tt) <= VISION_SQ && acos(clamp(dvec.normalized().dot(facing), -1, 1)) < HALF_FOV:
			mRaycast.enabled = true
			# TODO: Don't track centerpoint but random points within radius to see partial target
			mRaycast.cast_to = tt - translation
			if mRaycast.get_collider() == Target:
				if !mEngaged:
					mEngaged = true
					if mSearchTime <= 0:
						mObject.rotation.y = dvec.angle_to(ZERO_ANGLE)
						mAnimationPlayer.play("Alarm")
						mMode = Mode.ALERT
			else:
				if mEngaged:
					_Disengage(true)
		else:
			if mEngaged:
				_Disengage(true)

func _Engage():
	if Target.Dead:
		_Disengage(false)
		return
	# If we are far enough from home and HP is low, flee to home
	if mHP < ESCAPE_HP && translation.distance_squared_to(mHome) > MAX_DISTANCE_FROM_HOME_SQ:
		mEscaping = true
		mDestination = mHome
		_Disengage(false)
		return
	
	# Last known location
	mDestination = Target.translation
	var mvec = (mDestination - translation).normalized() * WALKING_SPEED
	mObject.rotation.y = Vector2(mvec.x, mvec.z).angle_to(ZERO_ANGLE)
	
	# Attack if in range
	if translation.distance_squared_to(mDestination) < ATTACK_RANGE_SQ:
		if mAttackCooldown <= 0 && mMode == Mode.IDLE:
			# As we can't add stuff to imported animations, this will have to do.
			var t = $Spatial/Tween
			t.remove_all()
			t.interpolate_callback(self, 0.5, "_OnAttack")
			t.start()
			mAnimationPlayer.play("Attack")
			mMode = Mode.ATTACK
		elif mMode == Mode.WALK:
			mAnimationPlayer.play("Idle-loop")
			mMode = Mode.IDLE
	else:
		# Move into range
		if mMode != Mode.WALK:
			mAnimationPlayer.play("Walk-loop")
			mMode = Mode.WALK
		move_and_slide(mvec)

func _Disengage(search):
	mEngaged = false
	mAnimationPlayer.play("Idle-loop")
	mMode = Mode.IDLE
	if search:
		mSearchTime = rand_range(MAX_SEARCH_TIME * .2, MAX_SEARCH_TIME)
	else:
		mSearchTime = 0.0
	mMode = Mode.IDLE


func _Loiter():
	# If too far from home, return there
	if translation.distance_squared_to(mHome) > MAX_DISTANCE_FROM_HOME_SQ:
		mDestination = mHome
	mEscaping = false
	if mDestination == null:
		if mTimer > 0:
			return
		# Decide new destination
		if randf() < .7:
			# Idle
			mTimer = rand_range(0.5, 2)
			if mMode != Mode.IDLE:
				mAnimationPlayer.play("Idle-loop")
				mMode = Mode.IDLE
			return
		mDestination = mHome + Vector3(rand_range(-1, 1), 0, rand_range(-1, 1)).normalized() * sqrt(MAX_DISTANCE_FROM_HOME_SQ)
		mDestination = mDestination.round()
		# FIXME: Check that destination tile is free
		if mMode != Mode.WALK:
			mAnimationPlayer.play("Walk-loop")
			mMode = Mode.WALK
	# Go to destination
	if translation.distance_squared_to(mDestination) < .5:
		# Close enough, mode will be changed on next frame.
		mDestination = null
		return
	var mvec = (mDestination - translation).normalized() * WALKING_SPEED
	move_and_slide(mvec)
	mObject.rotation.y = Vector2(mvec.x, mvec.z).angle_to(ZERO_ANGLE)

