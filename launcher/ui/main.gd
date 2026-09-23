extends Control

const CREAM := Color("fff3cf")
const GREEN := Color("244b39")
const GOLD := Color("f0bf58")
var worker: Thread
var result: Dictionary = {}
var helper := ""
var install_root := ""
var current := ""
var latest := ""
var previous := ""
var busy := false
var playing := false
var play_after_update := false
var operation := ""
var status: Label
var versions: Label
var notes: RichTextLabel
var play_button: Button
var update_button: Button
var back_button: Button
var check_button: Button
var progress: ProgressBar

func _ready() -> void:
	get_tree().auto_accept_quit = false
	DisplayServer.window_set_min_size(Vector2i(850, 600))
	_build_ui()
	var ext := ".exe" if OS.get_name() == "Windows" else ""
	var resource := "res://bin/updater-windows.exe" if ext != "" else "res://bin/updater-linux"
	var bytes := FileAccess.get_file_as_bytes(resource)
	if bytes.is_empty():
		status.text = "O launcher está incompleto. Baixe o pacote novamente."
		return
	var hash_context := HashingContext.new()
	hash_context.start(HashingContext.HASH_SHA256)
	hash_context.update(bytes)
	var digest := hash_context.finish().hex_encode()
	helper = ProjectSettings.globalize_path("user://updater-" + digest.left(16) + ext)
	# Content-addressed helpers never overwrite one that another launcher is using.
	if not FileAccess.file_exists(helper) or FileAccess.get_sha256(helper) != digest:
		var temporary := helper + "." + str(OS.get_process_id()) + ".tmp"
		var file := FileAccess.open(temporary, FileAccess.WRITE)
		if file == null:
			status.text = "Não foi possível preparar o atualizador."
			return
		file.store_buffer(bytes)
		file.close()
		if DirAccess.rename_absolute(temporary, helper) != OK:
			status.text = "Não foi possível preparar o atualizador. Reabra o launcher."
			return
	if ext == "":
		OS.execute("chmod", ["+x", helper])
	install_root = OS.get_executable_path().get_base_dir().path_join("jogo")
	if OS.has_feature("editor"):
		install_root = ProjectSettings.globalize_path("user://preview-install")
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--install-root="):
			install_root = arg.trim_prefix("--install-root=")
	_start("status")

func _style(color: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = color
	s.set_corner_radius_all(14)
	s.content_margin_left = 18
	s.content_margin_right = 18
	s.content_margin_top = 12
	s.content_margin_bottom = 12
	return s

func _button(text: String, color: Color, callback: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size.y = 52
	b.add_theme_stylebox_override("normal", _style(color))
	b.add_theme_stylebox_override("hover", _style(color.lightened(0.12)))
	b.add_theme_stylebox_override("pressed", _style(color.darkened(0.12)))
	b.add_theme_stylebox_override("disabled", _style(Color("344c40")))
	b.add_theme_color_override("font_color", Color("142b20"))
	b.add_theme_color_override("font_hover_color", Color("142b20"))
	b.add_theme_color_override("font_disabled_color", Color("a7b6a2"))
	b.add_theme_font_size_override("font_size", 19)
	b.pressed.connect(callback)
	return b

func _build_ui() -> void:
	var photo := TextureRect.new()
	photo.texture = load("res://farm.jpg")
	photo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	photo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	photo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	photo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(photo)
	var shade := ColorRect.new()
	shade.color = Color(0.035, 0.09, 0.055, 0.80)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 32)
	add_child(margin)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 12)
	margin.add_child(col)
	var small := Label.new()
	small.text = "BEM-VINDO DE VOLTA AO CAMPO"
	small.add_theme_color_override("font_color", GOLD)
	col.add_child(small)
	var title := Label.new()
	title.text = "DO MATO AO MILHÃO"
	title.add_theme_font_size_override("font_size", 38)
	title.add_theme_color_override("font_color", CREAM)
	col.add_child(title)
	versions = Label.new()
	versions.text = "Preparando sua próxima visita..."
	col.add_child(versions)
	var row := HBoxContainer.new()
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 24)
	col.add_child(row)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _style(Color(0.08, 0.16, 0.11, 0.92)))
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(panel)
	var info := VBoxContainer.new()
	info.add_theme_constant_override("separation", 12)
	panel.add_child(info)
	var heading := Label.new()
	heading.text = "NOVIDADES DA FAZENDA"
	heading.add_theme_color_override("font_color", GOLD)
	info.add_child(heading)
	notes = RichTextLabel.new()
	notes.size_flags_vertical = Control.SIZE_EXPAND_FILL
	notes.add_theme_font_size_override("normal_font_size", 16)
	notes.text = "Baixe uma vez. Nas próximas visitas, atualize por aqui.\n\nSeu progresso fica guardado separadamente.\n\nPara jogar com amigos, usem a mesma versão."
	info.add_child(notes)
	var actions := VBoxContainer.new()
	actions.custom_minimum_size.x = 290
	actions.add_theme_constant_override("separation", 12)
	row.add_child(actions)
	play_button = _button("JOGAR", GOLD, func(): _start("play"))
	actions.add_child(play_button)
	update_button = _button("ATUALIZAR E JOGAR", CREAM, func(): play_after_update = true; _start("update"))
	actions.add_child(update_button)
	check_button = _button("Verificar novidades", Color("a9c09b"), func(): _start("check"))
	actions.add_child(check_button)
	back_button = _button("Voltar à versão anterior", Color("a9c09b"), _confirm_rollback)
	actions.add_child(back_button)
	var hint := Label.new()
	hint.text = "Jogar funciona sem internet.\nAtualizações precisam de conexão.\n\nLauncher 1.0 · Windows / Linux"
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_color_override("font_color", Color("c4d1bb"))
	actions.add_child(hint)
	progress = ProgressBar.new()
	progress.custom_minimum_size.y = 6
	progress.show_percentage = false
	progress.indeterminate = true
	col.add_child(progress)
	status = Label.new()
	status.custom_minimum_size.y = 50
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status.add_theme_color_override("font_color", CREAM)
	col.add_child(status)
	_refresh()

