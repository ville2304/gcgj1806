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

const Player = preload("res://Player.tscn")
const Enemy = preload("res://Enemy.tscn")

var mPlayer = null


func PlayerDied(pos):
	mPlayer = null
	$CamTarget.translation = pos
	$CameraController.Target = $CamTarget
	_ChangeLevel()
	$Menu.Open()

func OpenPortal(pos):
	var lvl = $Level
	var portal = $EndPortal
	portal.show()
	# TODO: Play animation
	print("Open portal")
	
	# We just hope one of the adjacent tiles is free.
	var possible = []
	for y in range(-1, 2):
		var yy = int(round(pos.z)) + y
		if yy < 0 || yy >= lvl.Height:
			continue
		for x in range(-1, 2):
			var xx = int(round(pos.x)) + x
			if xx < 0 || xx >= lvl.Width:
				continue
			if xx == 0 && yy == 0:
				continue
			var tile = lvl.Data[xx + yy * lvl.Width]
			if tile == 0 || tile == 2:
				possible.push_back(Vector3(xx, 0, yy))
	if possible.empty():
		# Nope
		portal.translation = pos
	else:
		portal.translation = possible[int(rand_range(0, possible.size() - 1))]

func NextLevel():
	print("Victory!")
	_ChangeLevel()

func GetPlayer():
	return mPlayer

func _ChangeLevel():
	$Fade/AnimationPlayer.connect("animation_finished", self, "_StartLevel", [], CONNECT_ONESHOT)
	$Fade/AnimationPlayer.play("FadeIn")

func _StartLevel(none = null):
	# Make new level
	var lvl = $Level
	lvl.Init()
	
	# Add characters
	var chars = $Characters
	chars.mCharacters = 0
	for i in chars.get_children():
		chars.remove_child(i)
	
	var plr = Player.instance()
	chars.AddCharacter(plr)
	var possible = []
	var ePossible = []
	for i in range(lvl.Width * lvl.Height):
		if lvl.Data[i] == 0:
			possible.push_back(i)
		if lvl.Data[i] != 1 && lvl.Data[i] != 3:
			if ePossible.empty():
				ePossible.push_back(i)
			else:
				var index = int(rand_range(0, possible.size() - 1))
				ePossible.push_back(ePossible[index])
				ePossible[index] = i
	if possible.empty():
		# Quite unlikely
		get_tree().quit()
	var startCell = possible[int(rand_range(0, possible.size()))]
	ePossible.remove(ePossible.rfind(startCell))
	plr.Init(Vector3(startCell % lvl.Width, 0, int(startCell / lvl.Width)))
	mPlayer = plr
	$CameraController.Target = plr
	$CameraController.translation = plr.translation
	
	var numEnemies = min(int(sqrt(lvl.Width * lvl.Height) + 2), ePossible.size() - 1)
	#numEnemies = 1
	for i in range(numEnemies):
		var e = Enemy.instance()
		chars.AddCharacter(e)
		var cell = ePossible[i]
		e.Init(Vector3(cell % lvl.Width, 0, int(cell / lvl.Width)))
		e.Target = plr
	
	# Reset portal
	var portal = $EndPortal
	portal.hide()
	portal.translation = Vector3(0, -100, 0)
	
	$Fade/AnimationPlayer.play("FadeOut")

func _ready():
	randomize()
	_StartLevel()
