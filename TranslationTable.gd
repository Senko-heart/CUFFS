extends Node

var name_tbl: Dictionary[String, String]
var mess_tbl: Dictionary[int, PackedStringArray] = {}
var choice_tbl: Dictionary[int, String] = {}
var system_tbl: Dictionary[String, String] = {}

func initialize() -> void:
	load_table("name", name_tbl)
	load_table("mess", mess_tbl)
	load_table("choice", choice_tbl)
	load_table("system", system_tbl)
	for key in system_tbl:
		Global.confirm_prompt[key] = system_tbl[key]

func load_table_rows(filename: String, case_sensitive: bool = true) -> PackedStringArray:
	var src := filename + ".tl"
	var patch_src := "scenario".path_join(src)
	var bytes: PackedByteArray
	if FS.patch.file_exists(patch_src, case_sensitive):
		bytes = FS.patch.read_file(patch_src, case_sensitive)
	elif FS.scenario.file_exists(src, case_sensitive):
		bytes = FS.scenario.read_file(src, case_sensitive)
	else: return []
	var string := bytes.get_string_from_utf8()
	return string.split("\n", false)

func load_table(filename: String, tbl: Dictionary) -> void:
	var rows := load_table_rows(filename)
	for row in rows:
		var cols := row.split(";", true, 1)
		if cols.size() != 2: continue
		var key := cols[0]
		var value := cols[1]
		if tbl.get_typed_key_builtin() == TYPE_INT:
			var ikey := key.to_int()
			if tbl.get_typed_value_builtin() == TYPE_STRING:
				tbl[ikey] = value
			else:
				tbl.get_or_add(ikey, PackedStringArray()).append(value)
		else:
			if tbl.get_typed_value_builtin() == TYPE_STRING:
				tbl[key] = value
			else:
				tbl.get_or_add(key, PackedStringArray()).append(value)

func name_(show_name: String) -> String:
	if show_name in name_tbl:
		return name_tbl[show_name]
	return show_name

func mess(id: int) -> String:
	if id not in mess_tbl:
		return "MISSING"
	return "".join(mess_tbl[id])\
		.replace("／", "\n")\
		.replace("　", "  ")

func choice(id: int) -> String:
	return choice_tbl.get(id, "MISSING")
