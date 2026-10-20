extends ScrollContainer
## Keep taps, but let drags starting on dynamically added cards reach the scroller.
func _ready() -> void:
    get_tree().node_added.connect(_added)
    _prepare(self)

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
