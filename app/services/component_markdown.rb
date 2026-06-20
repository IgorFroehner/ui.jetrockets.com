# Renders one ComponentCatalog::Entry to plain Markdown.
#
# This is the LLM-native mirror of ComponentDocsHelper's HTML output:
# same data (props, slots, usage, examples), flat Markdown instead of
# ViewComponent markup.
class ComponentMarkdown
  def initialize(entry)
    @entry = entry
    @data  = entry.data
  end

  def self.call(entry) = new(entry).call

  def call
    [
      heading,
      usage_section,
      props_section,
      slots_section,
      examples_section
    ].compact.join("\n\n") + "\n"
  end

  private

  attr_reader :entry, :data

  def heading
    out = ["# #{entry.title}"]
    out << entry.description if entry.description.present?
    out.join("\n\n")
  end

  def usage_section
    usage = data["usage"].presence || data["preview"].presence
    return if usage.blank?

    "## Usage\n\n#{erb_block(usage)}"
  end

  def props_section
    props = Array(data["props"])
    return if props.empty?

    rows = props.map do |prop|
      type = [prop["type"], format_values(prop["values"])].compact.join(" ")
      "| `#{prop['name']}` | #{type} | #{code_or_dash(prop['default'])} | #{inline(prop['description'])} |"
    end

    table = ["| Prop | Type | Default | Description |", "|------|------|---------|-------------|", *rows].join("\n")
    note  = data["accepts_html_attributes"] ? "\n\nAlso accepts any HTML attributes via `**options` (e.g. `id:`, `data:`, `aria:`, `class:`)." : ""

    "## Props\n\n#{table}#{note}"
  end

  def slots_section
    slots = Array(data["slots"])
    return if slots.empty?

    rows = slots.map do |slot|
      "| `#{slot['name']}` | `ui.#{slot['name']}` | #{inline(slot['description'])} |"
    end

    table = ["| Name | Helper | Description |", "|------|--------|-------------|", *rows].join("\n")
    "## Subcomponents\n\nUse the subcomponents below, or any HTML.\n\n#{table}"
  end

  def examples_section
    examples = Array(data["examples"])
    return if examples.empty?

    blocks = examples.map do |ex|
      "### #{ex['name']}\n\n#{erb_block(ex['code'])}"
    end

    "## Examples\n\n#{blocks.join("\n\n")}"
  end

  def erb_block(code)
    "```erb\n#{code.to_s.strip}\n```"
  end

  def format_values(values)
    return if values.blank?

    "(#{Array(values).join(', ')})"
  end

  def code_or_dash(value)
    value.present? ? "`#{value}`" : "—"
  end

  def inline(text)
    text.to_s.gsub(/\s+/, " ").strip
  end
end
