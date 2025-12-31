extends Node2D

@export var bgm_list: Array[AudioStreamWAV]

func _ready() -> void:
	var zip := ZIPPacker.new()
	var err := zip.open("./sound.zip")
	if err != OK:
		printerr(err)
		return
	for bgm in bgm_list:
		var file_wav := bgm.resource_path.get_file()
		if not file_wav.ends_with(".wav"):
			printerr("%s is not a wav file." % file_wav)
			continue
		if bgm.format != AudioStreamWAV.FORMAT_QOA:
			printerr("%s is not QOA compressed.")
			continue
		var file_qoa := file_wav.trim_suffix(".wav") + ".qoa"
		zip.start_file(file_qoa)
		zip.write_file(bgm.data)
		zip.close_file()
		print("%s -> %s" % [file_wav, file_qoa])
	zip.close()
	print("Successfully written sound.zip")
