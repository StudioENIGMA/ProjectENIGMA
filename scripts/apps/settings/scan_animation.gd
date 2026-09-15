class_name ScanAnimation
extends Control
## Drawn replacement for the pre-rendered scanner videos: a sweeping radar dish whose rim doubles
## as the progress bar, with the ENIGMA wordmark landing letter by letter underneath.

signal finished()

#region PALETTE
const TEAL := Color(0.22352941, 0.5647059, 0.62352943)
const MINT := Color(0.30980393, 0.79607844, 0.68235296)
const PALE_MINT := Color(0.6392157, 0.9254902, 0.7607843)
const CRIMSON := Color(0.92156863, 0.039215688, 0.27058825)
#endregion

#region TIMING
const DURATION := 4.2 ## Seconds the whole sweep takes, start to 100%.
const SWEEP_PERIOD := 1.4 ## Seconds the radar arm takes to go around once.
const SWEEP_TRAIL := 1.05 ## Radians of fading trail behind the arm.
#endregion

#region RADAR
const RING_COUNT := 4
const SPOKE_COUNT := 12
const TICK_COUNT := 24
const BLIP_COUNT := 13
const BLIP_FADE := 0.7 ## Seconds a blip takes to settle after the arm lights it up.
const RIM_START := -PI * 0.5 ## The rim gauge fills clockwise from the top.
#endregion

#region LAYOUT
const RIM_MARGIN := 10.0 ## Room the rim ticks need outside the dish.
const CAPTION_GAP := 36.0 ## Dish edge to caption baseline.
const WORDMARK_GAP := 64.0 ## Caption baseline to wordmark baseline.
#endregion

const WORDMARK := "ENIGMA"
const CAPTIONS: Array[String] = [
	"Lendo aplicativos instalados",
	"Analisando permissões",
	"Checando integridade do sistema",
	"Compilando relatório",
]

const BOLD_FONT := preload("res://assets/fonts/IBMPlexSans-Bold.ttf")
const SEMIBOLD_FONT := preload("res://assets/fonts/IBMPlexSans-SemiBold.ttf")

var _elapsed := 0.0
var _threat_count := 0
var _blips: Array[Dictionary] = []

func _ready() -> void:
	set_process(false)

## Restarts the animation. `threat_count` only tints it: a clean sweep stays mint, a dirty one
## turns the arm and the blips it finds crimson.
func start(threat_count: int) -> void:
	_threat_count = threat_count
	_elapsed = 0.0
	_build_blips()
	set_process(true)
	queue_redraw()

func _process(delta: float) -> void:
	var previous_sweep := _sweep_angle()
	_elapsed += delta
	_light_up_blips(previous_sweep, _sweep_angle())
	queue_redraw()
	if _elapsed >= DURATION:
		set_process(false)
		finished.emit()

func _draw() -> void:
	var progress := clampf(_elapsed / DURATION, 0.0, 1.0)
	var radar_radius := minf(size.x * 0.30, 104.0)

	# The dish, the caption and the wordmark are laid out as one block centred on the overlay.
	var block_height := 2.0 * radar_radius + RIM_MARGIN * 2.0 + CAPTION_GAP + WORDMARK_GAP
	var block_top := (size.y - block_height) * 0.5
	var radar_center := Vector2(size.x * 0.5, block_top + RIM_MARGIN + radar_radius)
	var caption_baseline := radar_center.y + radar_radius + RIM_MARGIN + CAPTION_GAP

	_draw_scanline()
	_draw_radar(radar_center, radar_radius, progress)
	_draw_caption(Vector2(size.x * 0.5, caption_baseline), progress)
	_draw_wordmark(caption_baseline + WORDMARK_GAP, progress)

#region DRAWING
## Soft mint band travelling down the screen, tying the two pieces together.
func _draw_scanline() -> void:
	var head := fposmod(_elapsed * 210.0, size.y + 240.0) - 120.0
	for i in 14:
		var alpha := 0.035 * (1.0 - float(i) / 14.0)
		draw_rect(Rect2(0.0, head - i * 5.0, size.x, 5.0), Color(MINT, alpha))

func _draw_radar(center: Vector2, radius: float, progress: float) -> void:
	draw_circle(center, radius, Color(TEAL, 0.12))
	for i in RING_COUNT:
		var ring_radius := radius * float(i + 1) / RING_COUNT
		draw_arc(center, ring_radius, 0.0, TAU, 64, Color(TEAL, 0.30), 1.0, true)
	for i in SPOKE_COUNT:
		var angle := TAU * i / SPOKE_COUNT
		draw_line(center, center + Vector2.from_angle(angle) * radius, Color(TEAL, 0.20), 1.0, true)

	_draw_sweep(center, radius)
	_draw_blips(center, radius)
	_draw_rim(center, radius, progress)

