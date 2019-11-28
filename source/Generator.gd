extends Control

var Loader = preload("res://source/Loader.gd").new()

export var width := 0

var max_image_size := Vector2()

onready var sheet_width := $CenterContainer/VBoxContainer/SheetWidth/LineEdit
onready var name_line := $CenterContainer/VBoxContainer/Name/LineEdit

func _ready() -> void:
	sheet_width.text = str(10)
	name_line.text = "grass"

func _on_Button_pressed() -> void:
	var file_data := Loader.load_dir("res://images", ["png"]) as Array

	max_image_size = get_max_image_size(file_data)
	width = int(sheet_width.text)

	var dimensions = Vector2(width, file_data.size() / width + 1)

	var sheet_image := Image.new()
	var sheet_info := SheetInfo.new()

	sheet_image.create(dimensions.x * max_image_size.x, dimensions.y * max_image_size.y, false, Image.FORMAT_RGBA8)
	sheet_image.fill(Color("00000000"))

	sheet_image.lock()

	var cursor := Vector2(0, 0)
	var max_height := 0

	file_data.sort_custom(self, "sort_image_info")
	file_data.invert()

	for file in file_data:

		var image := file.data.get_data() as Image

		var rect = image.get_used_rect()

		if cursor.x + rect.size.x > width * max_image_size.x:
			cursor.x = 0
			cursor.y += max_height
			max_height = 0

		image.lock()

		# draw pixels
		for p_y in rect.size.y:
			for p_x in rect.size.x:
				var color = image.get_pixel(rect.position.x + p_x, rect.position.y + p_y)
				sheet_image.set_pixel(cursor.x + p_x, cursor.y + p_y, color)

		# make dict entry
		sheet_info.data[file.id] = {}
		sheet_info.data[file.id].id = file.id
		sheet_info.data[file.id].rect = Rect2(Vector2(cursor.x, cursor.y), rect.size)
		sheet_info.data[file.id].offset = rect.position

		cursor.x += rect.size.x
		max_height = max(max_height, rect.size.y)

	var sheet_size = sheet_image.get_used_rect().size
	sheet_image.crop(sheet_size.x, sheet_size.y)
	sheet_image.save_png("res://output/" + name_line.text + ".png")
	ResourceSaver.save("res://output/" + name_line.text + ".tres", sheet_info)

func get_max_image_size(file_data: Array) -> Vector2:
	var max_size = Vector2(0, 0)

	for file in file_data:
		var image := file.data.get_data() as Image
		var size := image.get_size()
		max_size = Vector2(max(max_size.x, size.x), max(max_size.y, size.y))

	return max_size

func sort_image_info(a: Dictionary, b: Dictionary) -> bool:
	var a_image := a.data.get_data() as Image
	var b_image := b.data.get_data() as Image

	return a_image.get_used_rect().size.y < b_image.get_used_rect().size.y
