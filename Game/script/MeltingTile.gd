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

extends Area

var mBodies
var mCondition
var mHeat

func _ready():
	mBodies = 0
	mHeat = 0.0
	mCondition = 5.0

func _physics_process(delta):
	var ob = get_overlapping_bodies()
	var oblen = ob.size()
	for i in ob:
		if mCondition <= 0:
			if !i.Dead:
				i.OnFall(translation)
		elif i.get_collision_layer_bit(12):
			if i.has_method("GetTemperature"):
				mHeat += delta * i.GetTemperature() / 20.0
			else:
				mHeat += delta
	if mHeat > .1:
		var value = min(mHeat, mHeat * delta * .5)
		mHeat-= value
		mCondition-= value
	else:
		mCondition+= delta
	mCondition = clamp(mCondition, -8.0, 5.0)
	if mCondition <= 0 && oblen > 0:
		mCondition = -8.0
	var s = clamp(mCondition, 0, 5) / 5.0
	$MeshInstance.scale = Vector3(s, 1, s)
