require 'rack'

class BasicMiddleware
  def initialize(app, options={})
    @app = app
  end
  def call(env)
    # We had a bug triggered at one point by trying to access any HTTP
    # header with a key less than 10 bytes long
    env['HTTP_foo']
    # Save off the accept header before Rack::Lint messes with it
    env['tb.accept_header'] = env['HTTP_ACCEPT']
    @app.call(env)
  end
end

use BasicMiddleware
use Rack::Lint

app = lambda { |env|
  body = <<-EOF
<div id='success' class='basic-rack'>it worked</div>
<div id='ruby-version'>#{RUBY_VERSION}</div>
<div id='path'>#{__FILE__}</div>
<div id='script_name'>#{env['SCRIPT_NAME']}</div>
<div id='path_info'>#{env['PATH_INFO']}</div>
<div id='request_uri'>#{env['REQUEST_URI']}</div>
<div id='accept_header'>#{env['tb.accept_header']}</div>
EOF
  if env['REQUEST_METHOD'] == 'POST'
    input = env['rack.input']
    if env['PATH_INFO'] == '/basic-rack/gets'
      posted = ''
      posted_line = input.gets
      while posted_line != nil
        posted << posted_line
        posted_line = input.gets
      end
    elsif env['PATH_INFO'] == '/basic-rack/read'
      posted = input.read(2)
      posted << input.read
    elsif env['PATH_INFO'] == '/basic-rack/each'
      posted = ""
      input.each { |str| posted << str}
    end
    body << "<div id='posted'>#{posted}</div>"
  end
  [200, { 'Content-Type' => 'text/html' }, [body]]
}
run app
