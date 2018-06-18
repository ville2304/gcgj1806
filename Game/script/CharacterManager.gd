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

onready var mLevel = get_node("../Level")


func Navigate(from, to):
	mLevel.Navigate(Vector2(from.x, from.z), Vector2(to.x, to.z))

func AddCharacter(c):
	add_child(c)

func DestroyCharacter(c, anim = null):
	# FIXME: No time to figure out better way.
	if anim != null:
		var src = c.get_node("Spatial")
		c.remove_child(src)
		add_child(src)
		src.owner = self
		src.transform = c.transform
		src.get_node("Char/AnimationPlayer").play(anim)
	
	remove_child(c)
	if c.name == "Player":
		get_parent().PlayerDied(c.translation)
	else:
		if get_child_count() == 1:
			get_parent().OpenPortal(get_child(0).translation)

func PlayerTeleport():
	get_parent().NextLevel()
