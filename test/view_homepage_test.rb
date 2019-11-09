class DeepSeaTest < Minitest::Test
  def test_access_homepage
    get '/'
    assert_equal 200, last_response.status
    assert_equal 'text/html;charset=utf-8', last_response['Content-Type']
    assert_includes last_response.body, "Deep Sea Adventure"
    assert_includes last_response.body, '<a class="btn btn-outline-primary"'
  end
end