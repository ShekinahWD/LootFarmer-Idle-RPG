extends Resource
## Change 41 (Playbook 52): the community links the game opens, each defined once, here and in its
## resource (resources/game/external_links.tres), never in a button. Store pages stay with their
## storefront in distribution_channels.gd (52.1). Used through preload (no class_name), like that file.
## The game opens a link with OS.shell_open, which hands an https URL to the system: the default
## browser on Windows, an ACTION_VIEW intent on Android (the Discord app when it is installed and
## claims discord.gg links, else the browser). Nothing is embedded and no account is touched.

## The approved invite for Settings → Discord.
@export var discord_url:="https://discord.gg/zbr9RH6QWa"
## A second press within this many real seconds opens nothing (a double tap, a press that slides).
@export var repeat_guard_seconds:=1.5

## Opens a URL and returns an Error. Probes replace it to test routing and failure without leaving
## the game. The resource is shared through preload, so the replacement reaches every caller.
var opener: Callable=func(url: String)->int:return OS.shell_open(url)
## The last URL handed to the opener (probes and the change report read it).
var last_url:=""
var _last_open_msec:=-1000000

## Opens the link once; false when it failed or was a repeat inside the guard (the caller then shows
## a short message for a failure only: failure_was_repeat tells which).
var failure_was_repeat:=false
func open(url: String) -> bool:
    failure_was_repeat=false
    if not url.begins_with("https://"):return false
    var now:=Time.get_ticks_msec()
    if now-_last_open_msec<int(repeat_guard_seconds*1000.0):
        failure_was_repeat=true
        return false
    _last_open_msec=now
    last_url=url
    return int(opener.call(url))==OK

## Probes only: forget the repeat guard between scripted presses.
func reset_guard() -> void:_last_open_msec=-1000000
