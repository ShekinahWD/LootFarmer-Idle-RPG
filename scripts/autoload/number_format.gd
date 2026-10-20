extends Node
## Centralized player-facing numeric formatting. Keep formatting out of gameplay math.

const SUFFIXES: Array[Array] = [
    [1e63, "V"], [1e60, "Nd"], [1e57, "Od"], [1e54, "Sd"], [1e51, "sd"],
    [1e48, "Qd"], [1e45, "Qu"], [1e42, "Tr"], [1e39, "Du"], [1e36, "Un"],
    [1e33, "De"], [1e30, "No"], [1e27, "Oc"], [1e24, "Sp"], [1e21, "Sx"],
    [1e18, "Qi"], [1e15, "Qa"], [1e12, "T"], [1e9, "B"], [1e6, "M"], [1e3, "K"],
]


func _fmt_float(value: float, decimals: int) -> String:
    var fmt := "%." + str(decimals) + "f"
    return fmt % value


func number(value: float, decimals: int = 2) -> String:
    if is_nan(value) or is_inf(value):
        return "—"
    var sign_text := "-" if value < 0.0 else ""
    var magnitude := absf(value)
    if magnitude >= 1e66:
        var efmt := "%." + str(decimals) + "e"
        return sign_text + (efmt % magnitude)
    for entry in SUFFIXES:
        if magnitude >= entry[0]:
            return sign_text + _fmt_float(magnitude / float(entry[0]), decimals) + String(entry[1])
    return sign_text + _fmt_float(magnitude, decimals)


func count(value: float) -> String:
    return number(value, 0)


func percent(value_0_to_1: float, decimals: int = 2) -> String:
    if is_nan(value_0_to_1) or is_inf(value_0_to_1):
        return "—%"
    return _fmt_float(value_0_to_1 * 100.0, decimals) + "%"


func pair(current: float, max_value: float, decimals: int = 2) -> String:
    return "%s / %s" % [number(current, decimals), number(max_value, decimals)]


func signed_number(value: float, decimals: int = 2) -> String:
    var body := number(absf(value), decimals)
    return ("+" + body) if value >= 0.0 else ("-" + body)