func _confirm_rollback() -> void:
	var dialog := ConfirmationDialog.new()
	dialog.title = "Voltar à versão anterior?"
	dialog.dialog_text = "O jogo voltará para " + previous + ".\nOs saves não serão alterados pelo launcher.\nUm save mais novo pode não funcionar em uma versão antiga."
	dialog.confirmed.connect(func(): _start("rollback"))
	dialog.canceled.connect(dialog.queue_free)
	dialog.confirmed.connect(dialog.queue_free)
	add_child(dialog)
	dialog.popup_centered()

func _refresh() -> void:
	if play_button == null:
		return
	play_button.disabled = busy or current.is_empty()
	update_button.disabled = busy
	check_button.disabled = busy
	back_button.disabled = busy or previous.is_empty()
	progress.visible = busy
	versions.text = "Instalada: " + (current if current != "" else "nenhuma") + "     •     Disponível: " + (latest if latest != "" else "verificando")
	update_button.text = "INSTALAR E JOGAR" if current.is_empty() else "ATUALIZAR E JOGAR"

func _start(action: String) -> void:
	if busy or helper.is_empty():
		return
	busy = true
	operation = action
	playing = action == "play"
	status.text = {"status": "Verificando instalação...", "check": "Buscando novidades no GitHub...", "update": "Baixando e verificando a versão mais recente. Aguarde...", "play": "Jogo aberto. Boa colheita! Feche o jogo para voltar ao launcher.", "rollback": "Selecionando a versão anterior..."}.get(action, "Aguarde...")
	_refresh()
	worker = Thread.new()
	worker.start(_execute.bind(action))

func _execute(action: String) -> Dictionary:
	var output: Array = []
	var code := OS.execute(helper, [action, install_root], output, true, false)
	var parsed: Variant = JSON.parse_string("\n".join(output))
	if parsed is Dictionary:
		return parsed
	return {"OK": false, "Message": "Não foi possível executar o atualizador (" + str(code) + "). Verifique a permissão de escrita desta pasta."}

func _process(_delta: float) -> void:
	if worker == null or worker.is_alive():
		return
	result = worker.wait_to_finish()
	worker = null
	busy = false
	playing = false
	if result.get("OK", false):
		current = result.get("Current", current)
		previous = result.get("Previous", previous)
		if result.get("Latest", "") != "":
			latest = result.Latest
		if result.get("Notes", "") != "":
			notes.text = _plain_notes(result.Notes)
		status.text = result.get("Message", "")
		if operation == "status":
			_start("check")
			return
		if operation == "update" and play_after_update:
			play_after_update = false
			_start("play")
			return
		if operation == "check":
			status.text = "Tudo pronto para jogar." if current == latest else "Tem novidade! Use Atualizar e jogar."
	else:
		play_after_update = false
		status.text = result.get("Message", "Ocorreu um erro. Tente novamente.")
	_refresh()

func _plain_notes(text: String) -> String:
	var lines := PackedStringArray()
	for line in text.split("\n"):
		while line.begins_with("#"):
			line = line.trim_prefix("#")
		lines.append(line.strip_edges().replace("**", ""))
	return "\n".join(lines)

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		if busy:
			status.text = "Feche o jogo antes de sair do launcher." if playing else "Aguarde a operação terminar antes de fechar."
		else:
			get_tree().quit()
