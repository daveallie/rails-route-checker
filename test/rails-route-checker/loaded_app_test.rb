require 'minitest/autorun'

require 'rails-route-checker/loaded_app'

describe RailsRouteChecker::LoadedApp do
  let(:loaded_app) do
    Dir.stub(:pwd, File.join(__dir__, '../dummy')) do
      RailsRouteChecker::LoadedApp.new
    end
  end

  it 'parses ActionController::Base and ActionController::API descendants' do
    assert_equal(
      loaded_app.controller_information.keys.sort, %w[application articles base_api articles_api].sort
    )
  end
end
