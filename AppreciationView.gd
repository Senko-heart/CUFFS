class_name AppreciationView
extends CanvasLayer

class BustupViewInfo:
	var file := ""
	var pos := 0
	var priority := 0

class CgViewInfo:
	var flag := 0
	var cg_file := ""
	var pt_cg1 := Vector2.ZERO
	var pt_cg2 := Vector2.ZERO
	var scroll := false
	var bu_list: Array[BustupViewInfo] = []

class CgViewManager:
	var is_create := false
	var thumb_info: Array[CgViewInfo] = []

var spr_base := Control.new()
var spr_back: TextureRect
var spr_title: TextureRect
var spr_tag: Array[Control] = []
var spr_thumb_base: Control
var spr_music: Control
var spr_scroll: Control
var sel_tag := -1
var sel_page := -1
var cg_view_man: Array[CgViewManager] = []
var cg_num_l: PackedInt32Array = [6, 5, 7, 30]
var cg_num_r: PackedInt32Array = [15, 12, 9, 3]
var sel_play_bgm := -1
var is_play_bgm := false
var scroll := false
var scroll_t := 0.0
var check: PackedInt32Array
var cnf_play_bgm := false

func _init(parent: Node, tag_id: int = 0, page_id: int = 1, bgm: int = -1) -> void:
	var option_skin := Global.option_skin
	parent.add_child(self)
	layer = Global.Layer.Appreciation
	spr_base.modulate.a = 0.0
	add_child(spr_base)
	spr_back = option_skin.create_texture_rect(&"ID_FRM_0701")
	spr_base.add_child(spr_back)
	spr_title = option_skin.create_texture_rect(&"ID_FRM_0702")
	spr_title.position = Vector2(5, 6)
	spr_base.add_child(spr_title)
	spr_thumb_base = option_skin.create_form_page(&"ID_PAGE_THUMB")
	spr_base.add_child(spr_thumb_base)
	spr_thumb_base.pivot_offset.x = 0.5 * spr_thumb_base.size.x
	for i in range(4):
		var tag := option_skin.create_form_page("ID_PAGE_TAG" + str(i + 1))
		spr_tag.append(tag)
		spr_base.add_child(tag)
	spr_music = option_skin.create_form_page(&"ID_PAGE_MUSIC")
	spr_music.position = Vector2(534, 38)
	if bgm == -1:
		spr_music.get_node("ID_STOP").button_pressed = true
	else:
		play_bgm(bgm)
		spr_music.get_node("ID_BGM" + str(bgm)).button_pressed = true
	spr_base.add_child(spr_music)
	spr_scroll = option_skin.create_form_page(&"ID_PAGE_SCROLL")
	var id_scroll: ModScroll = spr_scroll.get_node("ID_SCROLL")
	id_scroll.max_value = 100
	var pos_x := 0.5 * (Global.screen_size.x - spr_scroll.size.x)
	spr_scroll.position = Vector2(pos_x, 550)
	spr_scroll.modulate.a = 0.0
	var id_close: ModButton = spr_scroll.get_node("ID_CLOSE")
	id_close.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
	add_child(spr_scroll)
	set_page(tag_id, page_id, true)

func destroy() -> void:
	mini_destroy()
	queue_free()

func mini_create(tag_id: int = 0, page_id: int = 0, bgm: int = -1) -> void:
	spr_base.modulate.a = 0.0
	show()
	if bgm == -1:
		spr_music.get_node("ID_STOP").button_pressed = true
	else:
		play_bgm(bgm)
		spr_music.get_node("ID_BGM" + str(bgm)).button_pressed = true
	var pos_x := 0.5 * (Global.screen_size.x - spr_scroll.size.x)
	spr_scroll.position = Vector2(pos_x, 550)
	spr_scroll.modulate.a = 0.0
	sel_tag = -1
	sel_page = -1
	set_page(tag_id, page_id, true)

func mini_destroy() -> void:
	Anim.flush(spr_base)
	Anim.flush(spr_scroll)
	for tag in spr_tag:
		Anim.flush(tag)
	Anim.flush(spr_thumb_base)
	cg_view_man.clear()
	hide()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_left", true):
		Input.action_release("ui_left")
	elif event.is_action_pressed("ui_right", true):
		Input.action_release("ui_right")

func _show() -> void:
	_hide_scroll()
	Anim.fade(spr_base, 1.0, 0.5)

func _hide() -> void:
	await Anim.fade(spr_base, 0.0, 0.5)

func _hide_scroll(time: float = 0.3) -> void:
	await Anim.fade(spr_scroll, 0.0, time)
	if not Anim.is_animated(spr_scroll) and spr_scroll.modulate.a == 0.0:
		spr_scroll.hide()

func set_page(tag_id: int, page_id: int, flush: bool = false) -> void:
	if sel_tag == tag_id and sel_page == page_id:
		return
	if sel_tag != tag_id:
		cg_view_man.clear()
	set_cg_palette(tag_id, page_id)
	var y := 38
	for i in range(spr_tag.size()):
		Anim.move(spr_tag[i], Vector2(5, y), 0.5)
		y += 38
		if tag_id == i:
			var anim := {}
			if sel_tag != tag_id:
				var off := spr_thumb_base.pivot_offset
				var y0 := spr_thumb_base.position.y
				anim.position = {
					base = Vector2(270, y0) - off,
					target = Vector2(270, y) - off,
					accel = Vector2(3.0, 0.0)}
				anim.scale = {
					base = Vector2(1.0, 0.0),
					target = Vector2.ONE,
					accel = Vector2(3.0, 0.0)}
			anim.alpha = { target = 1.0, base = 0.5 }
			Anim.schedule(spr_thumb_base, anim)
			y += 312
	for i in range(spr_tag.size()):
		if flush:
			Anim.flush(spr_tag[i])
	Anim.run(0.5)
	if flush:
		Anim.flush(spr_thumb_base)
	sel_tag = tag_id
	sel_page = page_id

func reset_thumb_base() -> void:
	for i in range(12):
		spr_thumb_base.get_node("ID_CG" + str(i + 1)).modulate.a = 0.0
		spr_thumb_base.get_node("ID_CGSEL" + str(i + 1)).hide()
	for i in range(6):
		spr_thumb_base.get_node("ID_REC" + str(i + 1)).modulate.a = 0.0
		spr_thumb_base.get_node("ID_RECSEL" + str(i + 1)).hide()

func set_cg_palette(tag_id: int, page: int) -> void:
	reset_thumb_base()
	var cg_num := 0
	if tag_id == 0:
		if page == 0:
			check_palette_cg(1, 1, "CA01")
			check_palette_cg(2, 2, "CA02")
			check_palette_cg(3, 3, "CA03")
			check_palette_cg(4, 4, "CA04")
			check_palette_cg(5, 5, "CA05")
			check_palette_cg(7, 6, "CA07")
		elif page == 1:
			check_palette_cg(91, 1, "EA05")
			check_palette_cg(100, 2, "EA08")
			check_palette_cg(96, 3, "EA07")
			check_palette_cg(120, 4, "EA20")
			check_palette_cg(160, 5, "EA24")
			check_palette_cg(170, 6, "EA25")
			check_palette_cg(140, 7, "EA22")
			check_palette_cg(110, 8, "EA19")
			check_palette_cg(210, 9, "EA29")
			check_palette_cg(180, 10, "EA26")
			check_palette_cg(130, 11, "EA21")
			check_palette_cg(190, 12, "EA27")
		elif page == 2:
			check_palette_cg(200, 1, "EA28")
			check_palette_cg(105, 2, "EA18")
			check_palette_cg(150, 3, "EA23")
		elif page == 4:
			check_palette_recollect(1, 1, "REC_SR1")
			check_palette_recollect(2, 2, "REC_SR2")
			check_palette_recollect(3, 3, "REC_SR3")
	elif tag_id == 1:
		if page == 0:
			check_palette_cg(61, 1, "CG01")
			check_palette_cg(62, 2, "CG02")
			check_palette_cg(63, 3, "CG03")
			check_palette_cg(64, 4, "CG04")
			check_palette_cg(65, 5, "CG05")
		elif page == 1:
			check_palette_cg(270, 1, "EZ07")
			check_palette_cg(260, 2, "EZ04")
			check_palette_cg(280, 3, "EZ08")
			check_palette_cg(290, 4, "EZ09")
			check_palette_cg(320, 5, "EZ12")
			check_palette_cg(330, 6, "EZ13")
			check_palette_cg(340, 7, "EZ14")
			check_palette_cg(350, 8, "EZ15")
			check_palette_cg(300, 9, "EZ10")
			check_palette_cg(360, 10, "EZ16")
			check_palette_cg(370, 11, "EZ17")
			check_palette_cg(310, 12, "EZ11")
		elif page == 4:
			check_palette_recollect(4, 1, "REC_YH1")
			check_palette_recollect(5, 2, "REC_YH2")
			check_palette_recollect(6, 3, "REC_YH3")
	elif tag_id == 2:
		if page == 0:
			check_palette_cg(71, 1, "CH01")
			check_palette_cg(72, 2, "CH02")
			check_palette_cg(74, 3, "CH04")
			check_palette_cg(75, 4, "CH05")
			check_palette_cg(76, 5, "CH06")
			check_palette_cg(78, 6, "CH08")
			check_palette_cg(79, 7, "CH09")
		elif page == 1:
			check_palette_cg(380, 1, "EZ20")
			check_palette_cg(400, 2, "EZ22")
			check_palette_cg(430, 3, "EZ25")
			check_palette_cg(450, 4, "EZ26")
			check_palette_cg(410, 5, "EZ23")
			check_palette_cg(390, 6, "EZ21")
			check_palette_cg(460, 7, "EZ27")
			check_palette_cg(470, 8, "EZ28")
			check_palette_cg(420, 9, "EZ24")
		elif page == 4:
			check_palette_recollect(7, 1, "REC_KZ1")
			check_palette_recollect(8, 2, "REC_KZ2")
	elif tag_id == 3:
		if page == 0:
			check_palette_cg(11, 1, "CB01")
			check_palette_cg(12, 2, "CB02")
			check_palette_cg(13, 3, "CB03")
			check_palette_cg(14, 4, "CB04")
			check_palette_cg(16, 5, "CB06")
			check_palette_cg(17, 6, "CB07")
			check_palette_cg(21, 7, "CC01")
			check_palette_cg(22, 8, "CC02")
			check_palette_cg(23, 9, "CC03")
			check_palette_cg(26, 10, "CC06")
			check_palette_cg(24, 11, "CC04")
			check_palette_cg(25, 12, "CC05")
		elif page == 1:
			check_palette_cg(27, 1, "CC07")
			check_palette_cg(31, 2, "CD01")
			check_palette_cg(32, 3, "CD02")
			check_palette_cg(33, 4, "CD03")
			check_palette_cg(34, 5, "CD04")
			check_palette_cg(35, 6, "CD05")
			check_palette_cg(36, 7, "CD06")
			check_palette_cg(41, 8, "CE01")
			check_palette_cg(42, 9, "CE02")
			check_palette_cg(43, 10, "CE03")
			check_palette_cg(44, 11, "CE04")
			check_palette_cg(51, 12, "CF01")
		elif page == 2:
			check_palette_cg(52, 1, "CF02")
			check_palette_cg(53, 2, "CF03")
			check_palette_cg(54, 3, "CF04")
			check_palette_cg(55, 4, "CF05")
			check_palette_cg(56, 5, "CF06")
			check_palette_cg(81, 6, "CJ01")
		elif page == 3:
			check_palette_cg(220, 1, "EC02")
			check_palette_cg(230, 2, "ED02")
			check_palette_cg(250, 3, "EE02")
	cg_num = cg_num_l[tag_id] + cg_num_r[tag_id]
	cg_view_man.resize(cg_num)
	for i in range(cg_num):
		cg_view_man[i] = CgViewManager.new()

