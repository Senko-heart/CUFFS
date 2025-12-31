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
var sel_play_bgm := -1
var is_play_bgm := false
var scroll := false
var scroll_t := 0.0
var cnf_play_bgm := false

func _init(parent: Node, tag_id: int = 0, page_id: int = 0, bgm: int = -1) -> void:
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
	for i in range(6):
		var tag := option_skin.create_form_page("ID_PAGE_TAG" + str(i + 1))
		tag.get_node("ID_PAGE1").button_pressed = true
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
	for tag in spr_tag:
		if tag != spr_tag[tag_id]:
			tag.get_node("ID_PAGE1").button_pressed = true
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
		cg_num = 23
		if page == 0:
			check_palette_cg(1, 1, "CA01")
			check_palette_cg(2, 2, "CA02")
			check_palette_cg(3, 3, "CA03")
			check_palette_cg(4, 4, "CA04")
			check_palette_cg(6, 5, "CA06")
			check_palette_cg(5, 6, "CA05")
			check_palette_cg(7, 7, "CA07")
			check_palette_cg(100, 8, "EA01")
			check_palette_cg(110, 9, "EA02")
			check_palette_cg(120, 10, "EA03")
			check_palette_cg(130, 11, "EA04")
			check_palette_cg(140, 12, "EA05")
		elif page == 1:
			check_palette_cg(150, 1, "EA06")
			check_palette_cg(160, 2, "EA07")
			check_palette_cg(170, 3, "EA08")
			check_palette_cg(180, 4, "EA09")
			check_palette_cg(190, 5, "EA10")
			check_palette_cg(200, 6, "EA11")
			check_palette_cg(210, 7, "EA12")
			check_palette_cg(220, 8, "EA13")
			check_palette_cg(250, 9, "EA16")
			check_palette_cg(260, 10, "EA17")
			check_palette_cg(270, 11, "EA18")
		elif page == 3:
			check_palette_recollect(1, 1, "REC_SR1")
			check_palette_recollect(2, 2, "REC_SR2")
			check_palette_recollect(3, 3, "REC_SR3")
			check_palette_recollect(4, 4, "REC_SR4")
			check_palette_recollect(5, 5, "REC_SR5")
	elif tag_id == 1:
		cg_num = 21
		if page == 0:
			check_palette_cg(11, 1, "CB01")
			check_palette_cg(12, 2, "CB02")
			check_palette_cg(13, 3, "CB03")
			check_palette_cg(14, 4, "CB04")
			check_palette_cg(16, 5, "CB06")
			check_palette_cg(17, 6, "CB07")
			check_palette_cg(280, 7, "EB01")
			check_palette_cg(290, 8, "EB02")
			check_palette_cg(300, 9, "EB03")
			check_palette_cg(310, 10, "EB04")
			check_palette_cg(320, 11, "EB05")
			check_palette_cg(330, 12, "EB06")
		elif page == 1:
			check_palette_cg(340, 1, "EB07")
			check_palette_cg(350, 2, "EB08")
			check_palette_cg(370, 3, "EB10")
			check_palette_cg(380, 4, "EB11")
			check_palette_cg(390, 5, "EB12")
			check_palette_cg(400, 6, "EB13")
			check_palette_cg(430, 7, "EB16")
			check_palette_cg(440, 8, "EB17")
			check_palette_cg(450, 9, "EB18")
		elif page == 3:
			check_palette_recollect(6, 1, "REC_NO1")
			check_palette_recollect(7, 2, "REC_NO2")
			check_palette_recollect(8, 3, "REC_NO3")
			check_palette_recollect(9, 4, "REC_NO4")
	elif tag_id == 2:
		cg_num = 22
		if page == 0:
			check_palette_cg(21, 1, "CC01")
			check_palette_cg(22, 2, "CC02")
			check_palette_cg(23, 3, "CC03")
			check_palette_cg(26, 4, "CC06")
			check_palette_cg(24, 5, "CC04")
			check_palette_cg(28, 6, "CC08")
			check_palette_cg(25, 7, "CC05")
			check_palette_cg(27, 8, "CC07")
			check_palette_cg(460, 9, "EC01")
			check_palette_cg(470, 10, "EC02")
			check_palette_cg(480, 11, "EC03")
			check_palette_cg(500, 12, "EC05")
		elif page == 1:
			check_palette_cg(510, 1, "EC06")
			check_palette_cg(520, 2, "EC07")
			check_palette_cg(540, 3, "EC09")
			check_palette_cg(550, 4, "EC10")
			check_palette_cg(560, 5, "EC11")
			check_palette_cg(570, 6, "EC12")
			check_palette_cg(580, 7, "EC13")
			check_palette_cg(610, 8, "EC16")
			check_palette_cg(620, 9, "EC17")
			check_palette_cg(630, 10, "EC18")
		elif page == 3:
			check_palette_recollect(10, 1, "REC_AK1")
			check_palette_recollect(11, 2, "REC_AK2")
			check_palette_recollect(12, 3, "REC_AK3")
	elif tag_id == 3:
		cg_num = 22
		if page == 0:
			check_palette_cg(31, 1, "CD01")
			check_palette_cg(32, 2, "CD02")
			check_palette_cg(33, 3, "CD03")
			check_palette_cg(34, 4, "CD04")
			check_palette_cg(37, 5, "CD07")
			check_palette_cg(35, 6, "CD05")
			check_palette_cg(36, 7, "CD06")
			check_palette_cg(640, 8, "ED01")
			check_palette_cg(650, 9, "ED02")
			check_palette_cg(660, 10, "ED03")
			check_palette_cg(670, 11, "ED04")
			check_palette_cg(680, 12, "ED05")
		elif page == 1:
			check_palette_cg(690, 1, "ED06")
			check_palette_cg(700, 2, "ED07")
			check_palette_cg(720, 3, "ED09")
			check_palette_cg(730, 4, "ED10")
			check_palette_cg(740, 5, "ED11")
			check_palette_cg(750, 6, "ED12")
			check_palette_cg(760, 7, "ED13")
			check_palette_cg(790, 8, "ED16")
			check_palette_cg(800, 9, "ED17")
			check_palette_cg(810, 10, "ED18")
		elif page == 3:
			check_palette_recollect(13, 1, "REC_KA1")
			check_palette_recollect(14, 2, "REC_KA2")
			check_palette_recollect(15, 3, "REC_KA3")
	elif tag_id == 4:
		cg_num = 19
		if page == 0:
			check_palette_cg(41, 1, "CE01")
			check_palette_cg(42, 2, "CE02")
			check_palette_cg(43, 3, "CE03")
			check_palette_cg(44, 4, "CE04")
			check_palette_cg(820, 5, "EE01")
			check_palette_cg(830, 6, "EE02")
			check_palette_cg(840, 7, "EE03")
			check_palette_cg(850, 8, "EE04")
			check_palette_cg(860, 9, "EE05")
			check_palette_cg(870, 10, "EE06")
			check_palette_cg(880, 11, "EE07")
			check_palette_cg(890, 12, "EE08")
		elif page == 1:
			check_palette_cg(910, 1, "EE10")
			check_palette_cg(920, 2, "EE11")
			check_palette_cg(930, 3, "EE12")
			check_palette_cg(940, 4, "EE13")
			check_palette_cg(970, 5, "EE16")
			check_palette_cg(980, 6, "EE17")
			check_palette_cg(990, 7, "EE18")
		elif page == 3:
			check_palette_recollect(16, 1, "REC_MT1")
			check_palette_recollect(17, 2, "REC_MT2")
			check_palette_recollect(18, 3, "REC_MT3")
	elif tag_id == 5:
		cg_num = 21
		if page == 0:
			check_palette_cg(51, 1, "CF01")
			check_palette_cg(52, 2, "CF02")
			check_palette_cg(53, 3, "CF03")
			check_palette_cg(54, 4, "CF04")
			check_palette_cg(55, 5, "CF05")
			check_palette_cg(56, 6, "CF06")
			check_palette_cg(61, 7, "CG01")
			check_palette_cg(62, 8, "CG02")
			check_palette_cg(63, 9, "CG03")
			check_palette_cg(71, 10, "CH01")
			check_palette_cg(72, 11, "CH02")
			check_palette_cg(74, 12, "CH04")
		elif page == 1:
			check_palette_cg(77, 1, "CH07")
			check_palette_cg(75, 2, "CH05")
			check_palette_cg(76, 3, "CH06")
			check_palette_cg(81, 4, "CJ01")
			check_palette_cg(91, 5, "CK01")
			check_palette_cg(1000, 6, "EZ01")
			check_palette_cg(1030, 7, "EZ04")
			check_palette_cg(1040, 8, "EZ05")
			check_palette_cg(1050, 9, "EZ06")
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
	or cid == &"ID_REC"):
		var tag_item := control.get_parent()
		var tag := int(tag_item.name.trim_prefix("ID_PAGE_TAG")) - 1
		var nodes := ["ID_PAGE1", "ID_PAGE2", "ID_PAGE3", "ID_REC"]
		for i in range(nodes.size()):
			if tag_item.has_node(nodes[i]):
				if tag_item.get_node(nodes[i]).button_pressed:
					set_page(tag, i)
					break
	elif cid.begins_with("ID_CGSEL"):
		var id := int(cid.trim_prefix("ID_CGSEL")) - 1
		await show_cg_loop(sel_tag, sel_page * 12 + id)
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
		if Input.is_action_just_pressed("ui_up"):
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
		elif cid == &"ID_CLOSE" or Input.is_action_just_pressed("hide_adv"):
			spr_scroll.hide()
		elif cid == &"ID_SCROLL":
			scroll_t = id_scroll.ratio
			var info := cg_view_man[id].thumb_info[index]
			var a := info.pt_cg1
			var b := info.pt_cg2
			var d := (b - a) / 3.0
			var pt := a.bezier_interpolate(a + d, b - d, b, scroll_t)
			Global.adv.spr_cg.position = -pt
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
				set_cg_info(target, 6, "B21a", "CA06_01S")
				set_cg_info(target, 6, "B21a", "CA06_02S")
				set_cg_info(target, 6, "B21a", "CA06_03S")
				set_cg_info(target, 6, "B21a", "CA06_04S")
				set_cg_info(target, 6, "B21a", "CA06_05S")
				set_cg_info(target, 6, "B21a", "CA06_06S")
				set_cg_info(target, 6, "B21a", "CA06_07S")
				set_cg_info(target, 6, "B21a", "CA06_08S")
				set_cg_info(target, 6, "B21a", "CA06_09S")
				set_cg_info(target, 6, "B21a", "CA06_10S")
				set_cg_info(target, 6, "B21a", "CA06_11S")
				set_cg_info(target, 6, "B21a", "CA06_12S")
				set_cg_info(target, 6, "B21a", "CA06_13S")
			elif id == 5:
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
			elif id == 6:
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
			elif id == 7:
				set_cg_info(target, 101, "EA01A")
				set_cg_info(target, 102, "EA01B")
				set_cg_info(target, 103, "EA01C")
				set_cg_info(target, 104, "EA01D")
				set_cg_info(target, 105, "EA01E")
				set_cg_info(target, 106, "EA01F")
				set_cg_info(target, 107, "EA01G")
				set_cg_info(target, 108, "EA01H")
			elif id == 8:
				set_cg_info(target, 111, "EA02")
			elif id == 9:
				set_cg_info(target, 121, "EA03A")
				set_cg_info(target, 122, "EA03B")
			elif id == 10:
				set_cg_info(target, 131, "EA04A")
				set_cg_info(target, 132, "EA04B")
				set_cg_info(target, 133, "EA04C")
			elif id == 11:
				set_cg_info(target, 141, "EA05")
			elif id == 12:
				set_cg_info(target, 151, "EA06a", "", Vector2(269, 0), Vector2(0, 266))
				set_cg_info(target, 152, "EA06b", "", Vector2(269, 0), Vector2(0, 266))
				set_cg_info(target, 153, "EA06c", "", Vector2(269, 0), Vector2(0, 266))
			elif id == 13:
				set_cg_info(target, 161, "EA07")
			elif id == 14:
				set_cg_info(target, 171, "EA08A", "", Vector2(0, 700), Vector2(0, 0))
				set_cg_info(target, 172, "EA08B", "", Vector2(0, 700), Vector2(0, 0))
				set_cg_info(target, 173, "EA08C", "", Vector2(0, 700), Vector2(0, 0))
			elif id == 15:
				set_cg_info(target, 181, "EA09A")
				set_cg_info(target, 182, "EA09B")
				set_cg_info(target, 183, "EA09C")
				set_cg_info(target, 184, "EA09D")
			elif id == 16:
				set_cg_info(target, 191, "EA10A")
				set_cg_info(target, 192, "EA10B")
				set_cg_info(target, 193, "EA10C")
				set_cg_info(target, 194, "EA10D")
			elif id == 17:
				set_cg_info(target, 201, "EA11A")
				set_cg_info(target, 202, "EA11B")
				set_cg_info(target, 203, "EA11C")
				set_cg_info(target, 203, "EA11D")
			elif id == 18:
				set_cg_info(target, 211, "EA12A")
				set_cg_info(target, 212, "EA12B")
				set_cg_info(target, 213, "EA12C")
			elif id == 19:
				set_cg_info(target, 221, "EA13A")
				set_cg_info(target, 222, "EA13B")
				set_cg_info(target, 223, "EA13C")
			elif id == 20:
				set_cg_info(target, 251, "EA16A")
				set_cg_info(target, 252, "EA16B")
			elif id == 21:
				set_cg_info(target, 261, "EA17A")
				set_cg_info(target, 262, "EA17B")
				set_cg_info(target, 263, "EA17C")
			elif id == 22:
				set_cg_info(target, 271, "EA18A")
				set_cg_info(target, 272, "EA18B")
	elif tag_id == 1:
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
				set_cg_info(target, 13, "B06a", "CB03_01M")
				set_cg_info(target, 13, "B06a", "CB03_02M")
				set_cg_info(target, 13, "B06a", "CB03_03M")
				set_cg_info(target, 13, "B06a", "CB03_04M")
				set_cg_info(target, 13, "B06a", "CB03_05M")
				set_cg_info(target, 13, "B06a", "CB03_06M")
				set_cg_info(target, 13, "B06a", "CB03_07M")
				set_cg_info(target, 13, "B06a", "CB03_08M")
				set_cg_info(target, 13, "B06a", "CB03_09M")
				set_cg_info(target, 13, "B06a", "CB03_10M")
				set_cg_info(target, 13, "B06a", "CB03_11M")
				set_cg_info(target, 13, "B06a", "CB03_12M")
				set_cg_info(target, 13, "B06a", "CB03_13M")
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
				set_cg_info(target, 281, "EB01A")
				set_cg_info(target, 282, "EB01B")
			elif id == 7:
				set_cg_info(target, 291, "EB02A")
				set_cg_info(target, 292, "EB02B")
			elif id == 8:
				set_cg_info(target, 301, "EB03")
			elif id == 9:
				set_cg_info(target, 311, "EB04A")
				set_cg_info(target, 312, "EB04B")
				set_cg_info(target, 313, "EB04A_")
			elif id == 10:
				set_cg_info(target, 321, "EB05")
			elif id == 11:
				set_cg_info(target, 331, "EB06A", "", Vector2(0, 0), Vector2(0, 258))
				set_cg_info(target, 332, "EB06B", "", Vector2(0, 0), Vector2(0, 258))
			elif id == 12:
				set_cg_info(target, 341, "EB07A")
				set_cg_info(target, 342, "EB07B")
			elif id == 13:
				set_cg_info(target, 351, "EB08A")
				set_cg_info(target, 352, "EB08B")
				set_cg_info(target, 353, "EB08C")
				set_cg_info(target, 354, "EB08A_")
				set_cg_info(target, 355, "EB08B_")
			elif id == 14:
				set_cg_info(target, 371, "EB10A")
				set_cg_info(target, 372, "EB10B")
			elif id == 15:
				set_cg_info(target, 381, "EB11A")
				set_cg_info(target, 382, "EB11B")
			elif id == 16:
				set_cg_info(target, 391, "EB12A")
				set_cg_info(target, 392, "EB12B")
				set_cg_info(target, 393, "EB12C")
			elif id == 17:
				set_cg_info(target, 401, "EB13A")
				set_cg_info(target, 402, "EB13B")
			elif id == 18:
				set_cg_info(target, 431, "EB16A")
				set_cg_info(target, 432, "EB16B")
				set_cg_info(target, 433, "EB16C")
			elif id == 19:
				set_cg_info(target, 441, "EB17A")
				set_cg_info(target, 442, "EB17B")
				set_cg_info(target, 443, "EB17C")
			elif id == 20:
				set_cg_info(target, 451, "EB18")
	elif tag_id == 2:
		if not cg_view_man[id].is_create:
			cg_view_man[id].is_create = true
			if id == 0:
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
			elif id == 1:
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
			elif id == 2:
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
			elif id == 3:
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
			elif id == 4:
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
			elif id == 5:
				set_cg_info(target, 28, "B21a", "CC08_01S")
				set_cg_info(target, 28, "B21a", "CC08_02S")
				set_cg_info(target, 28, "B21a", "CC08_03S")
				set_cg_info(target, 28, "B21a", "CC08_04S")
				set_cg_info(target, 28, "B21a", "CC08_05S")
				set_cg_info(target, 28, "B21a", "CC08_06S")
				set_cg_info(target, 28, "B21a", "CC08_07S")
				set_cg_info(target, 28, "B21a", "CC08_08S")
				set_cg_info(target, 28, "B21a", "CC08_09S")
				set_cg_info(target, 28, "B21a", "CC08_10S")
				set_cg_info(target, 28, "B21a", "CC08_11S")
				set_cg_info(target, 28, "B21a", "CC08_12S")
				set_cg_info(target, 28, "B21a", "CC08_13S")
				set_cg_info(target, 28, "B21a", "CC08_14S")
			elif id == 6:
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
			elif id == 7:
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
			elif id == 8:
				set_cg_info(target, 461, "EC01A")
				set_cg_info(target, 462, "EC01B")
			elif id == 9:
				set_cg_info(target, 471, "EC02A")
				set_cg_info(target, 472, "EC02B")
				set_cg_info(target, 473, "EC02C")
			elif id == 10:
				set_cg_info(target, 481, "EC03A")
				set_cg_info(target, 482, "EC03B")
				set_cg_info(target, 483, "EC03C")
				set_cg_info(target, 484, "EC03D")
			elif id == 11:
				set_cg_info(target, 501, "EC05A")
				set_cg_info(target, 502, "EC05B")
			elif id == 12:
				set_cg_info(target, 511, "EC06A", "", Vector2(0, 0), Vector2(0, 370))
				set_cg_info(target, 512, "EC06B", "", Vector2(0, 0), Vector2(0, 370))
			elif id == 13:
				set_cg_info(target, 521, "EC07A")
				set_cg_info(target, 522, "EC07B")
				set_cg_info(target, 523, "EC07C")
			elif id == 14:
				set_cg_info(target, 541, "EC09")
			elif id == 15:
				set_cg_info(target, 551, "EC10A")
				set_cg_info(target, 552, "EC10B")
				set_cg_info(target, 553, "EC10C")
				set_cg_info(target, 554, "EC10D")
				set_cg_info(target, 555, "EC10E")
				set_cg_info(target, 556, "EC10F")
			elif id == 16:
				set_cg_info(target, 561, "EC11A")
				set_cg_info(target, 562, "EC11B")
				set_cg_info(target, 563, "EC11C")
			elif id == 17:
				set_cg_info(target, 571, "EC12A")
				set_cg_info(target, 572, "EC12B")
				set_cg_info(target, 573, "EC12C")
			elif id == 18:
				set_cg_info(target, 581, "EC13A")
				set_cg_info(target, 582, "EC13B")
				set_cg_info(target, 583, "EC13C")
				set_cg_info(target, 584, "EC13D")
				set_cg_info(target, 584, "EC13E")
			elif id == 19:
				set_cg_info(target, 611, "EC16A")
				set_cg_info(target, 612, "EC16B")
				set_cg_info(target, 613, "EC16C")
				set_cg_info(target, 614, "EC16D")
			elif id == 20:
				set_cg_info(target, 621, "EC17A")
				set_cg_info(target, 622, "EC17B")
				set_cg_info(target, 623, "EC17C")
			elif id == 21:
				set_cg_info(target, 631, "EC18")
	elif tag_id == 3:
		if not cg_view_man[id].is_create:
			cg_view_man[id].is_create = true
			if id == 0:
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
			elif id == 1:
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
			elif id == 2:
				set_cg_info(target, 33, "B07d", "CD03_01M")
				set_cg_info(target, 33, "B07d", "CD03_02M")
				set_cg_info(target, 33, "B07d", "CD03_03M")
				set_cg_info(target, 33, "B07d", "CD03_04M")
				set_cg_info(target, 33, "B07d", "CD03_05M")
				set_cg_info(target, 33, "B07d", "CD03_06M")
				set_cg_info(target, 33, "B07d", "CD03_07M")
				set_cg_info(target, 33, "B07d", "CD03_08M")
				set_cg_info(target, 33, "B07d", "CD03_09M")
				set_cg_info(target, 33, "B07d", "CD03_10M")
				set_cg_info(target, 33, "B07d", "CD03_11M")
				set_cg_info(target, 33, "B07d", "CD03_12M")
				set_cg_info(target, 33, "B07d", "CD03_13M")
			elif id == 3:
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
			elif id == 4:
				set_cg_info(target, 37, "B21a", "CD07_01S")
				set_cg_info(target, 37, "B21a", "CD07_02S")
				set_cg_info(target, 37, "B21a", "CD07_03S")
				set_cg_info(target, 37, "B21a", "CD07_04S")
				set_cg_info(target, 37, "B21a", "CD07_05S")
				set_cg_info(target, 37, "B21a", "CD07_06S")
				set_cg_info(target, 37, "B21a", "CD07_07S")
				set_cg_info(target, 37, "B21a", "CD07_08S")
				set_cg_info(target, 37, "B21a", "CD07_09S")
				set_cg_info(target, 37, "B21a", "CD07_10S")
				set_cg_info(target, 37, "B21a", "CD07_11S")
				set_cg_info(target, 37, "B21a", "CD07_12S")
				set_cg_info(target, 37, "B21a", "CD07_13S")
			elif id == 5:
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
			elif id == 6:
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
			elif id == 7:
				set_cg_info(target, 641, "ED01A")
				set_cg_info(target, 642, "ED01B")
				set_cg_info(target, 643, "ED01C")
			elif id == 8:
				set_cg_info(target, 651, "ED02A")
				set_cg_info(target, 652, "ED02B")
			elif id == 9:
				set_cg_info(target, 661, "ED03A")
				set_cg_info(target, 662, "ED03B")
				set_cg_info(target, 663, "ED03C")
			elif id == 10:
				set_cg_info(target, 671, "ED04")
			elif id == 11:
				set_cg_info(target, 681, "ED05")
			elif id == 12:
				set_cg_info(target, 691, "ED06A")
				set_cg_info(target, 692, "ED06B")
				set_cg_info(target, 693, "ED06C")
			elif id == 13:
				set_cg_info(target, 701, "ED07A")
				set_cg_info(target, 702, "ED07B")
			elif id == 14:
				set_cg_info(target, 721, "ED09")
			elif id == 15:
				set_cg_info(target, 731, "ED10A")
				set_cg_info(target, 732, "ED10B")
				set_cg_info(target, 733, "ED10C")
			elif id == 16:
				set_cg_info(target, 741, "ED11A")
				set_cg_info(target, 742, "ED11B")
				set_cg_info(target, 743, "ED11C")
				set_cg_info(target, 744, "ED11D")
			elif id == 17:
				set_cg_info(target, 751, "ED12A")
				set_cg_info(target, 752, "ED12B")
				set_cg_info(target, 753, "ED12C")
			elif id == 18:
				set_cg_info(target, 761, "ED13A")
				set_cg_info(target, 762, "ED13B")
			elif id == 19:
				set_cg_info(target, 791, "ED16A")
				set_cg_info(target, 792, "ED16B")
				set_cg_info(target, 793, "ED16C")
			elif id == 20:
				set_cg_info(target, 801, "ED17A")
				set_cg_info(target, 802, "ED17B")
				set_cg_info(target, 803, "ED17C")
			elif id == 21:
				set_cg_info(target, 811, "ED18A")
				set_cg_info(target, 812, "ED18B")
				set_cg_info(target, 813, "ED18C")
	elif tag_id == 4:
		if not cg_view_man[id].is_create:
			cg_view_man[id].is_create = true
			if id == 0:
				set_cg_info(target, 41, "B09a", "CE01_01M")
				set_cg_info(target, 41, "B09a", "CE01_02M")
				set_cg_info(target, 41, "B09a", "CE01_03M")
				set_cg_info(target, 41, "B09a", "CE01_04M")
				set_cg_info(target, 41, "B09a", "CE01_05M")
				set_cg_info(target, 41, "B09a", "CE01_06M")
				set_cg_info(target, 41, "B09a", "CE01_07M")
				set_cg_info(target, 41, "B09a", "CE01_08M")
				set_cg_info(target, 41, "B09a", "CE01_09M")
				set_cg_info(target, 41, "B09a", "CE01_10M")
				set_cg_info(target, 41, "B09a", "CE01_11M")
				set_cg_info(target, 41, "B09a", "CE01_12M")
			elif id == 1:
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
			elif id == 2:
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
			elif id == 3:
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
			elif id == 4:
				set_cg_info(target, 821, "EE01A")
				set_cg_info(target, 822, "EE01B")
				set_cg_info(target, 823, "EE01C")
				set_cg_info(target, 824, "EE01D")
			elif id == 5:
				set_cg_info(target, 831, "EE02A")
				set_cg_info(target, 832, "EE02B")
				set_cg_info(target, 833, "EE02C")
				set_cg_info(target, 834, "EE02D")
			elif id == 6:
				set_cg_info(target, 841, "EE03A")
				set_cg_info(target, 842, "EE03B")
			elif id == 7:
				set_cg_info(target, 851, "EE04A")
				set_cg_info(target, 852, "EE04B")
				set_cg_info(target, 853, "EE04C")
			elif id == 8:
				set_cg_info(target, 861, "EE05A")
				set_cg_info(target, 862, "EE05B")
			elif id == 9:
				set_cg_info(target, 871, "EE06A")
				set_cg_info(target, 872, "EE06B")
			elif id == 10:
				set_cg_info(target, 881, "EE07A")
				set_cg_info(target, 882, "EE07B")
			elif id == 11:
				set_cg_info(target, 891, "EE08A")
				set_cg_info(target, 892, "EE08B")
			elif id == 12:
				set_cg_info(target, 911, "EE10A")
				set_cg_info(target, 912, "EE10B")
				set_cg_info(target, 913, "EE10C")
				set_cg_info(target, 914, "EE10D")
			elif id == 13:
				set_cg_info(target, 921, "EE11A")
				set_cg_info(target, 922, "EE11B")
				set_cg_info(target, 923, "EE11C")
			elif id == 14:
				set_cg_info(target, 931, "EE12A")
				set_cg_info(target, 932, "EE12B")
				set_cg_info(target, 933, "EE12C")
				set_cg_info(target, 934, "EE12D")
			elif id == 15:
				set_cg_info(target, 941, "EE13A")
				set_cg_info(target, 942, "EE13B")
				set_cg_info(target, 943, "EE13C")
			elif id == 16:
				set_cg_info(target, 971, "EE16A")
				set_cg_info(target, 972, "EE16B")
			elif id == 17:
				set_cg_info(target, 981, "EE17A")
				set_cg_info(target, 982, "EE17B")
			elif id == 18:
				set_cg_info(target, 991, "EE18")
	elif tag_id == 5:
		if not cg_view_man[id].is_create:
			cg_view_man[id].is_create = true
			if id == 0:
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
			elif id == 1:
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
			elif id == 2:
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
			elif id == 3:
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
			elif id == 4:
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
			elif id == 5:
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
			elif id == 6:
				set_cg_info(target, 61, "B16a", "CG01_01M")
				set_cg_info(target, 61, "B16a", "CG01_02M")
				set_cg_info(target, 61, "B16a", "CG01_03M")
				set_cg_info(target, 61, "B16a", "CG01_04M")
				set_cg_info(target, 61, "B16a", "CG01_05M")
				set_cg_info(target, 61, "B16a", "CG01_06M")
				set_cg_info(target, 61, "B16a", "CG01_07M")
				set_cg_info(target, 61, "B16a", "CG01_08M")
			elif id == 7:
				set_cg_info(target, 62, "B15a", "CG02_01M")
				set_cg_info(target, 62, "B15a", "CG02_02M")
				set_cg_info(target, 62, "B15a", "CG02_03M")
				set_cg_info(target, 62, "B15a", "CG02_04M")
				set_cg_info(target, 62, "B15a", "CG02_05M")
				set_cg_info(target, 62, "B15a", "CG02_06M")
				set_cg_info(target, 62, "B15a", "CG02_07M")
				set_cg_info(target, 62, "B15a", "CG02_08M")
			elif id == 8:
				set_cg_info(target, 63, "B39a", "CG03_01M")
				set_cg_info(target, 63, "B39a", "CG03_02M")
				set_cg_info(target, 63, "B39a", "CG03_03M")
				set_cg_info(target, 63, "B39a", "CG03_04M")
				set_cg_info(target, 63, "B39a", "CG03_05M")
				set_cg_info(target, 63, "B39a", "CG03_06M")
				set_cg_info(target, 63, "B39a", "CG03_07M")
				set_cg_info(target, 63, "B39a", "CG03_08M")
			elif id == 9:
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
			elif id == 10:
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
			elif id == 11:
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
			elif id == 12:
				set_cg_info(target, 76, "B21a", "CH07_01S")
				set_cg_info(target, 77, "B21a", "CH07_02S")
				set_cg_info(target, 77, "B21a", "CH07_03S")
				set_cg_info(target, 77, "B21a", "CH07_04S")
				set_cg_info(target, 77, "B21a", "CH07_05S")
				set_cg_info(target, 77, "B21a", "CH07_06S")
				set_cg_info(target, 77, "B21a", "CH07_07S")
				set_cg_info(target, 77, "B21a", "CH07_08S")
				set_cg_info(target, 77, "B21a", "CH07_09S")
				set_cg_info(target, 77, "B21a", "CH07_10S")
				set_cg_info(target, 77, "B21a", "CH07_11S")
			elif id == 13:
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
			elif id == 14:
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
			elif id == 15:
				set_cg_info(target, 81, "B09a", "CJ01_01M")
				set_cg_info(target, 81, "B09a", "CJ01_02M")
				set_cg_info(target, 81, "B09a", "CJ01_03M")
			elif id == 16:
				set_cg_info(target, 91, "B09a", "CK01_01M")
				set_cg_info(target, 91, "B09a", "CK01_02M")
				set_cg_info(target, 91, "B09a", "CK01_03M")
				set_cg_info(target, 91, "B09a", "CK01_04M")
			elif id == 17:
				set_cg_info(target, 91, "EZ01a")
				set_bustup_info(target, "EZ01CA01a", 10, 5)
				set_bustup_info(target, "EZ01CB01a", 8, 1)
				set_bustup_info(target, "EZ01CC01a", 4, 2)
				set_bustup_info(target, "EZ01CD01a", 2, 3)
				set_bustup_info(target, "EZ01CF01a", 6, 4)
				set_cg_info(target, 91, "EZ01b")
				set_bustup_info(target, "EZ01CA01b", 10, 5)
				set_bustup_info(target, "EZ01CB01b", 8, 1)
				set_bustup_info(target, "EZ01CC01b", 4, 2)
				set_bustup_info(target, "EZ01CD01b", 2, 3)
				set_bustup_info(target, "EZ01CF01b", 6, 4)
			elif id == 18:
				set_cg_info(target, 1031, "EZ04A")
				set_cg_info(target, 1032, "EZ04B")
			elif id == 19:
				set_cg_info(target, 1041, "EZ05A")
				set_cg_info(target, 1042, "EZ05B")
				set_cg_info(target, 1043, "EZ05C")
				set_cg_info(target, 1044, "EZ05D")
			elif id == 20:
				set_cg_info(target, 1051, "EZ06A")
				set_cg_info(target, 1052, "EZ06B")
				set_cg_info(target, 1053, "EZ06C")
				set_cg_info(target, 1054, "EZ06D")
				set_cg_info(target, 1055, "EZ06E")
				set_cg_info(target, 1056, "EZ06F")

