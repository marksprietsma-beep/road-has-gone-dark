class_name LocalMapArt
extends RefCounted
## Presentation only: preserves the sealed packet and every geographic path.
## Godot's SVG rasterizer does not honour nested SVG viewports consistently.
static func for_gameplay(svg: String) -> String:
 var icons := RegEx.new()
 icons.compile('<g class="shared-game-icon"[^>]*>(<circle[^>]*/>)<svg[^>]*>[\\s\\S]*?</svg></g>')
 var result := icons.sub(svg, "$1", true)
 # SVG text is not supported by Godot's rasterizer. Its caption backplates
 # become empty boxes; real UI labels/markers supply that information instead.
 var captions := RegEx.new()
 captions.compile('<rect[^>]*(?:fill="#efe1be"|x="18" y="(?:18|950)")[^>]*/>|<text[\\s\\S]*?</text>')
 return captions.sub(result, "", true)