func check_palette_cg(flag: int, id: int, sprite_id: String) -> void:
	var id_cg: TextureRect = spr_thumb_base.get_node("ID_CG" + str(id))
	var id_cgsel: Control = spr_thumb_base.get_node("ID_CGSEL" + str(id))
	if Global.check_cg_flag(flag):
		id_cg.modulate.a = 1.0
		id_cgsel.show()
		id_cg.texture = Global.option_skin.get_texture("ID_" + sprite_id)
	else:
		id_cg.modulate.a = 1.0
		id_cgsel.hide()
		id_cg.texture = Global.option_skin.get_texture(&"ID_FRM_0733")

func cg_proc(cid: StringName, control: Control) -> bool:
	if (cid == &"ID_TAG"
	or cid == &"ID_PAGE1"
	or cid == &"ID_PAGE2"
	or cid == &"ID_PAGE3"
	or cid == &"ID_PAGE4"
	or cid == &"ID_REC"):
		var tag_item := control.get_parent()
		var tag := int(tag_item.name.trim_prefix("ID_PAGE_TAG")) - 1
		var nodes := ["ID_PAGE1", "ID_PAGE2", "ID_PAGE3", "ID_PAGE4", "ID_REC"]
		for i in range(nodes.size()):
			if tag_item.has_node(nodes[i]):
				if tag_item.get_node(nodes[i]).button_pressed:
					set_page(tag, i)
					check[tag] = i + 1
					break
	elif cid.begins_with("ID_CGSEL"):
		var id := int(cid.trim_prefix("ID_CGSEL")) - 1
		if sel_page * 12 + id < cg_num_l[sel_tag]:
			await show_cg_loop(sel_tag, sel_page * 12 + id)
		else:
			var bu_page := cg_num_l[sel_tag] / 12 + 1
			await show_cg_loop(sel_tag, (sel_page - bu_page) * 12 + id + cg_num_l[sel_tag])
	else:
		return false
	return true

func show_cg_loop(char_id: int, id: int) -> void:
	setup_cg_view_info(char_id, id)
	var index := check_hit_cg(id)
	var length := cg_view_man[id].thumb_info.size()
	show_cg(cg_view_man[id].thumb_info[index], true)
	_hide()
	var cg_view_max := cg_view_man.size()
	var id_scroll: ModScroll = spr_scroll.get_node("ID_SCROLL")
	while true:
		var control := await Global.poll_ui_event()
		var cid := control.name if control else &""
		if cid == &"ID_SCROLL":
			scroll_t = id_scroll.ratio
			var info := cg_view_man[id].thumb_info[index]
			var a := info.pt_cg1
			var b := info.pt_cg2
			var d := (b - a) / 3.0
			var pt := a.bezier_interpolate(a + d, b - d, b, scroll_t)
			Global.adv.spr_cg.position = -pt
		elif cid == &"ID_CLOSE" or Input.is_action_just_pressed("hide_adv"):
			spr_scroll.hide()
		elif Input.is_action_just_pressed("ui_up"):
			id -= 1
			index = -1
			if id < 0:
				id = cg_view_max - 1
			setup_cg_view_info(char_id, id)
			length = cg_view_man[id].thumb_info.size()
			while true:
				index += 1
				if index >= length:
					index = 0
					id -= 1
				if id < 0:
					id = cg_view_max - 1
				setup_cg_view_info(char_id, id)
				length = cg_view_man[id].thumb_info.size()
				if Global.check_cg_flag(cg_view_man[id].thumb_info[index].flag):
					break
			await show_cg(cg_view_man[id].thumb_info[index])
		elif Input.is_action_just_pressed("ui_down"):
			id += 1
			index = -1
			if id >= cg_view_max:
				id = 0
			setup_cg_view_info(char_id, id)
			length = cg_view_man[id].thumb_info.size()
			while -1:
				index += 1
				if index >= length:
					index = 0
					id += 1
				if id >= cg_view_max:
					id = 0
				setup_cg_view_info(char_id, id)
				length = cg_view_man[id].thumb_info.size()
				if Global.check_cg_flag(cg_view_man[id].thumb_info[index].flag):
					break
			await show_cg(cg_view_man[id].thumb_info[index])
		elif cid.is_empty() and Input.is_action_just_pressed("hit_confirm", true):
			while true:
				index += 1
				if index >= length:
					index = 0
					id += 1
				if id >= cg_view_max:
					id = 0
				setup_cg_view_info(char_id, id)
				length = cg_view_man[id].thumb_info.size()
				if Global.check_cg_flag(cg_view_man[id].thumb_info[index].flag):
					break
			await show_cg(cg_view_man[id].thumb_info[index])
		elif Input.is_action_just_pressed("ui_left") and scroll:
			id_scroll.value -= 10
			scroll_t = id_scroll.ratio
			var info := cg_view_man[id].thumb_info[index]
			var a := info.pt_cg1
			var b := info.pt_cg2
			var d := (b - a) / 3.0
			var pt := a.bezier_interpolate(a + d, b - d, b, scroll_t)
			Global.adv.spr_cg.position = -pt
		elif Input.is_action_just_pressed("ui_right") and scroll:
			id_scroll.value += 10
			scroll_t = id_scroll.ratio
			var info := cg_view_man[id].thumb_info[index]
			var a := info.pt_cg1
			var b := info.pt_cg2
			var d := (b - a) / 3.0
			var pt := a.bezier_interpolate(a + d, b - d, b, scroll_t)
			Global.adv.spr_cg.position = -pt
		elif Input.is_action_just_pressed("hit_cancel"):
			if scroll and spr_scroll.visible:
				spr_scroll.hide()
			else:
				break
	_show()

func show_cg(info: CgViewInfo, flush: bool = false) -> void:
	flush = flush or Global.cnf_obj.screen_effect == ConfigDataBase.ScreenEffect.None
	Global.adv.bustup_clear(0)
	scroll = info.scroll
	if not flush:
		if scroll:
			spr_scroll.show()
			Anim.fade(spr_scroll, 1.0, 0.3)
		else:
			_hide_scroll()
	elif scroll:
		spr_scroll.show()
		Anim.fade(spr_scroll, 1.0, 0.0)
	else:
		spr_scroll.hide()
	if scroll:
		var id_scroll: ModScroll = spr_scroll.get_node("ID_SCROLL")
		id_scroll.value = 0.0
		scroll_t = 0.0
	Global.adv.set_cg_(info.cg_file, int(info.pt_cg1.x), int(info.pt_cg1.y))
	for bu in info.bu_list:
		Global.adv.set_bustup_(bu.file, bu.pos, bu.priority)
	await Global.adv.update_(flush)

func set_cg_info(
	info: Array[CgViewInfo],
	flag: int,
	cg_file: String,
	bu_file: String = "",
	pt1: Vector2 = Vector2.ZERO,
	pt2: Variant = null,
) -> void:
	var index := info.size()
	info.append(CgViewInfo.new())
	info[index].flag = flag
	info[index].cg_file = cg_file
	info[index].pt_cg1 = pt1
	if pt2 is Vector2:
		info[index].pt_cg2 = pt2
		info[index].scroll = true
	else:
		info[index].scroll = false
	if bu_file != "":
		set_bustup_info(info, bu_file)

