class_name MapWorldText
extends RefCounted

## Azgaar notes can include rich HTML, interactive external iframes and
## undecipherable inscription glyphs. This is a DISPLAY-ONLY conversion:
## never mutate the canonical marker note or execute source HTML.
static func plain(value: String, limit: int = 480) -> String:
	var text := value.substr(0, 16000)
	# Eliminate active/embed content including its body. The source often
	# contains Deorum character and Watabou dungeon iframe previews.
	var excluded := [
		"(?is)<\\s*(script|iframe|style|svg|object|embed)\\b[^>]*>.*?<\\s*/\\s*\\1\\s*>",
		"(?is)<\\s*div\\b[^>]*\\bstyle\\s*=[^>]*>.*?<\\s*/\\s*div\\s*>",
		"(?is)<\\s*(iframe|img|embed|source)\\b[^>]*>",
		"(?is)<[^>]*>",
		"(?i)https?://[^\\s<>]+"
	]
	for pattern in excluded:
		var re := RegEx.new()
		if re.compile(pattern) == OK:
			text = re.sub(text, " ", true)
	# Invalid XML scalar zero must be stripped *before* entity decoding.
	# Defining a GDScript string literal with a backslash-u zero escape
	# itself materialises a NUL, which Godot logs as a Unicode parse error.
	var zero_entity := RegEx.new()
	zero_entity.compile("(?i)&#(?:0+|x0+);")
	text = zero_entity.sub(text, " ", true).xml_unescape()
	var readable := ""
	for index in text.length():
		var codepoint := text.unicode_at(index)
		if codepoint == 0 or codepoint == 65533:
			continue
		readable += text.substr(index, 1)
	text = readable.strip_edges()
	# A source link is not clickable after conversion, so don't promise it.
	text = text.replace("See One page dungeon", "")
	text = text.replace("See  One page dungeon", "")
	var spaces := RegEx.new()
	spaces.compile("\\s+")
	text = spaces.sub(text, " ", true).strip_edges()
	if text.length() > limit:
		text = text.substr(0, limit).strip_edges() + "…"
	return text
