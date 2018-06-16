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

export(float, 0, 100) var amount = 5
export(float, 0, 5) var push = 0
export(float, 0, 1) var tremor = 0.0
export(int, 1, 10) var lifetime = 1


func _enter_tree():
	get_tree().call_group("Tremor", "Tremor", global_transform.origin, tremor)

func _physics_process(delta):
	if lifetime < 0:
		get_parent().remove_child(self)
	lifetime -= 1

func _OnBodyEntered(body):
	if body.has_method("OnDamage"):
		body.OnDamage(amount, push, global_transform.origin)
