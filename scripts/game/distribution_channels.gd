extends Resource
## Change 35: which storefront this build was distributed through, and where its review action goes.
## The storefront is a property of the release artifact, never of the device: an Android APK can come
## from Google Play or itch.io, and a desktop build from itch.io. Each release export preset declares
## exactly one store feature tag in its custom_features (export_presets.cfg); the running game reads it
## with OS.has_feature. No tag (editor runs, test or sideloaded builds), an unknown tag, two tags or an
## entry without an https URL resolves to "" and the game offers no review action at all.
## Adding a storefront: one entry here (feature tag, CTA key, exact URL), its CTA string in
## localization/en.po and an export preset carrying the tag. The review invitation never changes.
## Used through preload (no class_name), like stage_scenes.gd. Values: resources/game/distribution_channels.tres.

## channel id -> {"feature": export feature tag, "cta": localization key of the review button,
## "url": the exact store page}.
@export var channels: Dictionary={}

## The configured channel id, or "" when the build declares none (or an ambiguous/invalid one).
## Probes and captures may name a channel with --store-channel=<id> (BootContext accepts it only in
## test profiles), so a production build can never be switched by a command line.
func current() -> String:
    if BootContext.store_channel_override!="":
        return BootContext.store_channel_override if valid(BootContext.store_channel_override) else ""
    return resolve(func(tag: String)->bool:return OS.has_feature(tag))

## The single channel whose feature tag `has_tag` reports, or "" for none or more than one.
func resolve(has_tag: Callable) -> String:
    var found: Array=[]
    for id in channels:
        if valid(id) and has_tag.call(str(channels[id].feature)):found.append(id)
    return found[0] if found.size()==1 else ""

## The channel ids an export preset's comma-separated custom_features select (export checks).
func channel_for_features(custom_features: String) -> String:
    var tags: PackedStringArray=custom_features.replace(" ","").split(",",false)
    return resolve(func(tag: String)->bool:return tags.has(tag))

func valid(id: String) -> bool:
    if not channels.has(id) or not channels[id] is Dictionary:return false
    var entry: Dictionary=channels[id]
    return str(entry.get("feature",""))!="" and str(entry.get("cta",""))!="" and str(entry.get("url","")).begins_with("https://")

func url(id: String) -> String:return str(channels[id].url) if valid(id) else ""
func cta(id: String) -> String:return str(channels[id].cta) if valid(id) else ""
