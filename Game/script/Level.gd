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

onready var mNavigation = $Navigation

func Init():
	var width = 10
	var height = 10
	var data = [
	0,0,0,0,0,0,0,0,0,0,
	0,0,0,0,0,0,0,0,0,0,
	0,0,1,1,1,0,0,0,0,0,
	0,0,0,0,0,0,0,0,0,0,
	0,0,0,0,0,0,0,0,0,0,
	0,0,0,0,0,0,0,0,0,0,
	0,0,0,0,0,0,0,0,0,0,
	0,0,0,0,0,0,0,0,0,0,
	0,0,0,0,0,0,0,0,0,0,
	0,0,0,0,0,0,0,0,0,0
	]
	var Wall = load("res://Wall.tscn")
	
	# FIXME: This could be greatly optimized
	var vertices = PoolVector2Array()
	vertices.append(Vector2(0, 0))
	vertices.append(Vector2(1, 0))
	vertices.append(Vector2(1, 1))
	vertices.append(Vector2(0, 1))
	var navmesh = NavigationPolygon.new()
	navmesh.add_outline(vertices)
	navmesh.make_polygons_from_outlines()
	for y in range(height):
		for x in range(width):
			if data[x + y * width] == 1:
				var w = Wall.instance()
				w.translation = Vector3(x, 0, y)
				add_child(w)
			else:
				var trans = Transform2D()
				trans.origin = Vector2(x, y)
				mNavigation.navpoly_add(navmesh, trans)

func Navigate(from, to):
	return mNavigation.get_simple_path(from, to)

func _ready():
	Init()