func set_bustup_info(
	info: Array[CgViewInfo],
	bu_file: String,
	pos: int = 0,
	priority: int = 0
) -> void:
	var index := info.size() - 1
	var i_bustup := info[index].bu_list.size()
	info[index].bu_list.append(BustupViewInfo.new())
	var r_bustup := info[index].bu_list[i_bustup]
	r_bustup.file = bu_file
	r_bustup.pos = pos
	r_bustup.priority = priority

func check_hit_cg(id: int) -> int:
	return cg_view_man[id].thumb_info.find_custom(
		func(thminf: CgViewInfo) -> bool:
			return Global.check_cg_flag(thminf.flag))

func setup_cg_view_info(tag_id: int, id: int) -> void:
	var target := cg_view_man[id].thumb_info
	if tag_id == 0:
		if not cg_view_man[id].is_create:
			cg_view_man[id].is_create = true
			if id == 0:
				set_cg_info(target, 1, "B17a", "CA01_01M")
				set_cg_info(target, 1, "B17a", "CA01_02M")
				set_cg_info(target, 1, "B17a", "CA01_03M")
				set_cg_info(target, 1, "B17a", "CA01_04M")
				set_cg_info(target, 1, "B17a", "CA01_05M")
				set_cg_info(target, 1, "B17a", "CA01_06M")
				set_cg_info(target, 1, "B17a", "CA01_07M")
				set_cg_info(target, 1, "B17a", "CA01_08M")
				set_cg_info(target, 1, "B17a", "CA01_09M")
				set_cg_info(target, 1, "B17a", "CA01_10M")
				set_cg_info(target, 1, "B17a", "CA01_11M")
				set_cg_info(target, 1, "B17a", "CA01_12M")
				set_cg_info(target, 1, "B17a", "CA01_13M")
			elif id == 1:
				set_cg_info(target, 2, "B01a", "CA02_01M")
				set_cg_info(target, 2, "B01a", "CA02_02M")
				set_cg_info(target, 2, "B01a", "CA02_03M")
				set_cg_info(target, 2, "B01a", "CA02_04M")
				set_cg_info(target, 2, "B01a", "CA02_05M")
				set_cg_info(target, 2, "B01a", "CA02_06M")
				set_cg_info(target, 2, "B01a", "CA02_07M")
				set_cg_info(target, 2, "B01a", "CA02_08M")
				set_cg_info(target, 2, "B01a", "CA02_09M")
				set_cg_info(target, 2, "B01a", "CA02_10M")
				set_cg_info(target, 2, "B01a", "CA02_11M")
				set_cg_info(target, 2, "B01a", "CA02_12M")
				set_cg_info(target, 2, "B01a", "CA02_13M")
			elif id == 2:
				set_cg_info(target, 3, "B03a", "CA03_01M")
				set_cg_info(target, 3, "B03a", "CA03_02M")
				set_cg_info(target, 3, "B03a", "CA03_03M")
				set_cg_info(target, 3, "B03a", "CA03_04M")
				set_cg_info(target, 3, "B03a", "CA03_05M")
				set_cg_info(target, 3, "B03a", "CA03_06M")
				set_cg_info(target, 3, "B03a", "CA03_07M")
				set_cg_info(target, 3, "B03a", "CA03_08M")
				set_cg_info(target, 3, "B03a", "CA03_09M")
				set_cg_info(target, 3, "B03a", "CA03_10M")
				set_cg_info(target, 3, "B03a", "CA03_11M")
				set_cg_info(target, 3, "B03a", "CA03_12M")
				set_cg_info(target, 3, "B03a", "CA03_13M")
			elif id == 3:
				set_cg_info(target, 4, "B21a", "CA04_01M")
				set_cg_info(target, 4, "B21a", "CA04_02M")
				set_cg_info(target, 4, "B21a", "CA04_03M")
				set_cg_info(target, 4, "B21a", "CA04_04M")
				set_cg_info(target, 4, "B21a", "CA04_05M")
				set_cg_info(target, 4, "B21a", "CA04_06M")
				set_cg_info(target, 4, "B21a", "CA04_07M")
				set_cg_info(target, 4, "B21a", "CA04_08M")
				set_cg_info(target, 4, "B21a", "CA04_09M")
				set_cg_info(target, 4, "B21a", "CA04_10M")
				set_cg_info(target, 4, "B21a", "CA04_11M")
				set_cg_info(target, 4, "B21a", "CA04_12M")
				set_cg_info(target, 4, "B21a", "CA04_13M")
			elif id == 4:
				set_cg_info(target, 5, "B20a", "CA05_01M", Vector2(400, 0))
				set_cg_info(target, 5, "B20a", "CA05_02M", Vector2(400, 0))
				set_cg_info(target, 5, "B20a", "CA05_03M", Vector2(400, 0))
				set_cg_info(target, 5, "B20a", "CA05_04M", Vector2(400, 0))
				set_cg_info(target, 5, "B20a", "CA05_05M", Vector2(400, 0))
				set_cg_info(target, 5, "B20a", "CA05_06M", Vector2(400, 0))
				set_cg_info(target, 5, "B20a", "CA05_07M", Vector2(400, 0))
				set_cg_info(target, 5, "B20a", "CA05_08M", Vector2(400, 0))
				set_cg_info(target, 5, "B20a", "CA05_09M", Vector2(400, 0))
				set_cg_info(target, 5, "B20a", "CA05_10M", Vector2(400, 0))
				set_cg_info(target, 5, "B20a", "CA05_11M", Vector2(400, 0))
				set_cg_info(target, 5, "B20a", "CA05_12M", Vector2(400, 0))
				set_cg_info(target, 5, "B20a", "CA05_13M", Vector2(400, 0))
			elif id == 5:
				set_cg_info(target, 7, "B23a", "CA07_01M")
				set_cg_info(target, 7, "B23a", "CA07_02M")
				set_cg_info(target, 7, "B23a", "CA07_03M")
				set_cg_info(target, 7, "B23a", "CA07_04M")
				set_cg_info(target, 7, "B23a", "CA07_05M")
				set_cg_info(target, 7, "B23a", "CA07_06M")
				set_cg_info(target, 7, "B23a", "CA07_07M")
				set_cg_info(target, 7, "B23a", "CA07_08M")
				set_cg_info(target, 7, "B23a", "CA07_09M")
				set_cg_info(target, 7, "B23a", "CA07_10M")
				set_cg_info(target, 7, "B23a", "CA07_11M")
				set_cg_info(target, 7, "B23a", "CA07_12M")
				set_cg_info(target, 7, "B23a", "CA07_13M")
			elif id == 6:
				set_cg_info(target, 91, "EA05")
			elif id == 7:
				set_cg_info(target, 101, "EA08A", "", Vector2(0, 700), Vector2(0, 0))
				set_cg_info(target, 102, "EA08B", "", Vector2(0, 700), Vector2(0, 0))
				set_cg_info(target, 103, "EA08C", "", Vector2(0, 700), Vector2(0, 0))
			elif id == 8:
				set_cg_info(target, 96, "EA07")
			elif id == 9:
				set_cg_info(target, 121, "EA20a")
				set_cg_info(target, 122, "EA20b")
			elif id == 10:
				set_cg_info(target, 161, "EA24a")
				set_cg_info(target, 162, "EA24b")
				set_cg_info(target, 163, "EA24c")
			elif id == 11:
				set_cg_info(target, 171, "EA25a")
				set_cg_info(target, 172, "EA25b")
				set_cg_info(target, 173, "EA25c")
				set_cg_info(target, 174, "EA25d")
			elif id == 12:
				set_cg_info(target, 141, "EA22a")
				set_cg_info(target, 142, "EA22b")
				set_cg_info(target, 143, "EA22c")
				set_cg_info(target, 144, "EA22d")
			elif id == 13:
				set_cg_info(target, 111, "EA19a")
				set_cg_info(target, 112, "EA19b")
				set_cg_info(target, 113, "EA19c")
			elif id == 14:
				set_cg_info(target, 211, "EA29a")
				set_cg_info(target, 212, "EA29b")
				set_cg_info(target, 213, "EA29c")
			elif id == 15:
				set_cg_info(target, 181, "EA26a")
				set_cg_info(target, 182, "EA26b")
				set_cg_info(target, 183, "EA26c")
				set_cg_info(target, 184, "EA26d")
				set_cg_info(target, 185, "EA26e")
				set_cg_info(target, 186, "EA26f")
				set_cg_info(target, 187, "EA26g")
				set_cg_info(target, 188, "EA26h")
			elif id == 16:
				set_cg_info(target, 131, "EA21a")
				set_cg_info(target, 132, "EA21b")
				set_cg_info(target, 133, "EA21c")
			elif id == 17:
				set_cg_info(target, 191, "EA27a")
				set_cg_info(target, 192, "EA27b")
				set_cg_info(target, 193, "EA27c")
				set_cg_info(target, 194, "EA27d")
				set_cg_info(target, 195, "EA27e")
				set_cg_info(target, 196, "EA27f")
				set_cg_info(target, 197, "EA27g")
				set_cg_info(target, 198, "EA27h")
			elif id == 18:
				set_cg_info(target, 201, "EA28a")
				set_cg_info(target, 202, "EA28b")
				set_cg_info(target, 203, "EA28c")
				set_cg_info(target, 204, "EA28d")
			elif id == 19:
				set_cg_info(target, 106, "EA18a")
				set_cg_info(target, 107, "EA18b")
			elif id == 20:
				set_cg_info(target, 152, "EA23b")
				set_cg_info(target, 151, "EA23a")
	elif tag_id == 1:
		if not cg_view_man[id].is_create:
			cg_view_man[id].is_create = true
			if id == 0:
				set_cg_info(target, 61, "B16a", "CG01_01M")
				set_cg_info(target, 61, "B16a", "CG01_02M")
				set_cg_info(target, 61, "B16a", "CG01_03M")
				set_cg_info(target, 61, "B16a", "CG01_04M")
				set_cg_info(target, 61, "B16a", "CG01_05M")
				set_cg_info(target, 61, "B16a", "CG01_06M")
				set_cg_info(target, 61, "B16a", "CG01_07M")
				set_cg_info(target, 61, "B16a", "CG01_08M")
				set_cg_info(target, 61, "B16a", "CG01_09M")
				set_cg_info(target, 61, "B16a", "CG01_10M")
				set_cg_info(target, 61, "B16a", "CG01_11M")
				set_cg_info(target, 61, "B16a", "CG01_12M")
			elif id == 1:
				set_cg_info(target, 62, "B15a", "CG02_01M")
				set_cg_info(target, 62, "B15a", "CG02_02M")
				set_cg_info(target, 62, "B15a", "CG02_03M")
				set_cg_info(target, 62, "B15a", "CG02_04M")
				set_cg_info(target, 62, "B15a", "CG02_05M")
				set_cg_info(target, 62, "B15a", "CG02_06M")
				set_cg_info(target, 62, "B15a", "CG02_07M")
				set_cg_info(target, 62, "B15a", "CG02_08M")
				set_cg_info(target, 62, "B15a", "CG02_09M")
				set_cg_info(target, 62, "B15a", "CG02_10M")
				set_cg_info(target, 62, "B15a", "CG02_11M")
				set_cg_info(target, 62, "B15a", "CG02_12M")
			elif id == 2:
				set_cg_info(target, 63, "B39a", "CG03_01M")
				set_cg_info(target, 63, "B39a", "CG03_02M")
				set_cg_info(target, 63, "B39a", "CG03_03M")
				set_cg_info(target, 63, "B39a", "CG03_04M")
				set_cg_info(target, 63, "B39a", "CG03_05M")
				set_cg_info(target, 63, "B39a", "CG03_06M")
				set_cg_info(target, 63, "B39a", "CG03_07M")
				set_cg_info(target, 63, "B39a", "CG03_08M")
				set_cg_info(target, 63, "B39a", "CG03_09M")
				set_cg_info(target, 63, "B39a", "CG03_10M")
				set_cg_info(target, 63, "B39a", "CG03_11M")
				set_cg_info(target, 63, "B39a", "CG03_12M")
			elif id == 3:
				set_cg_info(target, 64, "B39a", "CG04_01M")
				set_cg_info(target, 64, "B39a", "CG04_02M")
				set_cg_info(target, 64, "B39a", "CG04_03M")
				set_cg_info(target, 64, "B39a", "CG04_04M")
				set_cg_info(target, 64, "B39a", "CG04_05M")
				set_cg_info(target, 64, "B39a", "CG04_06M")
				set_cg_info(target, 64, "B39a", "CG04_07M")
				set_cg_info(target, 64, "B39a", "CG04_08M")
				set_cg_info(target, 64, "B39a", "CG04_09M")
				set_cg_info(target, 64, "B39a", "CG04_10M")
				set_cg_info(target, 64, "B39a", "CG04_11M")
				set_cg_info(target, 64, "B39a", "CG04_12M")
			elif id == 4:
				set_cg_info(target, 65, "B23a", "CG05_01M")
				set_cg_info(target, 65, "B23a", "CG05_02M")
				set_cg_info(target, 65, "B23a", "CG05_03M")
				set_cg_info(target, 65, "B23a", "CG05_04M")
				set_cg_info(target, 65, "B23a", "CG05_05M")
				set_cg_info(target, 65, "B23a", "CG05_06M")
				set_cg_info(target, 65, "B23a", "CG05_07M")
				set_cg_info(target, 65, "B23a", "CG05_08M")
				set_cg_info(target, 65, "B23a", "CG05_09M")
				set_cg_info(target, 65, "B23a", "CG05_10M")
				set_cg_info(target, 65, "B23a", "CG05_11M")
				set_cg_info(target, 65, "B23a", "CG05_12M")
			elif id == 5:
				set_cg_info(target, 271, "EZ07a")
				set_cg_info(target, 272, "EZ07b")
			elif id == 6:
				set_cg_info(target, 261, "EZ04a")
				set_cg_info(target, 262, "EZ04b")
			elif id == 7:
				set_cg_info(target, 281, "EZ08a")
				set_cg_info(target, 282, "EZ08b")
				set_cg_info(target, 283, "EZ08c")
			elif id == 8:
				set_cg_info(target, 291, "EZ09a")
				set_cg_info(target, 292, "EZ09b")
				set_cg_info(target, 293, "EZ09c")
				set_cg_info(target, 294, "EZ09d")
			elif id == 9:
				set_cg_info(target, 321, "EZ12a")
				set_cg_info(target, 322, "EZ12b")
				set_cg_info(target, 323, "EZ12c")
				set_cg_info(target, 324, "EZ12d")
				set_cg_info(target, 325, "EZ12e")
				set_cg_info(target, 326, "EZ12f")
			elif id == 10:
				set_cg_info(target, 331, "EZ13a")
				set_cg_info(target, 332, "EZ13b")
				set_cg_info(target, 333, "EZ13c")
				set_cg_info(target, 334, "EZ13d")
			elif id == 11:
				set_cg_info(target, 341, "EZ14a")
				set_cg_info(target, 342, "EZ14b")
				set_cg_info(target, 343, "EZ14c")
			elif id == 12:
				set_cg_info(target, 351, "EZ15a")
				set_cg_info(target, 352, "EZ15b")
				set_cg_info(target, 353, "EZ15c")
				set_cg_info(target, 354, "EZ15d")
			elif id == 13:
				set_cg_info(target, 301, "EZ10")
			elif id == 14:
				set_cg_info(target, 361, "EZ16a")
				set_cg_info(target, 362, "EZ16b")
				set_cg_info(target, 363, "EZ16c")
				set_cg_info(target, 364, "EZ16d")
				set_cg_info(target, 365, "EZ16e")
			elif id == 15:
				set_cg_info(target, 371, "EZ17a")
				set_cg_info(target, 372, "EZ17b")
				set_cg_info(target, 373, "EZ17c")
				set_cg_info(target, 374, "EZ17d")
				set_cg_info(target, 375, "EZ17e")
			elif id == 16:
				set_cg_info(target, 311, "EZ11")
	elif tag_id == 2:
		if not cg_view_man[id].is_create:
			cg_view_man[id].is_create = true
			if id == 0:
				set_cg_info(target, 71, "B19a", "CH01_01M")
				set_cg_info(target, 71, "B19a", "CH01_02M")
				set_cg_info(target, 71, "B19a", "CH01_03M")
				set_cg_info(target, 71, "B19a", "CH01_04M")
				set_cg_info(target, 71, "B19a", "CH01_05M")
				set_cg_info(target, 71, "B19a", "CH01_06M")
				set_cg_info(target, 71, "B19a", "CH01_07M")
				set_cg_info(target, 71, "B19a", "CH01_08M")
				set_cg_info(target, 71, "B19a", "CH01_09M")
				set_cg_info(target, 71, "B19a", "CH01_10M")
				set_cg_info(target, 71, "B19a", "CH01_11M")
				set_cg_info(target, 71, "B19a", "CH01_12M")
				set_cg_info(target, 71, "B19a", "CH01_13M")
				set_cg_info(target, 71, "B19a", "CH01_14M")
			elif id == 1:
				set_cg_info(target, 72, "B12a", "CH02_01M")
				set_cg_info(target, 72, "B12a", "CH02_02M")
				set_cg_info(target, 72, "B12a", "CH02_03M")
				set_cg_info(target, 72, "B12a", "CH02_04M")
				set_cg_info(target, 72, "B12a", "CH02_05M")
				set_cg_info(target, 72, "B12a", "CH02_06M")
				set_cg_info(target, 72, "B12a", "CH02_07M")
				set_cg_info(target, 72, "B12a", "CH02_08M")
				set_cg_info(target, 72, "B12a", "CH02_09M")
				set_cg_info(target, 72, "B12a", "CH02_10M")
				set_cg_info(target, 72, "B12a", "CH02_11M")
				set_cg_info(target, 72, "B12a", "CH02_12M")
				set_cg_info(target, 72, "B12a", "CH02_13M")
				set_cg_info(target, 72, "B12a", "CH02_14M")
			elif id == 2:
				set_cg_info(target, 74, "B21a", "CH04_01M")
				set_cg_info(target, 74, "B21a", "CH04_02M")
				set_cg_info(target, 74, "B21a", "CH04_03M")
				set_cg_info(target, 74, "B21a", "CH04_04M")
				set_cg_info(target, 74, "B21a", "CH04_05M")
				set_cg_info(target, 74, "B21a", "CH04_06M")
				set_cg_info(target, 74, "B21a", "CH04_07M")
				set_cg_info(target, 74, "B21a", "CH04_08M")
				set_cg_info(target, 74, "B21a", "CH04_09M")
				set_cg_info(target, 74, "B21a", "CH04_10M")
				set_cg_info(target, 74, "B21a", "CH04_11M")
				set_cg_info(target, 74, "B21a", "CH04_12M")
				set_cg_info(target, 74, "B21a", "CH04_13M")
				set_cg_info(target, 74, "B21a", "CH04_14M")
			elif id == 3:
				set_cg_info(target, 75, "B20a", "CH05_01M", Vector2(400, 0))
				set_cg_info(target, 75, "B20a", "CH05_02M", Vector2(400, 0))
				set_cg_info(target, 75, "B20a", "CH05_03M", Vector2(400, 0))
				set_cg_info(target, 75, "B20a", "CH05_04M", Vector2(400, 0))
				set_cg_info(target, 75, "B20a", "CH05_05M", Vector2(400, 0))
				set_cg_info(target, 75, "B20a", "CH05_06M", Vector2(400, 0))
				set_cg_info(target, 75, "B20a", "CH05_07M", Vector2(400, 0))
				set_cg_info(target, 75, "B20a", "CH05_08M", Vector2(400, 0))
				set_cg_info(target, 75, "B20a", "CH05_09M", Vector2(400, 0))
				set_cg_info(target, 75, "B20a", "CH05_10M", Vector2(400, 0))
				set_cg_info(target, 75, "B20a", "CH05_11M", Vector2(400, 0))
				set_cg_info(target, 75, "B20a", "CH05_12M", Vector2(400, 0))
				set_cg_info(target, 75, "B20a", "CH05_13M", Vector2(400, 0))
				set_cg_info(target, 75, "B20a", "CH05_14M", Vector2(400, 0))
			elif id == 4:
				set_cg_info(target, 76, "B23a", "CH06_01M")
				set_cg_info(target, 76, "B23a", "CH06_02M")
				set_cg_info(target, 76, "B23a", "CH06_03M")
				set_cg_info(target, 76, "B23a", "CH06_04M")
				set_cg_info(target, 76, "B23a", "CH06_05M")
				set_cg_info(target, 76, "B23a", "CH06_06M")
				set_cg_info(target, 76, "B23a", "CH06_07M")
				set_cg_info(target, 76, "B23a", "CH06_08M")
				set_cg_info(target, 76, "B23a", "CH06_09M")
				set_cg_info(target, 76, "B23a", "CH06_10M")
				set_cg_info(target, 76, "B23a", "CH06_11M")
				set_cg_info(target, 76, "B23a", "CH06_12M")
				set_cg_info(target, 76, "B23a", "CH06_13M")
				set_cg_info(target, 76, "B23a", "CH06_14M")
			elif id == 5:
				set_cg_info(target, 78, "B39a", "CH08_01M")
				set_cg_info(target, 78, "B39a", "CH08_02M")
				set_cg_info(target, 78, "B39a", "CH08_03M")
				set_cg_info(target, 78, "B39a", "CH08_04M")
				set_cg_info(target, 78, "B39a", "CH08_05M")
				set_cg_info(target, 78, "B39a", "CH08_06M")
				set_cg_info(target, 78, "B39a", "CH08_07M")
				set_cg_info(target, 78, "B39a", "CH08_08M")
				set_cg_info(target, 78, "B39a", "CH08_09M")
				set_cg_info(target, 78, "B39a", "CH08_10M")
				set_cg_info(target, 78, "B39a", "CH08_11M")
				set_cg_info(target, 78, "B39a", "CH08_12M")
				set_cg_info(target, 78, "B39a", "CH08_13M")
				set_cg_info(target, 78, "B39a", "CH08_14M")
			elif id == 6:
				set_cg_info(target, 79, "B19a", "CH09_01M")
				set_cg_info(target, 79, "B19a", "CH09_02M")
				set_cg_info(target, 79, "B19a", "CH09_03M")
				set_cg_info(target, 79, "B19a", "CH09_04M")
				set_cg_info(target, 79, "B19a", "CH09_05M")
				set_cg_info(target, 79, "B19a", "CH09_06M")
				set_cg_info(target, 79, "B19a", "CH09_07M")
				set_cg_info(target, 79, "B19a", "CH09_08M")
				set_cg_info(target, 79, "B19a", "CH09_09M")
				set_cg_info(target, 79, "B19a", "CH09_10M")
				set_cg_info(target, 79, "B19a", "CH09_11M")
				set_cg_info(target, 79, "B19a", "CH09_12M")
				set_cg_info(target, 79, "B19a", "CH09_13M")
				set_cg_info(target, 79, "B19a", "CH09_14M")
			elif id == 7:
				set_cg_info(target, 381, "EZ20")
			elif id == 8:
				set_cg_info(target, 401, "EZ22a")
				set_cg_info(target, 402, "EZ22b")
				set_cg_info(target, 403, "EZ22c")
			elif id == 9:
				set_cg_info(target, 431, "EZ25a")
				set_cg_info(target, 432, "EZ25b")
				set_cg_info(target, 433, "EZ25c")
				set_cg_info(target, 434, "EZ25d")
				set_cg_info(target, 435, "EZ25e")
				set_cg_info(target, 436, "EZ25f")
				set_cg_info(target, 437, "EZ25g")
				set_cg_info(target, 438, "EZ25h")
				set_cg_info(target, 439, "EZ25i")
				set_cg_info(target, 440, "EZ25j")
				set_cg_info(target, 441, "EZ25k")
				set_cg_info(target, 442, "EZ25l")
			elif id == 10:
				set_cg_info(target, 451, "EZ26a")
				set_cg_info(target, 452, "EZ26b")
				set_cg_info(target, 453, "EZ26c")
				set_cg_info(target, 454, "EZ26d")
			elif id == 11:
				set_cg_info(target, 411, "EZ23a")
				set_cg_info(target, 412, "EZ23b")
			elif id == 12:
				set_cg_info(target, 391, "EZ21a")
				set_cg_info(target, 392, "EZ21b")
				set_cg_info(target, 393, "EZ21c")
				set_cg_info(target, 394, "EZ21d")
				set_cg_info(target, 395, "EZ21e")
			elif id == 13:
				set_cg_info(target, 461, "EZ27a")
				set_cg_info(target, 462, "EZ27b")
				set_cg_info(target, 463, "EZ27c")
			elif id == 14:
				set_cg_info(target, 471, "EZ28a")
				set_cg_info(target, 472, "EZ28b")
				set_cg_info(target, 473, "EZ28c")
				set_cg_info(target, 474, "EZ28d")
			elif id == 15:
				set_cg_info(target, 421, "EZ24b")
				set_cg_info(target, 422, "EZ24a")
	elif tag_id == 3:
		if not cg_view_man[id].is_create:
			cg_view_man[id].is_create = true
			if id == 0:
				set_cg_info(target, 11, "B18a", "CB01_01M")
				set_cg_info(target, 11, "B18a", "CB01_02M")
				set_cg_info(target, 11, "B18a", "CB01_03M")
				set_cg_info(target, 11, "B18a", "CB01_04M")
				set_cg_info(target, 11, "B18a", "CB01_05M")
				set_cg_info(target, 11, "B18a", "CB01_06M")
				set_cg_info(target, 11, "B18a", "CB01_07M")
				set_cg_info(target, 11, "B18a", "CB01_08M")
				set_cg_info(target, 11, "B18a", "CB01_09M")
				set_cg_info(target, 11, "B18a", "CB01_10M")
				set_cg_info(target, 11, "B18a", "CB01_11M")
				set_cg_info(target, 11, "B18a", "CB01_12M")
				set_cg_info(target, 11, "B18a", "CB01_13M")
			elif id == 1:
				set_cg_info(target, 12, "B12a", "CB02_01M")
				set_cg_info(target, 12, "B12a", "CB02_02M")
				set_cg_info(target, 12, "B12a", "CB02_03M")
				set_cg_info(target, 12, "B12a", "CB02_04M")
				set_cg_info(target, 12, "B12a", "CB02_05M")
				set_cg_info(target, 12, "B12a", "CB02_06M")
				set_cg_info(target, 12, "B12a", "CB02_07M")
				set_cg_info(target, 12, "B12a", "CB02_08M")
				set_cg_info(target, 12, "B12a", "CB02_09M")
				set_cg_info(target, 12, "B12a", "CB02_10M")
				set_cg_info(target, 12, "B12a", "CB02_11M")
				set_cg_info(target, 12, "B12a", "CB02_12M")
				set_cg_info(target, 12, "B12a", "CB02_13M")
			elif id == 2:
				set_cg_info(target, 13, "B33a", "CB03_01M")
				set_cg_info(target, 13, "B33a", "CB03_02M")
				set_cg_info(target, 13, "B33a", "CB03_03M")
				set_cg_info(target, 13, "B33a", "CB03_04M")
				set_cg_info(target, 13, "B33a", "CB03_05M")
				set_cg_info(target, 13, "B33a", "CB03_06M")
				set_cg_info(target, 13, "B33a", "CB03_07M")
				set_cg_info(target, 13, "B33a", "CB03_08M")
				set_cg_info(target, 13, "B33a", "CB03_09M")
				set_cg_info(target, 13, "B33a", "CB03_10M")
				set_cg_info(target, 13, "B33a", "CB03_11M")
				set_cg_info(target, 13, "B33a", "CB03_12M")
				set_cg_info(target, 13, "B33a", "CB03_13M")
			elif id == 3:
				set_cg_info(target, 14, "B21a", "CB04_01M")
				set_cg_info(target, 14, "B21a", "CB04_02M")
				set_cg_info(target, 14, "B21a", "CB04_03M")
				set_cg_info(target, 14, "B21a", "CB04_04M")
				set_cg_info(target, 14, "B21a", "CB04_05M")
				set_cg_info(target, 14, "B21a", "CB04_06M")
				set_cg_info(target, 14, "B21a", "CB04_07M")
				set_cg_info(target, 14, "B21a", "CB04_08M")
				set_cg_info(target, 14, "B21a", "CB04_09M")
				set_cg_info(target, 14, "B21a", "CB04_10M")
				set_cg_info(target, 14, "B21a", "CB04_11M")
				set_cg_info(target, 14, "B21a", "CB04_12M")
				set_cg_info(target, 14, "B21a", "CB04_13M")
			elif id == 4:
				set_cg_info(target, 16, "B21a", "CB06_01M")
				set_cg_info(target, 16, "B21a", "CB06_02M")
				set_cg_info(target, 16, "B21a", "CB06_03M")
				set_cg_info(target, 16, "B21a", "CB06_04M")
				set_cg_info(target, 16, "B21a", "CB06_05M")
				set_cg_info(target, 16, "B21a", "CB06_06M")
				set_cg_info(target, 16, "B21a", "CB06_07M")
				set_cg_info(target, 16, "B21a", "CB06_08M")
				set_cg_info(target, 16, "B21a", "CB06_09M")
				set_cg_info(target, 16, "B21a", "CB06_10M")
				set_cg_info(target, 16, "B21a", "CB06_11M")
				set_cg_info(target, 16, "B21a", "CB06_12M")
				set_cg_info(target, 16, "B21a", "CB06_13M")
			elif id == 5:
				set_cg_info(target, 17, "B23a", "CB07_01M")
				set_cg_info(target, 17, "B23a", "CB07_02M")
				set_cg_info(target, 17, "B23a", "CB07_03M")
				set_cg_info(target, 17, "B23a", "CB07_04M")
				set_cg_info(target, 17, "B23a", "CB07_05M")
				set_cg_info(target, 17, "B23a", "CB07_06M")
				set_cg_info(target, 17, "B23a", "CB07_07M")
				set_cg_info(target, 17, "B23a", "CB07_08M")
				set_cg_info(target, 17, "B23a", "CB07_09M")
				set_cg_info(target, 17, "B23a", "CB07_10M")
				set_cg_info(target, 17, "B23a", "CB07_11M")
				set_cg_info(target, 17, "B23a", "CB07_12M")
				set_cg_info(target, 17, "B23a", "CB07_13M")
			elif id == 6:
				set_cg_info(target, 21, "B19a", "CC01_01M")
				set_cg_info(target, 21, "B19a", "CC01_02M")
				set_cg_info(target, 21, "B19a", "CC01_03M")
				set_cg_info(target, 21, "B19a", "CC01_04M")
				set_cg_info(target, 21, "B19a", "CC01_05M")
				set_cg_info(target, 21, "B19a", "CC01_06M")
				set_cg_info(target, 21, "B19a", "CC01_07M")
				set_cg_info(target, 21, "B19a", "CC01_08M")
				set_cg_info(target, 21, "B19a", "CC01_09M")
				set_cg_info(target, 21, "B19a", "CC01_10M")
				set_cg_info(target, 21, "B19a", "CC01_11M")
				set_cg_info(target, 21, "B19a", "CC01_12M")
				set_cg_info(target, 21, "B19a", "CC01_13M")
				set_cg_info(target, 21, "B19a", "CC01_14M")
			elif id == 7:
				set_cg_info(target, 22, "B12a", "CC02_01M")
				set_cg_info(target, 22, "B12a", "CC02_02M")
				set_cg_info(target, 22, "B12a", "CC02_03M")
				set_cg_info(target, 22, "B12a", "CC02_04M")
				set_cg_info(target, 22, "B12a", "CC02_05M")
				set_cg_info(target, 22, "B12a", "CC02_06M")
				set_cg_info(target, 22, "B12a", "CC02_07M")
				set_cg_info(target, 22, "B12a", "CC02_08M")
				set_cg_info(target, 22, "B12a", "CC02_09M")
				set_cg_info(target, 22, "B12a", "CC02_10M")
				set_cg_info(target, 22, "B12a", "CC02_11M")
				set_cg_info(target, 22, "B12a", "CC02_12M")
				set_cg_info(target, 22, "B12a", "CC02_13M")
				set_cg_info(target, 22, "B12a", "CC02_14M")
			elif id == 8:
				set_cg_info(target, 23, "B07a", "CC03_01M")
				set_cg_info(target, 23, "B07a", "CC03_02M")
				set_cg_info(target, 23, "B07a", "CC03_03M")
				set_cg_info(target, 23, "B07a", "CC03_04M")
				set_cg_info(target, 23, "B07a", "CC03_05M")
				set_cg_info(target, 23, "B07a", "CC03_06M")
				set_cg_info(target, 23, "B07a", "CC03_07M")
				set_cg_info(target, 23, "B07a", "CC03_08M")
				set_cg_info(target, 23, "B07a", "CC03_09M")
				set_cg_info(target, 23, "B07a", "CC03_10M")
				set_cg_info(target, 23, "B07a", "CC03_11M")
				set_cg_info(target, 23, "B07a", "CC03_12M")
				set_cg_info(target, 23, "B07a", "CC03_13M")
				set_cg_info(target, 23, "B07a", "CC03_14M")
			elif id == 9:
				set_cg_info(target, 26, "B07a", "CC06_01M")
				set_cg_info(target, 26, "B07a", "CC06_02M")
				set_cg_info(target, 26, "B07a", "CC06_03M")
				set_cg_info(target, 26, "B07a", "CC06_04M")
				set_cg_info(target, 26, "B07a", "CC06_05M")
				set_cg_info(target, 26, "B07a", "CC06_06M")
				set_cg_info(target, 26, "B07a", "CC06_07M")
				set_cg_info(target, 26, "B07a", "CC06_08M")
				set_cg_info(target, 26, "B07a", "CC06_09M")
				set_cg_info(target, 26, "B07a", "CC06_10M")
				set_cg_info(target, 26, "B07a", "CC06_11M")
				set_cg_info(target, 26, "B07a", "CC06_12M")
				set_cg_info(target, 26, "B07a", "CC06_13M")
				set_cg_info(target, 26, "B07a", "CC06_14M")
			elif id == 10:
				set_cg_info(target, 24, "B21a", "CC04_01M")
				set_cg_info(target, 24, "B21a", "CC04_02M")
				set_cg_info(target, 24, "B21a", "CC04_03M")
				set_cg_info(target, 24, "B21a", "CC04_04M")
				set_cg_info(target, 24, "B21a", "CC04_05M")
				set_cg_info(target, 24, "B21a", "CC04_06M")
				set_cg_info(target, 24, "B21a", "CC04_07M")
				set_cg_info(target, 24, "B21a", "CC04_08M")
				set_cg_info(target, 24, "B21a", "CC04_09M")
				set_cg_info(target, 24, "B21a", "CC04_10M")
				set_cg_info(target, 24, "B21a", "CC04_11M")
				set_cg_info(target, 24, "B21a", "CC04_12M")
				set_cg_info(target, 24, "B21a", "CC04_13M")
				set_cg_info(target, 24, "B21a", "CC04_14M")
			elif id == 11:
				set_cg_info(target, 25, "B20a", "CC05_01M", Vector2(400, 0))
				set_cg_info(target, 25, "B20a", "CC05_02M", Vector2(400, 0))
				set_cg_info(target, 25, "B20a", "CC05_03M", Vector2(400, 0))
				set_cg_info(target, 25, "B20a", "CC05_04M", Vector2(400, 0))
				set_cg_info(target, 25, "B20a", "CC05_05M", Vector2(400, 0))
				set_cg_info(target, 25, "B20a", "CC05_06M", Vector2(400, 0))
				set_cg_info(target, 25, "B20a", "CC05_07M", Vector2(400, 0))
				set_cg_info(target, 25, "B20a", "CC05_08M", Vector2(400, 0))
				set_cg_info(target, 25, "B20a", "CC05_09M", Vector2(400, 0))
				set_cg_info(target, 25, "B20a", "CC05_10M", Vector2(400, 0))
				set_cg_info(target, 25, "B20a", "CC05_11M", Vector2(400, 0))
				set_cg_info(target, 25, "B20a", "CC05_12M", Vector2(400, 0))
				set_cg_info(target, 25, "B20a", "CC05_13M", Vector2(400, 0))
				set_cg_info(target, 25, "B20a", "CC05_14M", Vector2(400, 0))
			elif id == 12:
				set_cg_info(target, 27, "B23a", "CC07_01M")
				set_cg_info(target, 27, "B23a", "CC07_02M")
				set_cg_info(target, 27, "B23a", "CC07_03M")
				set_cg_info(target, 27, "B23a", "CC07_04M")
				set_cg_info(target, 27, "B23a", "CC07_05M")
				set_cg_info(target, 27, "B23a", "CC07_06M")
				set_cg_info(target, 27, "B23a", "CC07_07M")
				set_cg_info(target, 27, "B23a", "CC07_08M")
				set_cg_info(target, 27, "B23a", "CC07_09M")
				set_cg_info(target, 27, "B23a", "CC07_10M")
				set_cg_info(target, 27, "B23a", "CC07_11M")
				set_cg_info(target, 27, "B23a", "CC07_12M")
				set_cg_info(target, 27, "B23a", "CC07_13M")
				set_cg_info(target, 27, "B23a", "CC07_14M")
			elif id == 13:
				set_cg_info(target, 31, "B19a", "CD01_01M")
				set_cg_info(target, 31, "B19a", "CD01_02M")
				set_cg_info(target, 31, "B19a", "CD01_03M")
				set_cg_info(target, 31, "B19a", "CD01_04M")
				set_cg_info(target, 31, "B19a", "CD01_05M")
				set_cg_info(target, 31, "B19a", "CD01_06M")
				set_cg_info(target, 31, "B19a", "CD01_07M")
				set_cg_info(target, 31, "B19a", "CD01_08M")
				set_cg_info(target, 31, "B19a", "CD01_09M")
				set_cg_info(target, 31, "B19a", "CD01_10M")
				set_cg_info(target, 31, "B19a", "CD01_11M")
				set_cg_info(target, 31, "B19a", "CD01_12M")
				set_cg_info(target, 31, "B19a", "CD01_13M")
			elif id == 14:
				set_cg_info(target, 32, "B39a", "CD02_01M")
				set_cg_info(target, 32, "B39a", "CD02_02M")
				set_cg_info(target, 32, "B39a", "CD02_03M")
				set_cg_info(target, 32, "B39a", "CD02_04M")
				set_cg_info(target, 32, "B39a", "CD02_05M")
				set_cg_info(target, 32, "B39a", "CD02_06M")
				set_cg_info(target, 32, "B39a", "CD02_07M")
				set_cg_info(target, 32, "B39a", "CD02_08M")
				set_cg_info(target, 32, "B39a", "CD02_09M")
				set_cg_info(target, 32, "B39a", "CD02_10M")
				set_cg_info(target, 32, "B39a", "CD02_11M")
				set_cg_info(target, 32, "B39a", "CD02_12M")
				set_cg_info(target, 32, "B39a", "CD02_13M")
			elif id == 15:
				set_cg_info(target, 33, "B07e", "CD03_01M")
				set_cg_info(target, 33, "B07e", "CD03_02M")
				set_cg_info(target, 33, "B07e", "CD03_03M")
				set_cg_info(target, 33, "B07e", "CD03_04M")
				set_cg_info(target, 33, "B07e", "CD03_05M")
				set_cg_info(target, 33, "B07e", "CD03_06M")
				set_cg_info(target, 33, "B07e", "CD03_07M")
				set_cg_info(target, 33, "B07e", "CD03_08M")
				set_cg_info(target, 33, "B07e", "CD03_09M")
				set_cg_info(target, 33, "B07e", "CD03_10M")
				set_cg_info(target, 33, "B07e", "CD03_11M")
				set_cg_info(target, 33, "B07e", "CD03_12M")
				set_cg_info(target, 33, "B07e", "CD03_13M")
			elif id == 16:
				set_cg_info(target, 34, "B21a", "CD04_01M")
				set_cg_info(target, 34, "B21a", "CD04_02M")
				set_cg_info(target, 34, "B21a", "CD04_03M")
				set_cg_info(target, 34, "B21a", "CD04_04M")
				set_cg_info(target, 34, "B21a", "CD04_05M")
				set_cg_info(target, 34, "B21a", "CD04_06M")
				set_cg_info(target, 34, "B21a", "CD04_07M")
				set_cg_info(target, 34, "B21a", "CD04_08M")
				set_cg_info(target, 34, "B21a", "CD04_09M")
				set_cg_info(target, 34, "B21a", "CD04_10M")
				set_cg_info(target, 34, "B21a", "CD04_11M")
				set_cg_info(target, 34, "B21a", "CD04_12M")
				set_cg_info(target, 34, "B21a", "CD04_13M")
			elif id == 17:
				set_cg_info(target, 35, "B20a", "CD05_01M", Vector2(400, 0))
				set_cg_info(target, 35, "B20a", "CD05_02M", Vector2(400, 0))
				set_cg_info(target, 35, "B20a", "CD05_03M", Vector2(400, 0))
				set_cg_info(target, 35, "B20a", "CD05_04M", Vector2(400, 0))
				set_cg_info(target, 35, "B20a", "CD05_05M", Vector2(400, 0))
				set_cg_info(target, 35, "B20a", "CD05_06M", Vector2(400, 0))
				set_cg_info(target, 35, "B20a", "CD05_07M", Vector2(400, 0))
				set_cg_info(target, 35, "B20a", "CD05_08M", Vector2(400, 0))
				set_cg_info(target, 35, "B20a", "CD05_09M", Vector2(400, 0))
				set_cg_info(target, 35, "B20a", "CD05_10M", Vector2(400, 0))
				set_cg_info(target, 35, "B20a", "CD05_11M", Vector2(400, 0))
				set_cg_info(target, 35, "B20a", "CD05_12M", Vector2(400, 0))
				set_cg_info(target, 35, "B20a", "CD05_13M", Vector2(400, 0))
			elif id == 18:
				set_cg_info(target, 36, "B23a", "CD06_01M")
				set_cg_info(target, 36, "B23a", "CD06_02M")
				set_cg_info(target, 36, "B23a", "CD06_03M")
				set_cg_info(target, 36, "B23a", "CD06_04M")
				set_cg_info(target, 36, "B23a", "CD06_05M")
				set_cg_info(target, 36, "B23a", "CD06_06M")
				set_cg_info(target, 36, "B23a", "CD06_07M")
				set_cg_info(target, 36, "B23a", "CD06_08M")
				set_cg_info(target, 36, "B23a", "CD06_09M")
				set_cg_info(target, 36, "B23a", "CD06_10M")
				set_cg_info(target, 36, "B23a", "CD06_11M")
				set_cg_info(target, 36, "B23a", "CD06_12M")
				set_cg_info(target, 36, "B23a", "CD06_13M")
			elif id == 19:
				set_cg_info(target, 41, "B35a", "CE01_01M")
				set_cg_info(target, 41, "B35a", "CE01_02M")
				set_cg_info(target, 41, "B35a", "CE01_03M")
				set_cg_info(target, 41, "B35a", "CE01_04M")
				set_cg_info(target, 41, "B35a", "CE01_05M")
				set_cg_info(target, 41, "B35a", "CE01_06M")
				set_cg_info(target, 41, "B35a", "CE01_07M")
				set_cg_info(target, 41, "B35a", "CE01_08M")
				set_cg_info(target, 41, "B35a", "CE01_09M")
				set_cg_info(target, 41, "B35a", "CE01_10M")
				set_cg_info(target, 41, "B35a", "CE01_11M")
				set_cg_info(target, 41, "B35a", "CE01_12M")
			elif id == 20:
				set_cg_info(target, 42, "B35a", "CE02_01M")
				set_cg_info(target, 42, "B35a", "CE02_02M")
				set_cg_info(target, 42, "B35a", "CE02_03M")
				set_cg_info(target, 42, "B35a", "CE02_04M")
				set_cg_info(target, 42, "B35a", "CE02_05M")
				set_cg_info(target, 42, "B35a", "CE02_06M")
				set_cg_info(target, 42, "B35a", "CE02_07M")
				set_cg_info(target, 42, "B35a", "CE02_08M")
				set_cg_info(target, 42, "B35a", "CE02_09M")
				set_cg_info(target, 42, "B35a", "CE02_10M")
				set_cg_info(target, 42, "B35a", "CE02_11M")
				set_cg_info(target, 42, "B35a", "CE02_12M")
			elif id == 21:
				set_cg_info(target, 43, "B39a", "CE03_01M")
				set_cg_info(target, 43, "B39a", "CE03_02M")
				set_cg_info(target, 43, "B39a", "CE03_03M")
				set_cg_info(target, 43, "B39a", "CE03_04M")
				set_cg_info(target, 43, "B39a", "CE03_05M")
				set_cg_info(target, 43, "B39a", "CE03_06M")
				set_cg_info(target, 43, "B39a", "CE03_07M")
				set_cg_info(target, 43, "B39a", "CE03_08M")
				set_cg_info(target, 43, "B39a", "CE03_09M")
				set_cg_info(target, 43, "B39a", "CE03_10M")
				set_cg_info(target, 43, "B39a", "CE03_11M")
				set_cg_info(target, 43, "B39a", "CE03_12M")
			elif id == 22:
				set_cg_info(target, 44, "B23a", "CE04_01M")
				set_cg_info(target, 44, "B23a", "CE04_02M")
				set_cg_info(target, 44, "B23a", "CE04_03M")
				set_cg_info(target, 44, "B23a", "CE04_04M")
				set_cg_info(target, 44, "B23a", "CE04_05M")
				set_cg_info(target, 44, "B23a", "CE04_06M")
				set_cg_info(target, 44, "B23a", "CE04_07M")
				set_cg_info(target, 44, "B23a", "CE04_08M")
				set_cg_info(target, 44, "B23a", "CE04_09M")
				set_cg_info(target, 44, "B23a", "CE04_10M")
				set_cg_info(target, 44, "B23a", "CE04_11M")
				set_cg_info(target, 44, "B23a", "CE04_12M")
			elif id == 23:
				set_cg_info(target, 51, "B17a", "CF01_01M")
				set_cg_info(target, 51, "B17a", "CF01_02M")
				set_cg_info(target, 51, "B17a", "CF01_03M")
				set_cg_info(target, 51, "B17a", "CF01_04M")
				set_cg_info(target, 51, "B17a", "CF01_05M")
				set_cg_info(target, 51, "B17a", "CF01_06M")
				set_cg_info(target, 51, "B17a", "CF01_07M")
				set_cg_info(target, 51, "B17a", "CF01_08M")
				set_cg_info(target, 51, "B17a", "CF01_09M")
				set_cg_info(target, 51, "B17a", "CF01_10M")
			elif id == 24:
				set_cg_info(target, 52, "B12a", "CF02_01M")
				set_cg_info(target, 52, "B12a", "CF02_02M")
				set_cg_info(target, 52, "B12a", "CF02_03M")
				set_cg_info(target, 52, "B12a", "CF02_04M")
				set_cg_info(target, 52, "B12a", "CF02_05M")
				set_cg_info(target, 52, "B12a", "CF02_06M")
				set_cg_info(target, 52, "B12a", "CF02_07M")
				set_cg_info(target, 52, "B12a", "CF02_08M")
				set_cg_info(target, 52, "B12a", "CF02_09M")
				set_cg_info(target, 52, "B12a", "CF02_10M")
			elif id == 25:
				set_cg_info(target, 53, "B07a", "CF03_01M")
				set_cg_info(target, 53, "B07a", "CF03_02M")
				set_cg_info(target, 53, "B07a", "CF03_03M")
				set_cg_info(target, 53, "B07a", "CF03_04M")
				set_cg_info(target, 53, "B07a", "CF03_05M")
				set_cg_info(target, 53, "B07a", "CF03_06M")
				set_cg_info(target, 53, "B07a", "CF03_07M")
				set_cg_info(target, 53, "B07a", "CF03_08M")
				set_cg_info(target, 53, "B07a", "CF03_09M")
				set_cg_info(target, 53, "B07a", "CF03_10M")
			elif id == 26:
				set_cg_info(target, 54, "B21a", "CF04_01M")
				set_cg_info(target, 54, "B21a", "CF04_02M")
				set_cg_info(target, 54, "B21a", "CF04_03M")
				set_cg_info(target, 54, "B21a", "CF04_04M")
				set_cg_info(target, 54, "B21a", "CF04_05M")
				set_cg_info(target, 54, "B21a", "CF04_06M")
				set_cg_info(target, 54, "B21a", "CF04_07M")
				set_cg_info(target, 54, "B21a", "CF04_08M")
				set_cg_info(target, 54, "B21a", "CF04_09M")
				set_cg_info(target, 54, "B21a", "CF04_10M")
			elif id == 27:
				set_cg_info(target, 55, "B20a", "CF05_01M", Vector2(400, 0))
				set_cg_info(target, 55, "B20a", "CF05_02M", Vector2(400, 0))
				set_cg_info(target, 55, "B20a", "CF05_03M", Vector2(400, 0))
				set_cg_info(target, 55, "B20a", "CF05_04M", Vector2(400, 0))
				set_cg_info(target, 55, "B20a", "CF05_05M", Vector2(400, 0))
				set_cg_info(target, 55, "B20a", "CF05_06M", Vector2(400, 0))
				set_cg_info(target, 55, "B20a", "CF05_07M", Vector2(400, 0))
				set_cg_info(target, 55, "B20a", "CF05_08M", Vector2(400, 0))
				set_cg_info(target, 55, "B20a", "CF05_09M", Vector2(400, 0))
				set_cg_info(target, 55, "B20a", "CF05_10M", Vector2(400, 0))
			elif id == 28:
				set_cg_info(target, 56, "B23a", "CF06_01M")
				set_cg_info(target, 56, "B23a", "CF06_02M")
				set_cg_info(target, 56, "B23a", "CF06_03M")
				set_cg_info(target, 56, "B23a", "CF06_04M")
				set_cg_info(target, 56, "B23a", "CF06_05M")
				set_cg_info(target, 56, "B23a", "CF06_06M")
				set_cg_info(target, 56, "B23a", "CF06_07M")
				set_cg_info(target, 56, "B23a", "CF06_08M")
				set_cg_info(target, 56, "B23a", "CF06_09M")
				set_cg_info(target, 56, "B23a", "CF06_10M")
			elif id == 29:
				set_cg_info(target, 81, "B22a", "CJ01_01M")
				set_cg_info(target, 81, "B22a", "CJ01_02M")
				set_cg_info(target, 81, "B22a", "CJ01_03M")
			elif id == 30:
				set_cg_info(target, 221, "EC02a")
				set_cg_info(target, 222, "EC02b")
				set_cg_info(target, 223, "EC02c")
			elif id == 31:
				set_cg_info(target, 231, "ED02a")
			elif id == 32:
				set_cg_info(target, 251, "EE02a")
				set_cg_info(target, 252, "EE02b")
				set_cg_info(target, 253, "EE02c")
				set_cg_info(target, 254, "EE02d")

