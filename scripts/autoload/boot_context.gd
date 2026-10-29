extends Node
## Resolve save namespace before any service reads a file.

var profile_name: String = "production"
var autosave_enabled: bool = true
var is_probe: bool = false
## Change 15 (Playbook 18.10): probes of ordinary play start fresh profiles with the first-profile
## progression complete (every menu revealed, the early equipment guarantee spent). Only accepted
## together with a probe or capture profile; the onboarding probes run without it.
var first_run_complete: bool = false
## Change 35: a storefront named for a probe or capture (--store-channel=google_play|itch_io|none).
## Accepted only together with a test profile, so a release build always reads its export tag.
var store_channel_override: String = ""
## Localization Batch 01: a translation batch unlocked for a probe or capture (--test-languages=batch01).
## Accepted only together with a test profile; normal players keep the English-only gate (Playbook 132.5).
var test_languages: String = ""


func _init() -> void:
    for argument in OS.get_cmdline_args():
        if "tests/" in argument or "tests\\" in argument:
            is_probe = true
            profile_name = "probe-bootstrap"
    for argument in OS.get_cmdline_user_args():
        if argument == "--probe":
            is_probe = true
            profile_name = "probe-bootstrap"
        elif argument == "--no-autosave":
            autosave_enabled = false
        elif argument == "--first-run-complete":
            first_run_complete = true
        elif argument.begins_with("--store-channel="):
            store_channel_override = argument.trim_prefix("--store-channel=")
        elif argument.begins_with("--test-languages="):
            test_languages = argument.trim_prefix("--test-languages=")
        elif argument.begins_with("--profile="):
            var requested := argument.trim_prefix("--profile=")
            if _valid_test_profile(requested):
                profile_name = requested
                is_probe = true
            else:
                push_error("Rejected unsafe profile name; using isolated fallback.")
                profile_name = "probe-invalid"
                is_probe = true
    if not is_probe:
        first_run_complete = false
        store_channel_override = ""
        test_languages = ""


func _valid_test_profile(value: String) -> bool:
    if not (value.begins_with("probe-") or value.begins_with("capture-")):
        return false
    for character in value:
        if not character in "abcdefghijklmnopqrstuvwxyz0123456789-_":
            return false
    return value.length() <= 64


func save_directory() -> String:
    return "user://profiles/" + profile_name
