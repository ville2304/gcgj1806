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

const MeltingTile = preload("res://MeltingTile.tscn")
var TILES = preload("res://models/Tiles.tscn").instance()

onready var mTiles = $Tiles
onready var mMeltingTiles = $MeltingTiles
onready var mNavigation = $Navigation


var Width = 10
var Height = 10
var Data

func Init():
	for i in mMeltingTiles.get_children():
		mMeltingTiles.remove_child(i)
	for i in mTiles.get_children():
		mTiles.remove_child(i)
	
	# Very primitive level generator
	var MARGIN = 6
	Width = int(rand_range(10, 40 - 2 * MARGIN) + 2 * MARGIN)
	Height = int(rand_range(10, 40 - 2 * MARGIN) + 2 * MARGIN)
	Data = []
	var table = [0, 0, 0, 0, 0, 0, 2, 2, 2, 2, 2, 2, 1]
	for i in range(Width * Height):
		Data.push_back(table[int(floor(rand_range(0, table.size())))])
	for x in range(Width):
		for y in range(MARGIN):
			Data[x + Width * y] = 3
			Data[x + Width * (Height - y - 1)] = 3
		Data[x + Width * MARGIN] = 1
		Data[x + Width * (Height - MARGIN - 1)] = 1
	for y in range(Height):
		for x in range(MARGIN):
			Data[x + Width * y] = 3
			Data[Width - 1 - x + Width * y] = 3
		Data[MARGIN + Width * y] = 1
		Data[Width - 1 - MARGIN + Width * y] = 1
	
	
	"""
	var vertices = PoolVector2Array()
	vertices.append(Vector2(0, 0))
	vertices.append(Vector2(1, 0))
	vertices.append(Vector2(1, 1))
	vertices.append(Vector2(0, 1))
	var navmesh = NavigationPolygon.new()
	navmesh.add_outline(vertices)
	navmesh.make_polygons_from_outlines()
	"""
	var floorTiles = [0, 1, 2, 3, 4]
	var wallTiles = [5, 6, 7]
	var rot = [0, PI * .5, PI, PI * 1.5]
	for y in range(Height):
		for x in range(Width):
			var tile = Data[x + y * Width]
			if tile == 1:
				# Wall
				var tl = TILES.get_child(wallTiles[int(rand_range(0, wallTiles.size()))]).duplicate(DUPLICATE_USE_INSTANCING)
				tl.translation = Vector3(x, 0, y)
				tl.rotation.y = rot[int(rand_range(0, rot.size()))]
				mTiles.add_child(tl)
			elif tile == 2:
				# Melting tile
				var mt = MeltingTile.instance()
				mt.translation = Vector3(x, 0, y)
				mMeltingTiles.add_child(mt)
			elif tile == 3:
				# Margin tile
				if randf() < .6:
					var tl = TILES.get_child(floorTiles[int(rand_range(0, floorTiles.size()))]).duplicate(DUPLICATE_USE_INSTANCING)
					tl.translation = Vector3(x, 0, y)
					tl.rotation.y = rot[int(rand_range(0, rot.size()))]
					mTiles.add_child(tl)
				else:
					var tl = TILES.get_child(wallTiles[int(rand_range(0, wallTiles.size()))]).duplicate(DUPLICATE_USE_INSTANCING)
					tl.translation = Vector3(x, 0, y)
					tl.rotation.y = rot[int(rand_range(0, rot.size()))]
					mTiles.add_child(tl)
			else:
				# Floor
				var tl = TILES.get_child(floorTiles[int(rand_range(0, floorTiles.size()))]).duplicate(DUPLICATE_USE_INSTANCING)
				tl.translation = Vector3(x, 0, y)
				tl.rotation.y = rot[int(rand_range(0, rot.size()))]
				mTiles.add_child(tl)

func Navigate(from, to):
	return []
	return mNavigation.get_simple_path(from, to)
