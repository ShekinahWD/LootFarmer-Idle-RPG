extends ScrollContainer
## Keep taps, but let drags starting on dynamically added cards reach the scroller.
func _ready() -> void:
    get_tree().node_added.connect(_added)
    _prepare(self)
    var bar:=get_v_scroll_bar()
    var track: StyleBoxTexture=bar.get_theme_stylebox("scroll").duplicate()
    track.modulate_color=Color(.12,.19,.24,1)
    track.content_margin_left=7;track.content_margin_right=7
    var thumb: StyleBoxTexture=track.duplicate() # solid crop of the existing panel asset
    thumb.modulate_color=Color(.72,.82,.82,1)
    thumb.content_margin_left=7;thumb.content_margin_right=7
    thumb.content_margin_top=18;thumb.content_margin_bottom=18
    bar.add_theme_stylebox_override("scroll",track)
    for key in ["grabber","grabber_highlight","grabber_pressed"]:bar.add_theme_stylebox_override(key,thumb)
    vertical_scroll_mode=ScrollContainer.SCROLL_MODE_AUTO

func _added(node: Node) -> void:
    if is_ancestor_of(node):
        _prepare(node)

func _prepare(node: Node) -> void:
    if node!=self and (node is ScrollContainer or node is Slider or node is ScrollBar or node is SpinBox or node is LineEdit or node is TextEdit):
        return
    if node!=self and node is Control and node.mouse_filter==Control.MOUSE_FILTER_STOP:
        node.mouse_filter=Control.MOUSE_FILTER_PASS
    for child in node.get_children():
        _prepare(child)
