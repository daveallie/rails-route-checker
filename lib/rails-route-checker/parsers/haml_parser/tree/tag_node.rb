module RailsRouteChecker::Parsers::HamlParser::Tree
  class TagNode < Node
    def dynamic_attributes_sources
      @dynamic_attributes_sources ||=
        if Gem::Version.new(Haml::VERSION) < Gem::Version.new('5')
          @value[:attributes_hashes]
        else
          Array(@value[:dynamic_attributes].to_literal).reject(&:empty?)
        end
    end

    def dynamic_attributes_source
      @dynamic_attributes_source ||=
        attributes_source.reject { |key| key == :static }
    end

    def attributes_source
      @attr_source ||=
        begin
          _explicit_tag, static_attrs, rest =
            source_code.scan(/\A\s*(%[-:\w]+)?([-:\w\.\#]*)(.*)/m)[0]

          attr_types = {
            '{' => [:hash, %w[{ }]],
            '(' => [:html, %w[( )]],
            '[' => [:object_ref, %w[[ ]]]
          }

          attr_source = { static: static_attrs }
          while rest
            type, chars = attr_types[rest[0]]
            break unless type
            break if attr_source[type]

            attr_source[type], rest = Haml::Util.balance(rest, *chars)
          end

          attr_source
        end
    end

    def hash_attributes?
      !dynamic_attributes_source[:hash].nil?
    end

    def script
      (@value[:value] if @value[:parse]) || ''
    end
  end
end
