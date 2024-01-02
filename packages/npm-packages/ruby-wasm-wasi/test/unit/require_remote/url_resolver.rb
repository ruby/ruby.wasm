require "test-unit"
require "js"
require "js/require_remote"

class TestURLResolver < Test::Unit::TestCase
  def test_get_location
    url_resolver = JS::RequireRemote::URLResolver.new("https://example.com")
    script_location = url_resolver.get_location("foo.rb")
    assert_equal "https://example.com/foo.rb", script_location.url.to_s
    assert_equal "foo.rb", script_location.filename
  end

  def test_get_location_with_relative_path
    url_resolver = JS::RequireRemote::URLResolver.new("https://example.com")
    script_location = url_resolver.get_location("./foo.rb")
    assert_equal "https://example.com/foo.rb", script_location.url.to_s
    assert_equal "./foo.rb", script_location.filename
  end

  def test_get_location_with_relative_path_and_filename
    url_resolver =
      JS::RequireRemote::URLResolver.new("https://example.com/bar.rb")
    script_location = url_resolver.get_location("./foo.rb")
    assert_equal "https://example.com/foo.rb", script_location.url.to_s
    assert_equal "./foo.rb", script_location.filename
  end

  def test_get_location_with_relative_path_and_filename_without_extension
    url_resolver = JS::RequireRemote::URLResolver.new("https://example.com/bar")
    script_location = url_resolver.get_location("./foo")
    assert_equal "https://example.com/foo.rb", script_location.url.to_s
    assert_equal "./foo.rb", script_location.filename
  end

  def test_get_location_with_relative_path_and_directory
    url_resolver =
      JS::RequireRemote::URLResolver.new("https://example.com/bar/")
    script_location = url_resolver.get_location("./foo.rb")
    assert_equal "https://example.com/bar/foo.rb", script_location.url.to_s
    assert_equal "./foo.rb", script_location.filename
  end

  def test_get_location_with_backward_relative_path
    url_resolver =
      JS::RequireRemote::URLResolver.new("https://example.com/bar/")
    script_location = url_resolver.get_location("../foo.rb")
    assert_equal "https://example.com/foo.rb", script_location.url.to_s
    assert_equal "../foo.rb", script_location.filename
  end

  def test_get_location_with_backward_relative_path_and_filename
    url_resolver =
      JS::RequireRemote::URLResolver.new("https://example.com/baz.rb")
    script_location = url_resolver.get_location("../foo.rb")
    assert_equal "https://example.com/foo.rb", script_location.url.to_s
    assert_equal "../foo.rb", script_location.filename
  end

  def test_push_and_pop
    url_resolver = JS::RequireRemote::URLResolver.new("https://example.com")
    url_resolver.push("https://example.com/foo/bar.rb")
    script_location = url_resolver.get_location("./baz.rb")
    assert_equal "https://example.com/foo/baz.rb", script_location.url.to_s
    assert_equal "./baz.rb", script_location.filename
    url_resolver.pop
    script_location = url_resolver.get_location("./baz.rb")
    assert_equal "https://example.com/baz.rb", script_location.url.to_s
    assert_equal "./baz.rb", script_location.filename
  end
end
