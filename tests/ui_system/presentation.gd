extends SceneTree
var checks := 0
var failures := 0
func check(ok: bool, why: String) -> void:
 checks += 1
 if not ok:
  failures += 1
  push_error(why)
func _initialize() -> void: call_deferred("run")
func run() -> void:
 var source := '<svg><path id="terrain" d="M0 0L10 10"/><polyline class="azgaar-land_road" points="1,2 3,4"/><g class="shared-game-icon" data-role="hamlet"><circle cx="100" cy="200" r="16"/><svg x="87" y="187" width="26" height="26" viewBox="0 0 512 512"><path d="M0 0L512 512"/></svg></g><rect x="18" y="18" width="330" height="70"/><text x="32" y="48">Caption</text></svg>'
 var original := source.sha256_text()
 var composed := LocalMapArt.for_gameplay(source)
 check(source.sha256_text() == original, "presentation leaves sealed SVG input unchanged")
 check(composed.contains('<path id="terrain" d="M0 0L10 10"/>'), "terrain path unchanged")
 check(composed.contains('<polyline class="azgaar-land_road" points="1,2 3,4"/>'), "authoritative road stroke unchanged")
 check(composed.contains('<circle cx="100" cy="200" r="16"/>'), "source settlement remains at exact coordinates")
 check(not composed.contains('viewBox="0 0 512 512"'), "nested decorative icon removed")
 check(not composed.contains('<rect x="18"') and not composed.contains('<text'), "unsupported captions and empty backplates removed")
 check(LocalMapArt.for_gameplay(composed) == composed, "presentation filter idempotent")
 var theme := GameUI.shared_theme()
 check(theme == GameUI.shared_theme(), "screens share one theme resource")
 check(theme.get_color("font_color", "Label") != theme.get_color("font_color", "ScreenTitle"), "body has distinct hierarchy from headings")
 check(theme.get_font_size("font_size", "Button") == GameUI.BODY and GameUI.BODY >= 14, "compact controls retain readable body font")
 var row := GameUI.row("A known place", "Available", func(): pass)
 root.add_child(row)
 check(row.focus_mode == Control.FOCUS_ALL, "shared row supports keyboard focus")
 check(row.tooltip_text.contains("A known place"), "truncated row retains full title")
 row.queue_free()
 var screen := Control.new()
 root.add_child(screen)
 GameUI.install(screen)
 for physical in [Vector2i(640,360),Vector2i(1280,720),Vector2i(2560,1440)]:
  root.size = physical
  for i in 4: await process_frame
  var canvas := root.content_scale_size
  check(canvas.x >= 640 and canvas.y >= 360, "minimum logical layout respected")
  if physical.x > 640: check(canvas.x > 640, "larger window adds layout room")
  check(float(physical.x) / canvas.x <= 2.01, "physical control scale bounded")
 print("GAME-83 presentation: ",checks," checks, ",failures," failures")
 quit(1 if failures else 0)
