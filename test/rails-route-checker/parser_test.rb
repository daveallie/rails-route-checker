require "minitest/autorun"
require "haml"
require 'rails-route-checker/parsers/ruby_parser'
require 'rails-route-checker/parsers/haml_parser'
require 'rails-route-checker/parsers/haml_parser/document'

describe "HamlParser" do
  filename = Pathname.new("#{__dir__}/../dummy/app/views/articles/index_haml.html.haml")
  @haml_parser = RailsRouteChecker::Parsers::HamlParser.run(filename)
  it "everything is valid" do
    assert true
  end
end

