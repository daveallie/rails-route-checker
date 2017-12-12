module RailsRouteChecker
  module Parsers
    module ErbParser
      class << self
        def run(filename, **opts)
          file_source = opts[:source] || File.read(filename)

          next_ruby_source_line_num = 1
          ruby_source = ''
          source_map = {}

          file_source.split("\n").each_with_index do |line, line_num|
            ruby_lines = process_line(line)
            next unless ruby_lines.any?

            ruby_source += ruby_lines.join("\n") + "\n"
            ruby_lines.length.times do |i|
              source_map[next_ruby_source_line_num + i] = line_num + 1
            end
            next_ruby_source_line_num += ruby_lines.length
          end

          opts[:source] = ruby_source
          opts[:source_map] = source_map

          RailsRouteChecker::Parsers::RubyParser.run(filename, **opts)
        end

        private

        def process_line(line)
          lookup_index = 0
          ruby_lines = []

          while lookup_index < line.length
            opening = line.index('<%=', lookup_index)
            is_write_opening = opening
            opening ||= line.index('<%', lookup_index)
            break unless opening

            closing = line.index('%>', opening + 2)
            break unless closing

            ruby_lines << line[(opening + (is_write_opening ? 3 : 2))..(closing - 1)]
            lookup_index = closing + 2
          end
          ruby_lines
        end
      end
    end
  end
end
