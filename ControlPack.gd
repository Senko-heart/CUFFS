class_name ControlPack
extends RefCounted

var _arc := ZR.new()
var _arc_name: StringName
var _json := {}
var _resource := {}
var _style := {}
var _frame: Dictionary[StringName, Dictionary] = {}
var _material := ShaderMaterial.new()

func _init(arc: StringName) -> void:
	_arc = FS[arc]
	_arc_name = arc
	_material.shader = preload("res://premult.gdshader")
	_load_system_file()
	if &"resource" in _json:
		for res: Dictionary in _json.resource:
			_load_resource(res.id, res.src)
	if &"style" in _json:
		for style: Dictionary in _json.style:
			_bake_style(style)
	if &"frame" in _json:
		for frame: Dictionary in _json.frame:
			if &"id" in frame:
				_frame[frame.id] = frame

func _try_load(src: String, case_sensitive: bool = false) -> PackedByteArray:
	var patch_src := _arc_name.path_join(src)
	if FS.decensor.file_exists(patch_src, case_sensitive):
		return FS.decensor.read_file(patch_src, case_sensitive)
	if FS.patch.file_exists(patch_src, case_sensitive):
		return FS.patch.read_file(patch_src, case_sensitive)
	if _arc.file_exists(src, case_sensitive):
		return _arc.read_file(src, case_sensitive)
	return []

func _load_system_file() -> void:
	var bytes := _try_load("system.json")
	var text := bytes.get_string_from_utf8()
	_json = JSON.parse_string(text)

func _add_material(item: CanvasItem) -> void:
	item.material = _material

func _load_resource(id: String, src: String) -> void:
	var bytes := _try_load(src)
	if bytes.is_empty():
		print(src)
	match src.get_extension():
		"png":
			var img := Image.new()
			img.load_png_from_buffer(bytes)
			var tex := ImageTexture.create_from_image(img)
			_resource[id] = tex
		_: push_error("unknown resource type " + src)

func _bake_style(style: Dictionary) -> void:
	var obj := {}
	if &"id" not in style: return
	_style[style.id] = obj
	for key: StringName in style:
		var val: Variant = style[key]
		match key:
			&"normal": _add_atlas(obj, key, val)
			&"pushed": _add_atlas(obj, key, val)
			&"focus": _add_atlas(obj, key, val)
			&"pushed_focus": _add_atlas(obj, key, val)
			&"tracking": _add_atlas(obj, key, val)
			&"disabled": _add_atlas(obj, key, val)
			&"push_disabled": _add_atlas(obj, key, val)
			&"scroll": _add_atlas(obj, key, val)
			_: obj[key] = val

func _add_atlas(obj: Dictionary, key: StringName, val: Dictionary) -> void:
	if val.image not in _resource:
		push_error(val.image + " is not found")
		return
	var region := PackedInt32Array(val.get(&"region", []))
	region.resize(4)
	var tex := AtlasTexture.new()
	tex.atlas = _resource[val.image]
	tex.region = Rect2(region[0], region[1], region[2], region[3])
	tex.filter_clip = true
	obj[key] = tex
	if &"column" not in val: return
	key += "_column"
	if val.column not in _resource:
		push_error(val.column + " is not found")
		return
	obj[key] = _resource[val.column]

func create_texture_rect(id: StringName) -> TextureRect:
	var control := TextureRect.new()
	control.texture = _resource[id]
	control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_add_material(control)
	return control

func get_texture(id: StringName) -> Texture2D:
	return _resource.get(id)

func _create_button(style: Dictionary) -> ModButton:
	var btn := ModButton.new()
	btn.name = style.id
	if &"normal" in style: btn.tex_normal = style.normal
	if &"pushed" in style: btn.tex_pushed = style.pushed
	if &"focus" in style: btn.tex_focus = style.focus
	if &"pushed_focus" in style: btn.tex_pushed_focus = style.pushed_focus
	if &"disabled" in style: btn.tex_disabled = style.disabled
	if &"push_disabled" in style: btn.tex_push_disabled = style.push_disabled
	return btn

func _create_radio(style: Dictionary, btn_group: ButtonGroup) -> ModButton:
	var btn := _create_button(style)
	btn.button_group = btn_group
	btn.toggle_mode = true
	return btn

func _create_check(style: Dictionary) -> ModButton:
	var btn := _create_button(style)
	btn.toggle_mode = true
	return btn