func recollect_proc(cid: StringName) -> bool:
	if cid.begins_with("ID_RECSEL"):
		var id := int(cid.trim_prefix("ID_RECSEL")) - 1
		if   sel_tag == 0 and id == 0:
			await start_recollect("00_A011")
		elif sel_tag == 0 and id == 1:
			await start_recollect("00_A016")
		elif sel_tag == 0 and id == 2:
			await start_recollect("00_A020")
		elif sel_tag == 1 and id == 0:
			await start_recollect("00_G016")
		elif sel_tag == 1 and id == 1:
			await start_recollect("00_G019")
		elif sel_tag == 1 and id == 2:
			await start_recollect("00_G024")
		elif sel_tag == 2 and id == 0:
			await start_recollect("00_H028")
		elif sel_tag == 2 and id == 1:
			await start_recollect("00_H031B")
	else:
		return false
	return true

func start_recollect(scenario: String) -> void:
	var flag := is_play_bgm
	stop_bgm()
	Global.adv.set_cg_("BLACK")
	Global.adv.bustup_clear(0)
	await Global.adv.update_(true)
	await _hide()
	mini_destroy()
	Global.cnf_obj.play_bgm = cnf_play_bgm
	Global.sc_obj = ScenarioObject.new()
	await Global.scenario_loop(scenario)
	cnf_play_bgm = Global.cnf_obj.play_bgm
	Global.cnf_obj.play_bgm = true
	if cnf_play_bgm:
		mini_create(sel_tag, sel_page, sel_play_bgm)
	else:
		mini_create(sel_tag, sel_page)
	check_button()
	Global.setup_adv_screen()
	_show()
	is_play_bgm = flag

