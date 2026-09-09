extends RefCounted
## Named feedback definitions (CHATGPT_EFFICIENCY_IMPLEMENTATION_PLAN.md
## Slice 4): challenge_runner.gd names one of these ids when a fact happens
## (a stage clears, the colony needs a warning); the relevant view renders
## it without the caller building the panel's own dictionary shape inline.
##
## `kind` says which view owns the rendering:
## - "goal_shelf": hud.gd's goal shelf (set_challenge_goal). The stage that
##   just cleared already supplies its own completed-line text via its
##   `goal_text` in challenge_stages.gd, so this def is a documentation
##   marker for that path rather than a template -- there is exactly one
##   "stage cleared" definition because every stage clear renders the same
##   way.
## - "gallerin": a one-off Dr Gallerin prompt via gallerin_panel.show_now().
class_name ChallengeFeedback

const DEFS := {
	"stage_cleared": {
		"kind": "goal_shelf",
	},
	"challenge_2_rescue": {
		"kind": "gallerin",
		"trigger": "recovery",
		"repeatable": false,
		"text": "Ahem. Field ecologists do not usually carry emergency nectar, but I shall make one exception. Try to keep a forager pipeline going from here.",
	},
	"challenge_2_recovery": {
		"kind": "gallerin",
		"trigger": "recovery",
		"repeatable": false,
		"text": "A brief ecological wobble. Let's return to the last stable moment.\n\nThe colony has run out of usable energy. Let's return to the last stable point and rebuild the foraging pipeline.",
	},
	"challenge_1_pollen_cell_nectar": {
		"kind": "gallerin",
		"trigger": "warning",
		"repeatable": false,
		"text": "That cell was reserved for pollen, and nectar has found its way in regardless. Empty it, or build another cell for the nectar to go in.",
	},
}

## Builds the Dictionary gallerin_panel.show_now() expects from a "gallerin"
## definition. `id_suffix` distinguishes repeat instances of the same
## definition (challenge_2_recovery fires once per stage index) the way the
## inline dictionary this replaced used to with string formatting.
static func gallerin_prompt(def_id: String, id_suffix: String = "") -> Dictionary:
	var def: Dictionary = DEFS[def_id]
	return {
		"id": def_id + id_suffix,
		"trigger": def.trigger,
		"repeatable": def.repeatable,
		"text": def.text,
	}
