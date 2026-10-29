extends Button
## A prestige reward card: path art, the card name, its headline value and one line of meaning.
## Composition lives in prestige_card.tscn; this script only fills data and shows state.
const ITEM_ART="res://assets/PixelPlains/Items/All v3 (Separated Files, Black Outline)/Item-%d.png"
@export var compact:=false
var card_id:=""
var tint:=Color.WHITE

func setup(id: String,definition: Dictionary,path_info: Dictionary,state: String) -> void:
    card_id=id
    tint=Color(str(path_info.get("color","8899aa")))
    $Content/Art.texture=UiArt.cropped(load(ITEM_ART % int(path_info.get("icon",211))))
    $Content/Name.text=definition.name
    $Content/Value.text=headline(definition)
    $Content/Value.add_theme_color_override("font_color",tint.lightened(.45))
    $Content/Detail.text=definition.description
    $Content/Detail.visible=not compact
    $Content/State.text=tr({"owned":"CARD_OWNED","selected":"CARD_SELECTED","locked":"CARD_LOCKED","offered":""}.get(state,""))
    var style: StyleBoxTexture=get_theme_stylebox("normal","PrestigeCard").duplicate()
    style.modulate_color=tint.darkened(.35) if state!="locked" else Color(.22,.24,.28)
    var hover: StyleBoxTexture=style.duplicate();hover.modulate_color=style.modulate_color.lightened(.12)
    for name_ in ["normal","pressed","focus","disabled"]:add_theme_stylebox_override(name_,style)
    add_theme_stylebox_override("hover",hover)
    $Selected.visible=state=="selected"
    $Content/Art.modulate=Color(1,1,1,.35) if state=="locked" else Color.WHITE

## Large decision value derived from the effect, never authored twice.
static func headline(definition: Dictionary) -> String:
    var value: float=float(definition.value)
    match str(definition.effect):
        "crit","gear_chance","supply_chance","gem_chance":return TranslationServer.translate("CARD_VALUE_POINTS") % roundi(value*100)
        "boss_guard","guard","coin_discount","reroll_discount","camp_discount":return "−%d%%" % roundi(value*100)
        "respawn":return TranslationServer.translate("CARD_VALUE_SECONDS") % str(snappedf(value,.1)).trim_suffix(".0")
    return "+%d%%" % roundi(value*100)