func check_palette_recollect(flag: int, id: int, sprite_id: String) -> void:
	var id_rec: TextureRect = spr_thumb_base.get_node("ID_REC" + str(id))
	var id_recsel: Control = spr_thumb_base.get_node("ID_RECSEL" + str(id))
	if Global.chk_recollect_flag(flag):
		id_rec.modulate.a = 1.0
		id_recsel.show()
		id_rec.texture = Global.option_skin.get_texture("ID_" + sprite_id)
	else:
		id_rec.modulate.a = 1.0
		id_recsel.hide()
		id_rec.texture = Global.option_skin.get_texture(&"ID_FRM_0733")

func player_proc(cid: StringName) -> bool:
	if cid == &"ID_STOP":
		if SoundSystem.is_play_bgm():
			stop_bgm()
			sel_play_bgm = -1
	elif cid == &"ID_BGM1":
		play_bgm(0)
	elif cid == &"ID_BGM2":
		play_bgm(1)
	elif cid == &"ID_BGM3":
		play_bgm(2)
	elif cid == &"ID_BGM4":
		play_bgm(3)
	elif cid == &"ID_BGM5":
		play_bgm(4)
	elif cid == &"ID_BGM6":
		play_bgm(5)
	elif cid == &"ID_BGM7":
		play_bgm(6)
	elif cid == &"ID_BGM8":
		play_bgm(7)
	elif cid == &"ID_BGM9":
		play_bgm(8)
	elif cid == &"ID_BGM10":
		play_bgm(9)
	elif cid == &"ID_BGM11":
		play_bgm(10)
	elif cid == &"ID_BGM12":
		play_bgm(11)
	elif cid == &"ID_BGM13":
		play_bgm(12)
	elif cid == &"ID_BGM14":
		play_bgm(13)
	elif cid == &"ID_BGM15":
		play_bgm(14)
	elif cid == &"ID_BGM16":
		play_bgm(15)
	elif cid == &"ID_BGM17":
		play_bgm(16)
	elif cid == &"ID_BGM18":
		play_bgm(17)
	elif cid == &"ID_BGM19":
		play_bgm(18)
	elif cid == &"ID_BGM20":
		play_bgm(19)
	elif cid == &"ID_BGM21":
		play_bgm(20)
	elif cid == &"ID_BGM22":
		play_bgm(21)
	else:
		return false
	return true

