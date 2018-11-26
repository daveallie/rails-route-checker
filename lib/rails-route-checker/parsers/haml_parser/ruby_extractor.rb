module RailsRouteChecker
  module Parsers
    module HamlParser
      class RubyExtractor
        RubySource = Struct.new(:source, :source_map)

        def self.extract(document)
          new(document).extract
        end

        def initialize(document)
          @document = document
        end

        def extract
          @source_lines = []
          @source_map = {}
          @line_count = 0
          @indent_level = 0
          @output_count = 0

          visit_children(document.tree)

          RubySource.new(@source_lines.join("\n"), @source_map)
        end

        def visit_tag(node)
          additional_attributes = node.dynamic_attributes_sources

          additional_attributes.each do |attributes_code|
            attributes_code = attributes_code.gsub(/\s*\n\s*/, ' ').strip
            add_line("{}.merge(#{attributes_code.strip})", node)
          end

          if node.hash_attributes? && node.dynamic_attributes_sources.empty?
            normalized_attr_source = node.dynamic_attributes_source[:hash].gsub(/\s*\n\s*/, ' ')

            add_line(normalized_attr_source, node)
          end

          code = node.script.strip
          add_line(code, node) unless code.empty?
        end

        def visit_script(node)
          code = node.text
          add_line(code.strip, node)

          start_block = anonymous_block?(code) || start_block_keyword?(code)

          @indent_level += 1 if start_block

          yield

          return unless start_block

          @indent_level -= 1
          add_line('end', node)
        end

        def visit_filter(node)
          return unless node.filter_type == 'ruby'

          node.text.split("\n").each_with_index do |line, index|
            add_line(line, node.line + index + 1, false)
          end
        end

        def visit(node)
          block_called = false

          block = lambda do |descend = :children|
            block_called = true
            visit_children(node) if descend == :children
          end

          case node.type
          when :tag
            visit_tag(node)
          when :script, :silent_script
            visit_script(node, &block)
          when :filter
            visit_filter(node)
          end

          visit_children(node) unless block_called
        end

        def visit_children(parent)
          parent.children.each { |node| visit(node) }
        end

        private

        attr_reader :document

        def add_line(code, node_or_line, discard_blanks = true)
          return if code.empty? && discard_blanks

          indent_level = @indent_level

          if node_or_line.respond_to?(:line)
            indent_level -= 1 if mid_block_keyword?(code)
          end

          indent = (' ' * 2 * indent_level)

          @source_lines << indent_code(code, indent)

          original_line =
            node_or_line.respond_to?(:line) ? node_or_line.line : node_or_line

          (code.count("\n") + 1).times do
            @line_count += 1
            @source_map[@line_count] = original_line
          end
        end

        def indent_code(code, indent)
          codes = code.split("\n")
          codes.map { |c| indent + c }.join("\n")
        end

        def anonymous_block?(text)
          text =~ /\bdo\s*(\|\s*[^\|]*\s*\|)?(\s*#.*)?\z/
        end

        START_BLOCK_KEYWORDS = %w[if unless case begin for until while].freeze
        def start_block_keyword?(text)
          START_BLOCK_KEYWORDS.include?(block_keyword(text))
        end

        MID_BLOCK_KEYWORDS = %w[else elsif when rescue ensure].freeze
        def mid_block_keyword?(text)
          MID_BLOCK_KEYWORDS.include?(block_keyword(text))
        end

        LOOP_KEYWORDS = %w[for until while].freeze
        def block_keyword(text)
          # Need to handle 'for'/'while' since regex stolen from HAML parser doesn't
          keyword = text[/\A\s*([^\s]+)\s+/, 1]
          return keyword if keyword && LOOP_KEYWORDS.include?(keyword)

          keyword = text.scan(Haml::Parser::BLOCK_KEYWORD_REGEX)[0]
          return unless keyword

          keyword[0] || keyword[1]
        end
      end
    end
  end
end
