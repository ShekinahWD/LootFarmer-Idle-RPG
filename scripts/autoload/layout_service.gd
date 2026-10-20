extends Node
## Shared reference-layout and safe-area helper for Android-first 2D projects.
## Keep gameplay/UI authored in one reference coordinate system, then let
## canvas_items + expand expose extra space on wider/taller devices.

const REFERENCE_SIZE := Vector2(720.0, 1280.0)


func get_viewport_size() -> Vector2:
    var viewport := get_viewport()
    if viewport == null:
        return REFERENCE_SIZE
    return viewport.get_visible_rect().size


func get_center() -> Vector2:
    return get_viewport_size() * 0.5


func get_reference_center_offset() -> Vector2:
    return get_center() - (REFERENCE_SIZE * 0.5)


## Returns canvas-space safe insets as Vector4(left, top, right, bottom).
## Godot reports DisplayServer safe area in physical screen pixels, while
## Control offsets live in the stretched viewport coordinate system.
func get_safe_area_insets_canvas(extra_android_padding: float = 0.0) -> Vector4:
    var result := Vector4.ZERO
    if OS.get_name() != "Android":
        return result

    var safe_area: Rect2i = DisplayServer.get_display_safe_area()
    var screen_size: Vector2i = DisplayServer.screen_get_size(DisplayServer.SCREEN_OF_MAIN_WINDOW)
    var viewport_size: Vector2 = get_viewport_size()
    if screen_size.x <= 0 or screen_size.y <= 0 or viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
        return result
    if safe_area.size.x <= 0 or safe_area.size.y <= 0:
        return Vector4(extra_android_padding, extra_android_padding, extra_android_padding, extra_android_padding)

    var safe_right_px := maxi(0, screen_size.x - (safe_area.position.x + safe_area.size.x))
    var safe_bottom_px := maxi(0, screen_size.y - (safe_area.position.y + safe_area.size.y))
    var x_scale := viewport_size.x / float(screen_size.x)
    var y_scale := viewport_size.y / float(screen_size.y)

    result.x = float(maxi(0, safe_area.position.x)) * x_scale + extra_android_padding
    result.y = float(maxi(0, safe_area.position.y)) * y_scale + extra_android_padding
    result.z = float(safe_right_px) * x_scale + extra_android_padding
    result.w = float(safe_bottom_px) * y_scale + extra_android_padding
    return result
