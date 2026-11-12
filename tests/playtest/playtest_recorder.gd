extends RefCounted
## Player-profile playtesting, reusable part: the evidence recorder.
## Game-agnostic. Writes two JSON-lines files:
##   events.jsonl  decisions, action results and milestones; every field is deterministic for a seed
##                 (active seconds, virtual calendar time, game values) and never holds wall time or paths.
##   trace.jsonl   periodic diagnosis samples (only with --trace), plus the last samples before an
##                 abnormal stop, kept in a small ring so a stall can always be inspected.
## Volume is bounded: repeated identical failures are collapsed (see failure()).

const RING:=60
var events_path:=""
var trace_path:=""
var trace_enabled:=false
var active:=0.0          # simulated active seconds, set by the driver before each step
var virtual_unix:=0.0    # virtual calendar time, set by the driver
var count:=0
var _events: PackedStringArray=[]
var _trace: PackedStringArray=[]
var _ring: Array=[]
var _failures: Dictionary={}
var _hash:=HashingContext.new()

func open(directory: String,with_trace: bool) -> bool:
    DirAccess.make_dir_recursive_absolute(directory)
    events_path=directory.path_join("events.jsonl")
    trace_path=directory.path_join("trace.jsonl")
    trace_enabled=with_trace
    _hash.start(HashingContext.HASH_SHA256)
    for path in [events_path,trace_path]:
        var f:=FileAccess.open(path,FileAccess.WRITE)
        if f==null:return false
        f.close()
    return true

func stamp() -> String:
    return Time.get_datetime_string_from_unix_time(int(virtual_unix),false)+"Z"

## One event line. `data` must hold only deterministic values.
func event(kind: String,data: Dictionary={}) -> void:
    var row: Dictionary={"n":count,"t":snappedf(active,.1),"vt":stamp(),"type":kind}
    for key in data:row[key]=data[key]
    count+=1
    var line:=JSON.stringify(row)
    _events.append(line)
    _hash.update((line+"\n").to_utf8_buffer())
    if _events.size()>=200:flush()

## A rejected action. The first rejection of (action, reason, subject) is logged at once; repeats are
## counted and reported at most once per `every` active seconds, with how many were collapsed.
func failure(action: String,reason: String,subject: String,data: Dictionary={},every: float=120.0) -> void:
    var key:=action+"|"+reason+"|"+subject
    var entry: Dictionary=_failures.get(key,{"at":-1e9,"held":0})
    if active-float(entry.at)<every:
        entry.held=int(entry.held)+1
        _failures[key]=entry
        return
    var row: Dictionary={"action":action,"reason":reason,"subject":subject,"repeats_collapsed":int(entry.held)}
    for k in data:row[k]=data[k]
    event("action_rejected",row)
    _failures[key]={"at":active,"held":0}

func trace(data: Dictionary) -> void:
    var row: Dictionary={"t":snappedf(active,.1),"vt":stamp()}
    for key in data:row[key]=data[key]
    var line:=JSON.stringify(row)
    _ring.append(line)
    if _ring.size()>RING:_ring.pop_front()
    if trace_enabled:
        _trace.append(line)
        if _trace.size()>=100:flush()

## Abnormal stop: make sure the last samples are on disk even when --trace was off.
func dump_ring() -> void:
    if trace_enabled:return
    for line in _ring:_trace.append(line)
    flush()

func flush() -> void:
    _append(events_path,_events);_events=PackedStringArray()
    _append(trace_path,_trace);_trace=PackedStringArray()

func _append(path: String,lines: PackedStringArray) -> void:
    if lines.is_empty():return
    var f:=FileAccess.open(path,FileAccess.READ_WRITE)
    if f==null:return
    f.seek_end()
    for line in lines:f.store_string(line+"\n")
    f.close()

## SHA-256 of every event line written so far (the normalized event log's digest).
func digest() -> String:
    flush()
    var copy:=_hash.finish().hex_encode()
    return copy
