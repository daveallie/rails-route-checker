# frozen_string_literal: true

module RailsRouteChecker
  module Parsers
    module HamlParser
      module Tree
        class Node
          include Enumerable

          attr_accessor :children, :parent
          attr_reader :line, :type

          def initialize(document, parse_node)
            @line = parse_node.line
            @document = document
            @value = parse_node.value
            @type = parse_node.type
          end

          def each
            return to_enum(__callee__) unless block_given?

            node = self
            loop do
              yield node
              break unless (node = node.next_node)
            end
          end

          def directives
            directives = []
            directives << predecessor.directives if predecessor
            directives.flatten
          end

          def source_code
            next_node_line =
              if next_node
                next_node.line - 1
              else
                @document.source_lines.count + 1
              end

            @document.source_lines[@line - 1...next_node_line]
                     .join("\n")
                     .gsub(/^\s*\z/m, '')
          end

          def inspect
            "#<#{self.class.name}>"
          end

          def lines
            return [] unless @value && text

            text.split(/\r\n|\r|\n/)
          end

          def line_numbers
            return (line..line) unless @value && text

            (line..line + lines.count)
          end

          def predecessor
            siblings.previous(self) || parent
          end

          def successor
            next_sibling = siblings.next(self)
            return next_sibling if next_sibling

            parent&.successor
          end

          def next_node
            children.first || successor
          end

          def subsequents
            siblings.subsequents(self)
          end

          def text
            @value[:text].to_s
          end

          private

          def siblings
            @siblings ||= Siblings.new(parent ? parent.children : [self])
          end

          class Siblings < SimpleDelegator
            def next(node)
              subsequents(node).first
            end

            def previous(node)
              priors(node).last
            end

            def priors(node)
              position = position(node)
              if position.zero?
                []
              else
                siblings[0..(position - 1)]
              end
            end

            def subsequents(node)
              siblings[(position(node) + 1)..-1]
            end

            private

            alias siblings __getobj__

            def position(node)
              siblings.index(node)
            end
          end
        end
      end
    end
  end
end
