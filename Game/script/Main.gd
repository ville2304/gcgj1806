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

func PlayerDied(pos):
	$CamTarget.translation = pos
	$CameraController.Target = $CamTarget
	print("Game over!")

func OpenPortal(pos):
	var lvl = $Level
	var portal = $EndPortal
	portal.show()
	# TODO: Play animation
	print("Open portal")
	
	# We just hope one of the adjacent tiles is free.
	for y in range(-1, 1):
		var yy = int(round(pos.z)) + y
		if yy < 0 || yy >= lvl.Height:
			continue
		for x in range(-1, 1):
			var xx = int(round(pos.x)) + x
			if xx < 0 || xx >= lvl.Width:
				continue
			if lvl.Data[xx + yy * lvl.Height] != 1:
				portal.translation = Vector3(xx, 0, yy)
				return
	# Nope
	portal.translation = pos

func NextLevel():
	print("Victory!")
	# Just reload this scene, it ought to do for now.
	get_tree().reload_current_scene()

func _ready():
	$CameraController.Target = $Characters/Player
	
	var Enemy = load("res://Enemy.tscn")
	var plr = $Characters/Player
	var cont = $Characters
	for i in range(1):
		var e = Enemy.instance()
		cont.AddCharacter(e)
		e.Init(Vector3(rand_range(0, 10), 0, rand_range(0, 10)))
		e.Target = plr

