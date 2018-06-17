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

extends Spatial

const DEAD_ZONE = 0.1 * 0.1
const MAX_OFFSET = 4


export(float, 0, 5) var threshold = 2.0

var Target = null

onready var mCam = $Camera
onready var mCamPos = mCam.translation

var mShake
var mShakeLength = 0
var mShakeTime = 0
var mShakeIntensity = 0


func Tremor(at, strength):
	if strength < .1:
		return
	var dist = max(0.1, translation.distance_to(at))
	var intensity = clamp(1 / (dist * dist), 0, strength)
	if intensity < .05:
		return
	mShake = Vector3()
	mShakeLength = intensity * .8
	mShakeTime = 0
	mShakeIntensity = intensity

func _process(delta):
	var diff = translation
	if Target != null:
		diff -= Target.global_transform.origin
	diff.y = 0
	var ln = diff.length_squared()
	if ln > threshold * threshold:
		translate(diff * ln * .5 * -delta)
	
	var offset = Vector3()
	var axis = Vector2(Input.get_joy_axis(0, JOY_ANALOG_RX), Input.get_joy_axis(0, JOY_ANALOG_RY))
	if axis.length_squared() >= DEAD_ZONE:
		offset.x = axis.x
		offset.z = axis.y
		offset *= MAX_OFFSET
	offset += mCamPos.normalized() * offset.length()
	
	# Camera shake
	if mShakeTime < mShakeLength:
		mShakeTime += delta
		mShake += Vector3(rand_range(-1,1), rand_range(-1,1), rand_range(-1,1)).normalized()
		mShake *= 0.5
		mShake *= lerp(mShakeIntensity, 0, mShakeTime / mShakeLength)
		offset += mShake
	
	mCam.translation = mCamPos + offset




