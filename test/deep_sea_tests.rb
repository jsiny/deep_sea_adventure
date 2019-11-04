ENV["RACK_ENV"] = 'test'

require 'simplecov'
SimpleCov.start
require 'minitest/autorun'
require 'minitest/reporters'
Minitest::Reporters.use!
require 'rack/test'

require_relative '../deep_sea.rb'

class DeepSeaTest < Minitest::Test
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def test_access_homepage
    get '/'
    assert_equal 200, last_response.status
    assert_equal 'text/html;charset=utf-8', last_response['Content-Type']
    assert_includes last_response.body, "Deep Sea Adventure"
    assert_includes last_response.body, 'a class="btn btn-outline-primary"'
  end

end