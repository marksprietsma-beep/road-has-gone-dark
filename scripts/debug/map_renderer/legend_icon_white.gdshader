shader_type canvas_item;

// Legend-only white stencil. Retain the source icon's exact alpha/shape,
// but ignore the dark parchment RGB of the shared Game-icons TextureRect.
// Do not modify the actual world-map textures.
void fragment() {
    vec4 source = texture(TEXTURE, UV);
    COLOR = vec4(1.0, 1.0, 1.0, source.a);
}
