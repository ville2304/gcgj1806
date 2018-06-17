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

extends Node

var mOpen = true
onready var mCamera = get_node("../CameraController")
onready var mTargetOrigin = $TargetOrigin
onready var mTarget = $TargetOrigin/Target


func Open():
	get_tree().paused = true
	if !mOpen:
		$MenuView/AnimationPlayer.play("FadeIn")
	mOpen = true
	"""
	var p = get_parent().GetPlayer()
	if p != null:
		mTargetOrigin.translation = p.translation
		mTargetOrigin.translation = Vector3()
		mTargetOrigin.translation.y = 2.0
		mCamera.Goto(mTarget.global_transform, 1.0)
	"""

func Close():
	get_tree().paused = false
	if mOpen:
		$MenuView/AnimationPlayer.play("FadeOut")
	mOpen = false
	#mCamera.Restore()

func _ready():
	Open()
	call_deferred("Open")
	if Input.get_connected_joypads().empty():
		$MenuView/Label.text = "Press Enter"
	else:
		$MenuView/Label.text = str("Press ", Input.get_joy_button_string(JOY_START))

func _input(event):
	if event.is_pressed():
		if event.is_action("menu"):
			if mOpen:
				Close()
			else:
				Open()
		elif event.is_action("quit"):
			if mOpen:
				get_tree().quit()
			else:
				Open()

