require 'ripper'

module RailsRouteChecker
  module Parsers
    module RubyParser
      class << self
        def run(filename, **opts)
          file_source = opts[:source] || File.read(filename)

          items = []

          deep_iterator(Ripper.sexp(file_source)) do |item, extra_data|
            scope = extra_data[:scope]
            next unless %i[vcall fcall].include?(scope[-2])
            next unless scope[-1] == :@ident
            next unless item.end_with?('_path', '_url')

            next if opts[:filter].respond_to?(:call) && !opts[:filter].call(item)

            line = extra_data[:position][0]
            line = opts[:source_map][line] || 'unknown' if opts[:source_map]

            items << { file: filename, line: line, method: item }
          end

          items
        end

        private

        def deep_iterator(list, current_scope = [], current_line_num = [], &block)
          if list.is_a?(Array)
            if list[0].is_a?(Symbol)
              current_scope << list[0]

              if list[-1].is_a?(Array) && list[-1].length == 2 && list[-1].all? { |item| item.is_a?(Integer) }
                current_line_num = list[-1]
                list = list[0..-2]
              end

              list[1..-1].each do |item|
                deep_iterator(item, current_scope, current_line_num, &block)
              end
              current_scope.pop
            else
              list.each do |item|
                deep_iterator(item, current_scope, current_line_num, &block)
              end
            end
          elsif !list.nil?
            yield(list, { scope: current_scope, position: current_line_num })
          end
        end
      end
    end
  end
end
