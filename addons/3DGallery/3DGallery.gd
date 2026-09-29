@tool
extends EditorPlugin

const MainPanel = preload("res://addons/3DGallery/gallery.tscn")

var main_panel_instance
var refresh_pending := false


func _enter_tree():
	main_panel_instance = MainPanel.instantiate()
	# Add the main panel to the editor's main viewport.
	EditorInterface.get_editor_main_screen().add_child(main_panel_instance)
	var filesystem = EditorInterface.get_resource_filesystem()
	filesystem.filesystem_changed.connect(_on_filesystem_changed)
	filesystem.resources_reimported.connect(_on_resources_reimported)
	# Hide the main panel. Very much required.
	_make_visible(false)


func _exit_tree():
	var filesystem = EditorInterface.get_resource_filesystem()
	if filesystem.filesystem_changed.is_connected(_on_filesystem_changed):
		filesystem.filesystem_changed.disconnect(_on_filesystem_changed)
	if filesystem.resources_reimported.is_connected(_on_resources_reimported):
		filesystem.resources_reimported.disconnect(_on_resources_reimported)
	if main_panel_instance:
		main_panel_instance.queue_free()


func _on_filesystem_changed():
	_refresh_gallery()


func _on_resources_reimported(_resources: PackedStringArray):
	_refresh_gallery()


func _refresh_gallery():
	if refresh_pending:
		return
	refresh_pending = true
	call_deferred("_refresh_gallery_deferred")


func _refresh_gallery_deferred():
	refresh_pending = false
	if main_panel_instance:
		main_panel_instance.get_node("TabContainer/3D Models/GalleryTree").refresh()


func _has_main_screen():
	return true

func _make_visible(visible):
	if main_panel_instance:
		main_panel_instance.visible = visible

func _get_plugin_name():
	return "3D Gallery"


func _get_plugin_icon():
	return EditorInterface.get_editor_theme().get_icon("Node", "EditorIcons")
