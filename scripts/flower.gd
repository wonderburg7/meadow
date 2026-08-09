extends Polygon2D
## Flower -- v1 prototype, slice 7.
## Holds a limited amount of nectar and pollen that drains as bees
## collect and recharges over time. Only one bee may visit a given
## flower at a time (see `occupied_by`).
##
## Two species now, so "which flower" is a real decision:
##   Clover -- nectar-rich, pollen-poor, yellow
##   Borage -- pollen-rich, nectar-poor, blue-violet

const Shapes = preload("res://scripts/shapes.gd")

const SPECIES := [
	{
		"name": "Clover",
		"nectar_capacity": 20.0,
		"pollen_capacity": 10.0,
		"color": Color(0.95, 0.85, 0.1),
		"centre": Color(0.5, 0.35, 0.05),
	},
	{
		"name": "Borage",
		"nectar_capacity": 8.0,
		"pollen_capacity": 22.0,
		"color": Color(0.45, 0.4, 0.85),
		"centre": Color(0.15, 0.1, 0.4),
	},
]

var species_name: String = "Clover"
var nectar_capacity: float = 20.0
var pollen_capacity: float = 10.0
var nectar_recharge_rate: float = 0.5
var pollen_recharge_rate: float = 0.1

var nectar_amount: float
var pollen_amount: float
var occupied_by: Node2D = null   # the bee currently visiting this flower, if any

var nectar_label: Label
var pollen_label: Label

func _ready() -> void:
	add_to_group("flowers")

func setup(species_index: int) -> void:
	var s: Dictionary = SPECIES[species_index % SPECIES.size()]
	species_name = s.name
	nectar_capacity = s.nectar_capacity
	pollen_capacity = s.pollen_capacity
	nectar_recharge_rate = GameConfig.nectar_recharge_rate
	pollen_recharge_rate = GameConfig.pollen_recharge_rate
	nectar_amount = nectar_capacity
	pollen_amount = pollen_capacity

	polygon = Shapes.square_points(Vector2(28, 28))
	color = s.color

	var centre_dot := Polygon2D.new()
	centre_dot.polygon = Shapes.circle_points(5.0)
	centre_dot.color = s.centre
	add_child(centre_dot)

	# nectar amount reads bottom-left, pollen amount reads bottom-right
	nectar_label = Label.new()
	nectar_label.position = Vector2(-16, 11)
	nectar_label.add_theme_font_size_override("font_size", 10)
	add_child(nectar_label)

	pollen_label = Label.new()
	pollen_label.position = Vector2(4, 11)
	pollen_label.add_theme_font_size_override("font_size", 10)
	add_child(pollen_label)

	_update_labels()

func _process(delta: float) -> void:
	nectar_amount = min(nectar_capacity, nectar_amount + nectar_recharge_rate * delta)
	pollen_amount = min(pollen_capacity, pollen_amount + pollen_recharge_rate * delta)
	_update_fade()
	_update_labels()

func get_available(resource_type: String) -> float:
	return nectar_amount if resource_type == "nectar" else pollen_amount

func get_capacity(resource_type: String) -> float:
	return nectar_capacity if resource_type == "nectar" else pollen_capacity

func get_recharge_rate(resource_type: String) -> float:
	return nectar_recharge_rate if resource_type == "nectar" else pollen_recharge_rate

## How long, in seconds, until this flower is back to full for the
## given resource. Bees use this to decide how long to stay away.
func seconds_until_full(resource_type: String) -> float:
	var missing: float = get_capacity(resource_type) - get_available(resource_type)
	var rate: float = get_recharge_rate(resource_type)
	if rate <= 0.0:
		return 0.0
	return max(0.0, missing / rate)

## Removes up to `amount` of `resource_type` and returns how much was
## actually taken (may be less than requested if the flower runs low).
func collect(resource_type: String, amount: float) -> float:
	if resource_type == "nectar":
		var taken_n: float = min(amount, nectar_amount)
		nectar_amount -= taken_n
		return taken_n
	else:
		var taken_p: float = min(amount, pollen_amount)
		pollen_amount -= taken_p
		return taken_p

func release(bee: Node2D) -> void:
	if occupied_by == bee:
		occupied_by = null

## Fades the flower out as it empties so depletion is visible, and
## back in as it recharges. Purely a visual aid for playtesting.
##
## The fade is applied to the petal colour rather than `modulate`,
## because `modulate` cascades to child nodes and was dragging the
## amount labels down to 35% alpha exactly when you most want to read
## them (a nearly empty flower).
func _update_fade() -> void:
	var fullness: float = (nectar_amount + pollen_amount) / max(0.001, nectar_capacity + pollen_capacity)
	color.a = lerp(0.35, 1.0, fullness)

func _update_labels() -> void:
	nectar_label.text = str(int(round(nectar_amount)))
	pollen_label.text = str(int(round(pollen_amount)))
