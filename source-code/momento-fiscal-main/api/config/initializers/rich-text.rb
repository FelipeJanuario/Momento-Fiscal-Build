RichText.instance_eval do
  @config = nil
end

RichText.configure do |c|
  c.html_inline_formats ||= {
    bold:           { tag: 'strong' },
    br:             { tag: 'br' },
    hr:             { tag: 'hr', block_format: false },
    italic:         { tag: 'em' },
    strike:         { tag: 'strike' },
    header:         { tag: 'p', apply: ->(el, op, ctx) { el[:style] = "font-size: #{1.0 + (1 - op.attributes[:header].to_i * 0.2)}em; font-weight: bold;" } },
    link:           { tag: 'a', apply: ->(el, op, ctx){ el[:href] = op.attributes[:link] } },
    size:           { tag: 'span', apply: ->(el, op, ctx) { el[:style] = el[:style].to_s + "font-size: #{op.attributes[:size]};" } },
    color:          { tag: 'span', apply: ->(el, op, ctx) { el[:style] = el[:style].to_s + "color: #{op.attributes[:color]};" } },
    background:     { tag: 'span', apply: ->(el, op, ctx) { el[:style] = el[:style].to_s + "background: #{op.attributes[:background]};" } },
    code:           { tag: 'code', apply: ->(el, op, ctx) { el[:style] = "background: #f8f8f8; padding: 2px; border-radius: 2px;" } },
    script:         { tag: 'span', apply: ->(el, op, ctx) { el[:style] = el[:style].to_s + "vertical-align: #{op.attributes[:script]}; font-size: 0.8em;" } },
    blockquote:     { tag: 'blockquote', apply: ->(el, op, ctx) { el[:style] = "border-left: 2px solid #ccc; padding-left: 10px;" } },
    indent:         { tag: 'div', apply: ->(el, op, ctx) { el[:style] = "margin-left: #{op.attributes[:indent]}em;" } },
  }

  c.html_block_formats ||= {
    align:          { apply: ->(el, op, ctx) { el[:style] = "text-align: #{op.attributes[:align]}" } },
    firstheader:    { tag: 'h1' },
    secondheader:   { tag: 'h2' },
    thirdheader:    { tag: 'h3' },
    bullet:         { tag: 'li', parent: 'ul' },
    list:           { tag: 'li', parent: 'ul' },
    id:             { apply: ->(el, op, ctx){ el[:id] = op.attributes[:id] } }
  }

  c.html_default_block_format = 'p'
  c.safe_mode = true
end
