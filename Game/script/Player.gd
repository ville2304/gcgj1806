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

onready var mObject = $Spatial


func _physics_process(delta):
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
	move_and_slide(mvec)
	if mvec.length_squared() != 0:
		mObject.rotation.y = Vector2(mvec.x, mvec.z).angle_to(ZERO_ANGLE)


