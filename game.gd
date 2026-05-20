## SplitScreen.gd
## Attach to your root Node2D (e.g. "SplitScreen").
## Builds two SubViewports side-by-side, each with its own Camera2D.
##
## Scene tree built at runtime:
##
##  SplitScreen  (Node2D)
##  ├── HSplitContainer
##  │   ├── SubViewportContainer  (player 1 — left)
##  │   │   └── SubViewport
##  │   │       └── world_instance  +  Camera2D (P1)
##  │   └── SubViewportContainer  (player 2 — right)
##  │       └── SubViewport
##  │           └── world_instance  +  Camera2D (P2)

extends Node2D

# ── Exports ────────────────────────────────────────────────────────────────────

## Your game world scene (.tscn). Each player gets their own instance.
@export var world_scene: PackedScene

## Zoom level for both cameras (1.0 = default, 2.0 = zoomed in, 0.5 = zoomed out)
@export var camera_zoom: float = 1.0

## Name of the node inside world_scene that Camera2D should follow (e.g. "Player1", "Player2").
## Leave blank to just centre the camera without following anyone.
@export var player1_node_name: String = "chicken_man"
@export var player2_node_name: String = "corn_man"

# ── Internals ──────────────────────────────────────────────────────────────────

var _viewport_p1: SubViewport
var _viewport_p2: SubViewport
var _camera_p1: Camera2D
var _camera_p2: Camera2D


func _ready() -> void:
	_build_split_screen()


# ── Build ──────────────────────────────────────────────────────────────────────

func _build_split_screen() -> void:
	var hsc := HSplitContainer.new()
	hsc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hsc.split_offset = 0
	hsc.dragger_visibility = SplitContainer.DRAGGER_HIDDEN
	add_child(hsc)

	_viewport_p1 = _make_viewport_container(hsc, "Player1Viewport")
	_viewport_p2 = _make_viewport_container(hsc, "Player2Viewport")

	if world_scene:
		_populate_viewport(_viewport_p1, world_scene, player1_node_name, 1)
		_populate_viewport(_viewport_p2, world_scene, player2_node_name, 2)
	else:
		_demo_viewport(_viewport_p1, Color.ROYAL_BLUE,   "P1")
		_demo_viewport(_viewport_p2, Color.DARK_OLIVE_GREEN, "P2")


func _make_viewport_container(parent: Node, vp_name: String) -> SubViewport:
	var container := SubViewportContainer.new()
	container.stretch = true
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	container.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	parent.add_child(container)

	var vp := SubViewport.new()
	vp.name = vp_name
	vp.size = Vector2i(DisplayServer.window_get_size()) / Vector2i(2, 1)
	vp.handle_input_locally = true
	vp.physics_object_picking = true
	# Transparent background so your canvas background colour shows through
	vp.transparent_bg = false
	container.add_child(vp)

	return vp


# ── World population ───────────────────────────────────────────────────────────

func _populate_viewport(vp: SubViewport, scene: PackedScene, follow_node: String, player_idx: int) -> void:
	var world := scene.instantiate()
	vp.add_child(world)

	var cam := Camera2D.new()
	cam.name = "Camera2D_P%d" % player_idx
	cam.zoom = Vector2(camera_zoom, camera_zoom)
	cam.enabled = true

	if follow_node != "":
		var target := world.get_node_or_null(follow_node)
		if target:
			# Parent the camera to the target so it follows automatically
			target.add_child(cam)
		else:
			push_warning("SplitScreen: node '%s' not found in world scene for player %d." % [follow_node, player_idx])
			world.add_child(cam)
	else:
		world.add_child(cam)

	cam.make_current()

	if player_idx == 1:
		_camera_p1 = cam
	else:
		_camera_p2 = cam


# ── Demo mode (no world_scene set) ────────────────────────────────────────────

func _demo_viewport(vp: SubViewport, bg_color: Color, label: String) -> void:
	# Background colour rect
	var bg := ColorRect.new()
	bg.color = bg_color.darkened(0.4)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vp.add_child(bg)

	# A coloured square to prove the viewport is working
	var box := ColorRect.new()
	box.color = bg_color
	box.size = Vector2(80, 80)
	box.position = Vector2(60, 60)
	vp.add_child(box)

	# Label
	var lbl := Label.new()
	lbl.text = label
	lbl.add_theme_font_size_override("font_size", 48)
	lbl.position = Vector2(16, 16)
	vp.add_child(lbl)

	# Camera2D — no target, just centred
	var cam := Camera2D.new()
	cam.zoom = Vector2(camera_zoom, camera_zoom)
	vp.add_child(cam)
	cam.make_current()


# ── Public API ─────────────────────────────────────────────────────────────────

## Get the SubViewport for player 1 or 2.
func get_viewport_for_player(player: int) -> SubViewport:
	return _viewport_p1 if player == 1 else _viewport_p2

## Get the Camera2D for player 1 or 2 (useful to reposition or change zoom at runtime).
func get_camera_for_player(player: int) -> Camera2D:
	return _camera_p1 if player == 1 else _camera_p2


# ── Window resize ──────────────────────────────────────────────────────────────

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_SIZE_CHANGED:
		var half := Vector2i(DisplayServer.window_get_size()) / Vector2i(2, 1)
		if _viewport_p1:
			_viewport_p1.size = half
		if _viewport_p2:
			_viewport_p2.size = half