func _create_scroll(style: Dictionary, vertical: bool = false) -> ModScroll:
	var scroll := ModScroll.new()
	scroll.vertical = vertical
	scroll.scroll = style.get(&"scroll")
	scroll.grabber.tex_normal = style.get(&"normal")
	scroll.grabber.tex_focus = style.get(&"focus")
	scroll.grabber.tex_pushed = style.get(&"tracking")
	if &"up_button" in style:
		scroll.up_button = _create_button(_style[style.up_button.style])
	if &"down_button" in style:
		scroll.down_button = _create_button(_style[style.down_button.style])
	return scroll

func _create_static_text(ctrl: Dictionary, style: Dictionary) -> MessageSprite:
	var label := MessageSprite.new()
	attach_text_style(label, style.id)
	label.message = ctrl.get(&"text", "")
	return label

func attach_text_style(label: MessageSprite, style_id: StringName) -> void:
	if style_id not in _style:
		return
	var style: Dictionary = _style[style_id]
	if &"arrange" in style:
		var arrange: Dictionary = style.arrange
		if &"align" in arrange:
			match arrange.align:
				&"left": label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
				&"center": label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				&"right": label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		if &"line_height" in arrange:
			pass
	if &"font" in style:
		var font: Dictionary = style.font
		if &"size" in font:
			var size: int = font.size
			label.add_theme_font_size_override(&"normal_font_size", size)
			label.add_theme_font_size_override(&"bold_font_size", size)
			label.add_theme_font_size_override(&"italics_font_size", size)
			label.add_theme_font_size_override(&"bold_italics_font_size", size)
			label.add_theme_font_size_override(&"mono_font_size", size)
		if font.get(&"bold"): label.use_bold = true
		if font.get(&"italic"): label.use_italics = true
		if font.get(&"face"): label.face = font.face
	if &"text" in style:
		var text: Dictionary = style.text
		if &"color" in text:
			var c := Color(text.color)
			label.add_theme_color_override(&"default_color", c)
	if &"shadow" in style:
		var shadow: Dictionary = style.shadow
		if &"color" in shadow:
			var c := Color(shadow.color)
			label.add_theme_color_override(&"font_outline_color", c)
			label.add_theme_color_override(&"font_shadow_color", c)
		if &"x" in shadow:
			label.add_theme_constant_override(&"shadow_offset_x", shadow.x)
		if &"y" in shadow:
			label.add_theme_constant_override(&"shadow_offset_y", shadow.y)

func create_form_page(frm_id: StringName) -> Control:
	var frame := _frame[frm_id]
	var frm := TextureRect.new()
	if &"id" in frame: frm.name = frame.id
	_add_material(frm)
	if &"bg" in frame: frm.texture = _resource.get(frame.bg)
	frm.size.x = frame.get(&"width", 0)
	frm.size.y = frame.get(&"height", 0)
	var btn_group: ButtonGroup
	var refresh_btn_group := true
	for ctrl: Dictionary in frame.get(&"controls", []):
		if refresh_btn_group: btn_group = ButtonGroup.new()
		refresh_btn_group = true
		var control: Control
		if &"style" in ctrl:
			if not ctrl.style in _style:
				control = create_form_page(ctrl.style)
			else:
				var style: Dictionary = _style[ctrl.style]
				var type: StringName = style.get(&"type", &"button")
				if &"arrange" in style:
					type = style.arrange.get(&"type", type)
				match type:
					&"button": control = _create_button(style)
					&"radio":
						control = _create_radio(style, btn_group)
						refresh_btn_group = false
					&"check": control = _create_check(style)
					&"scroll_bar": control = _create_scroll(style)
					&"horz": control = _create_scroll(style)
					&"vert": control = _create_scroll(style, true)
					&"static_text": control = _create_static_text(ctrl, style)
					_: continue
		elif &"rsrc" in ctrl:
			var res: Variant = _resource[ctrl.rsrc]
			if res is Texture2D:
				control = TextureRect.new()
				control.texture = res
				control.mouse_filter = Control.MOUSE_FILTER_IGNORE
		else: continue
		if &"id" in ctrl: control.name = ctrl.id
		control.position.x = ctrl.get(&"x", 0)
		control.position.y = ctrl.get(&"y", 0)
		if &"width" in ctrl: control.size.x = ctrl.width
		if &"height" in ctrl: control.size.y = ctrl.height
		if control is not MessageSprite:
			_add_material(control)
		frm.add_child(control)
	return frm
