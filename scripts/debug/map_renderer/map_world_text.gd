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
	text = text.xml_unescape()
	text = text.replace("\uFFFD", "").replace("\u0000", "").strip_edges()
	# A source link is not clickable after conversion, so don't promise it.
	text = text.replace("See One page dungeon", "")
	text = text.replace("See  One page dungeon", "")
	var spaces := RegEx.new()
	spaces.compile("\\s+")
	text = spaces.sub(text, " ", true).strip_edges()
	if text.length() > limit:
		text = text.substr(0, limit).strip_edges() + "…"
	return text
