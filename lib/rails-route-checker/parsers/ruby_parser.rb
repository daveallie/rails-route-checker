require 'ripper'

module RailsRouteChecker
  module Parsers
    module RubyParser
      class << self
        def run(filename, **opts)
          file_source = opts[:source] || File.read(filename)
          process_file(filename, file_source, opts)
        end

        private

        def process_file(filename, source, opts)
          items = []

          deep_iterator(Ripper.sexp(source)) do |item, extra_data|
            next unless item_is_url_call?(item, extra_data)
            next if opts[:filter].respond_to?(:call) && !opts[:filter].call(item)

            line = extra_data[:position][0]
            line = opts[:source_map][line] || 'unknown' if opts[:source_map]

            items << { file: filename, line: line, method: item }
          end

          items
        end

        def item_is_url_call?(item, extra_data)
          scope = extra_data[:scope]
          return false unless %i[vcall fcall].include?(scope[-2])
          return false unless scope[-1] == :@ident
          return false unless item.end_with?('_path', '_url')

          true
        end

        def deep_iterator(list, current_scope = [], current_line_num = [], &block)
          return deep_iterate_array(list, current_scope, current_line_num, &block) if list.is_a?(Array)

          yield(list, { scope: current_scope, position: current_line_num }) unless list.nil?
        end

        def deep_iterate_array(list, current_scope, current_line_num, &block)
          unless list[0].is_a?(Symbol)
            list.each do |item|
              deep_iterator(item, current_scope, current_line_num, &block)
            end
            return
          end

          current_scope << list[0]

          last_list_item = list[-1]
          if last_list_item.is_a?(Array) &&
             last_list_item.length == 2 &&
             last_list_item.all? { |item| item.is_a?(Integer) }
            current_line_num = last_list_item
            list = list[0..-2]
          end

          list[1..-1].each do |item|
            deep_iterator(item, current_scope, current_line_num, &block)
          end
          current_scope.pop
        end
      end
    end
  end
end
