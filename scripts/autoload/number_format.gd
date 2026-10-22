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


## Coins and Gems (Change 13), the one presentation for every currency balance, price and reward:
## below 100 up to two decimals (coins are fractional values), 100 to 999 whole amounts, and from
## 1,000 the shared suffixes with up to two decimals, trailing zeros dropped (1K, 1.5K, 12.34K, 1M).
## Rounding is directional so the screen never claims more than is true: balances and rewards round
## down (round_up=false), prices and amounts still needed round up. A shown balance that is at least
## a shown price therefore always pays for it. Purchases always compare the exact numbers.
func currency(value: float, round_up := false) -> String:
    if is_nan(value) or is_inf(value):
        return "—"
    var sign_text := "-" if value < 0.0 else ""
    var magnitude := absf(value)
    if magnitude < 1000.0:
        var decimals := 0 if magnitude >= 100.0 else 2
        var shown := _directional(magnitude, decimals, round_up)
        if shown < 1000.0:
            return sign_text + _trimmed(shown, decimals)
        magnitude = 1000.0
    for i in range(SUFFIXES.size()):
        var entry: Array = SUFFIXES[i]
        if magnitude >= entry[0]:
            var shown := _directional(magnitude / float(entry[0]), 2, round_up)
            # 999.999K rounded up is 1M, not "1000K".
            if shown >= 1000.0 and i > 0:
                return sign_text + "1" + String(SUFFIXES[i - 1][1])
            return sign_text + _trimmed(shown, 2) + String(entry[1])
    return sign_text + _trimmed(magnitude, 2)


## Rounds to `decimals` toward +inf (round_up) or toward 0, ignoring float noise below 1e-6.
func _directional(value: float, decimals: int, round_up: bool) -> float:
    var scale := pow(10.0, decimals)
    return (ceilf(value * scale - 1e-6) if round_up else floorf(value * scale + 1e-6)) / scale


func _trimmed(value: float, decimals: int) -> String:
    var text := _fmt_float(value, decimals)
    if decimals > 0:
        text = text.rstrip("0").trim_suffix(".")
    return text


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
