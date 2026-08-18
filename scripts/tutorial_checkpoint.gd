extends RefCounted
## Automatic, invisible checkpoint/rollback for Challenge runs -- never
## the player's own save. See TUTORIAL_PLAN.md's "Checkpoint / rollback
## infrastructure" and DESIGN_BACKLOG.md §5 for why this exists: a
## Challenge needs a soft-recoverable snapshot at every sub-stage
## boundary, and nothing in saving.gd/save_game.gd covered that before
## this file -- the one save slot they manage is player-initiated and
## overwritten, not an autosave/rollback.
##
## Deliberately thin: this reuses save_game.gd's existing serialise
## (`SaveGame.save`) and deserialise (`Saving._restore`) routines rather
## than inventing a second way to capture state, just pointed at
## `CHECKPOINT_PATH` instead of the player's save file.
##
## One rolling checkpoint, not a history -- each call to `save()`
## overwrites whatever was checkpointed before. "Restore" always means
## "back to the start of the current sub-stage", never further than
## that. Callers are responsible for the timing (checkpoint once a
## sub-stage's completion condition is met, restore on that sub-stage's
## own soft-failure condition) -- this file only knows how to write and
## replay a snapshot, not when.
##
## Scope: only meaningful during a Challenge run. Starter modes and any
## future open-world mode never call into this file.

const CHECKPOINT_PATH := "user://tutorial_checkpoint.save"

static func has_checkpoint() -> bool:
	return FileAccess.file_exists(CHECKPOINT_PATH)

## `world` is main.gd's own node (the same thing saving.gd's methods call
## `main`), so this can reach `world.SaveGame` the same way saving.gd does.
static func save(world) -> bool:
	return world.SaveGame.save(world, CHECKPOINT_PATH)

## Deserialises straight back over the live game state -- the same
## mechanism an ordinary load already uses (`Saving._restore`), just
## silent and automatic rather than player-initiated. Does nothing and
## returns false if no checkpoint has been saved yet.
static func restore(world) -> bool:
	if not has_checkpoint():
		return false
	var data: Dictionary = world.SaveGame.read(CHECKPOINT_PATH)
	if data.is_empty():
		return false
	world.saving._restore(data)
	return true

## Called when a Challenge run ends (completed or abandoned back to the
## main menu), so a stale checkpoint from a finished run can never be
## mistaken for a live one.
static func clear() -> void:
	if has_checkpoint():
		DirAccess.remove_absolute(CHECKPOINT_PATH)