func play_bgm(id: int) -> void:
	var bgms := [
		"BGM01", "BGM03", "BGM04", "BGM05",
		"BGM06", "BGM07", "BGM08", "BGM09",
		"BGM10", "BGM11", "BGM12", "BGM13",
		"BGM14", "BGM15", "BGM16", "BGM17",
		"BGM18", "BGM19", "BGM20", "BGM21",
		"BGM02_S", "BGM22_S"
	]
	if id not in range(bgms.size()):
		return
	SoundSystem.play_bgm(bgms[id], true)
	sel_play_bgm = id
	is_play_bgm = true

func stop_bgm() -> void:
	SoundSystem.stop_bgm(true)
	is_play_bgm = false

func check_button() -> void:
	for i in range(4):
		if check[i] == 5:
			spr_tag[i].get_node("ID_REC").button_pressed = true
		else:
			spr_tag[i].get_node("ID_PAGE%d" % check[i]).button_pressed = true

func run() -> void:
	cnf_play_bgm = Global.cnf_obj.play_bgm
	Global.cnf_obj.play_bgm = true
	check = [2, 2, 2, 4]
	check_button()
	Global.setup_adv_screen()
	_show()
	while true:
		var control := await Global.poll_ui_event()
		var cid := control.name if control else &""
		if Input.is_action_just_pressed("hit_cancel"):
			break
		elif await cg_proc(cid, control): pass
		elif await recollect_proc(cid): pass
		elif player_proc(cid): pass
	Global.adv.set_cg_("BLACK")
	Global.adv.bustup_clear(0)
	await Global.adv.update_(true)
	Global.destroy_adv_screen()
	await _hide()
	SoundSystem.stop_bgm(true)
	Global.cnf_obj.play_bgm = cnf_play_bgm