func recollect_proc(cid: StringName) -> bool:
	if cid.begins_with("ID_RECSEL"):
		var id := int(cid.trim_prefix("ID_RECSEL")) - 1
		if   sel_tag == 0 and id == 0:
			await start_recollect("00_A020")
		elif sel_tag == 0 and id == 1:
			await start_recollect("00_A022")
		elif sel_tag == 0 and id == 2:
			await start_recollect("00_A025B")
		elif sel_tag == 0 and id == 3:
			await start_recollect("00_A026")
		elif sel_tag == 0 and id == 4:
			await start_recollect("00_A032")
		elif sel_tag == 1 and id == 0:
			await start_recollect("00_B005")
		elif sel_tag == 1 and id == 1:
			await start_recollect("00_B021")
		elif sel_tag == 1 and id == 2:
			await start_recollect("00_B025")
		elif sel_tag == 1 and id == 3:
			await start_recollect("00_B032")
		elif sel_tag == 2 and id == 0:
			await start_recollect("00_C019B")
		elif sel_tag == 2 and id == 1:
			await start_recollect("00_C023")
		elif sel_tag == 2 and id == 2:
			await start_recollect("00_C034")
		elif sel_tag == 3 and id == 0:
			await start_recollect("00_D025B")
		elif sel_tag == 3 and id == 1:
			await start_recollect("00_D028B")
		elif sel_tag == 3 and id == 2:
			await start_recollect("00_D042B")
		elif sel_tag == 4 and id == 0:
			await start_recollect("00_E013C")
		elif sel_tag == 4 and id == 1:
			await start_recollect("00_E024B")
		elif sel_tag == 4 and id == 2:
			await start_recollect("00_E036")
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
	Global.cnf_obj.play_bgm = true
	mini_create(sel_tag, sel_page, sel_play_bgm)
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
			sel_play_bgm = true
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
		"BGM02_S"
	]
	if id not in range(bgms.size()):
		return
	SoundSystem.play_bgm(bgms[id], true)
	sel_play_bgm = id
	is_play_bgm = true

func stop_bgm() -> void:
	SoundSystem.stop_bgm(true)
	is_play_bgm = 0

func run() -> void:
	cnf_play_bgm = Global.cnf_obj.play_bgm
	Global.cnf_obj.play_bgm = true
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