## The rim is the progress bar: it fills clockwise from the top and lights its ticks on the way.
func _draw_rim(center: Vector2, radius: float, progress: float) -> void:
	draw_arc(center, radius, 0.0, TAU, 96, Color(MINT, 0.20), 3.0, true)
	if progress > 0.0:
		draw_arc(
			center, radius, RIM_START, RIM_START + TAU * progress, 96, Color(MINT, 0.95), 3.5, true
		)

	for i in TICK_COUNT:
		var angle := TAU * i / TICK_COUNT
		var lit := fposmod(angle - RIM_START, TAU) <= TAU * progress
		var direction := Vector2.from_angle(angle)
		var length := 7.0 if i % 6 == 0 else 3.5
		draw_line(
			center + direction * radius,
			center + direction * (radius + length),
			Color(MINT, 0.65 if lit else 0.22), 1.0, true
		)

	if progress > 0.0 and progress < 1.0:
		var head := center + Vector2.from_angle(RIM_START + TAU * progress) * radius
		draw_circle(head, 4.5, PALE_MINT)

## Triangle fan whose vertices fade towards the tail, so the arm drags a wedge of light.
func _draw_sweep(center: Vector2, radius: float) -> void:
	var angle := _sweep_angle()
	var color := CRIMSON if _threat_count > 0 else MINT
	var steps := 20
	var points := PackedVector2Array([center])
	var colors := PackedColorArray([Color(color, 0.0)])
	for i in steps + 1:
		var ratio := float(i) / steps
		var vertex_angle := angle - SWEEP_TRAIL * (1.0 - ratio)
		points.append(center + Vector2.from_angle(vertex_angle) * radius)
		colors.append(Color(color, 0.05 + 0.34 * ratio * ratio))
	draw_polygon(points, colors)
	draw_line(center, center + Vector2.from_angle(angle) * radius, Color(color, 0.85), 2.0, true)

func _draw_blips(center: Vector2, radius: float) -> void:
	for blip in _blips:
		var lit_at: float = blip["lit_at"]
		if lit_at < 0.0:
			continue
		var settle := clampf((_elapsed - lit_at) / BLIP_FADE, 0.0, 1.0)
		var alpha := lerpf(1.0, 0.45, settle)
		var is_threat: bool = blip["is_threat"]
		var angle: float = blip["angle"]
		var distance: float = blip["radius"]
		var color := CRIMSON if is_threat else PALE_MINT
		var position := center + Vector2.from_angle(angle) * radius * distance
		draw_circle(position, lerpf(6.0, 3.0, settle), Color(color, alpha))
		if is_threat:
			var halo := 8.0 + 2.5 * sin(_elapsed * 6.0)
			draw_arc(position, halo, 0.0, TAU, 20, Color(color, alpha * 0.5), 1.5, true)

## The wordmark drops in letter by letter as the sweep progresses.
func _draw_wordmark(baseline: float, progress: float) -> void:
	var font_size := 34
	var spacing := 7.0
	var widths: Array[float] = []
	var total := -spacing
	for i in WORDMARK.length():
		var width := BOLD_FONT.get_string_size(
			WORDMARK[i], HORIZONTAL_ALIGNMENT_LEFT, -1, font_size
		).x
		widths.append(width)
		total += width + spacing

	var pen := size.x * 0.5 - total * 0.5
	for i in WORDMARK.length():
		var lands_at := 0.10 + 0.085 * i
		var ratio := clampf((progress - lands_at) / 0.16, 0.0, 1.0)
		var eased := 1.0 - pow(1.0 - ratio, 3.0)
		var offset := Vector2(0.0, (1.0 - eased) * -14.0)
		draw_char(
			BOLD_FONT, Vector2(pen, baseline) + offset, WORDMARK[i], font_size,
			Color(MINT, eased)
		)
		pen += widths[i] + spacing

## One line of flavour text per quarter of the sweep.
func _draw_caption(center: Vector2, progress: float) -> void:
	var index := mini(int(progress * CAPTIONS.size()), CAPTIONS.size() - 1)
	var caption := CAPTIONS[index]
	var font_size := 12
	var width := SEMIBOLD_FONT.get_string_size(
		caption, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size
	).x
	draw_string(
		SEMIBOLD_FONT, center + Vector2(-width * 0.5, 0.0), caption,
		HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(MINT, 0.75)
	)
#endregion

#region BLIPS
func _build_blips() -> void:
	_blips.clear()
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	for i in BLIP_COUNT:
		_blips.append({
			"angle": rng.randf() * TAU,
			"radius": rng.randf_range(0.20, 0.90),
			"is_threat": i < _threat_count,
			"lit_at": -1.0,
		})
	_blips.shuffle()

## A blip only appears once the arm has swept over it.
func _light_up_blips(from_angle: float, to_angle: float) -> void:
	var from := fposmod(from_angle, TAU)
	var to := fposmod(to_angle, TAU)
	for blip in _blips:
		if blip["lit_at"] >= 0.0:
			continue
		var angle: float = blip["angle"]
		var swept := false
		if to >= from:
			swept = angle >= from and angle < to
		else: # The arm wrapped past 0 this frame.
			swept = angle >= from or angle < to
		if swept:
			blip["lit_at"] = _elapsed

func _sweep_angle() -> float:
	return RIM_START + _elapsed * TAU / SWEEP_PERIOD
#endregion
