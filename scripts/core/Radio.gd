class_name Radio
extends RefCounted
## Radio.gd
##
## Pure gameplay logic for the radio console.
## No UI, no rendering, no scene dependencies — just the rules.
##
## A "signal" is characterized by two numbers:
##   freq: 0-100 (how far up the frequency band)
##   amp:  0-100 (how loud the signal is)
##
## A "target" is a specific (freq, amp) pair plus a tolerance window.
## The player wins a lock when their dials are within `tolerance` on
## BOTH axes.

## Result of a lock attempt.
enum LockResult {
	NO_TARGET,  ## No target has been set yet.
	MISS,       ## Dials are outside tolerance.
	HIT,        ## Dials are within tolerance.
}


## Represents one puzzle the player must solve.
class Target:
	var freq: float
	var amp: float
	var tolerance: float

	func _init(f: float, a: float, t: float) -> void:
		freq = f
		amp = a
		tolerance = t

	## Returns true if the given dial values fall inside this target's window.
	func matches(f: float, a: float) -> bool:
		return abs(f - freq) <= tolerance and abs(a - amp) <= tolerance


## The currently-active target, or null if none set.
var target: Target = null

## Cached dial values. Caller updates these as the player drags.
var freq: float = 50.0
var amp: float = 50.0


## Set the current puzzle.
func set_target(f: float, a: float, tolerance: float) -> void:
	target = Target.new(f, a, tolerance)


## Clear the current puzzle.
func clear_target() -> void:
	target = null


## Attempt a lock with the current dial values.
func try_lock() -> LockResult:
	if target == null:
		return LockResult.NO_TARGET
	if target.matches(freq, amp):
		return LockResult.HIT
	return LockResult.MISS
