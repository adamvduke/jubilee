require 'spec_helper'

feature 'basic rails4 test' do

  before(:all) do
    configurator = Jubilee::Configuration.new(chdir: "#{apps_dir}/rails4/basic")
    @server = Jubilee::Server.new(configurator.app, configurator.options)
    @server.start
    sleep 0.1
  end

  after(:all) do
    @server.stop
  end

  it 'should do a basic get' do
    visit '/'
    page.should have_content('It works')
    page.find('#success')[:class].should == 'basic-rails4'
  end

  context 'streaming' do
    it "should work for small responses" do
      verify_streaming("/root/streaming?count=0")
    end

    it "should work for large responses" do
      verify_streaming("/root/streaming?count=500")
    end

    def verify_streaming(url)
      uri = URI.parse("#{Capybara.app_host}#{url}")
      Net::HTTP.get_response(uri) do |response|
        response.should be_chunked
        response.header['transfer-encoding'].should == 'chunked'
        chunk_count, body = 0, ""
        response.read_body do |chunk|
          chunk_count += 1
          body += chunk
        end
        body.should include('It works')
        body.each_line do |line|
          line.should_not match(/^\d+\s*$/)
        end
        chunk_count.should be > 1
      end
    end
  end

  it 'should return a static page beneath default public dir' do
    visit "/some_page.html"
    element = page.find('#success')
    element.should_not be_nil
    element.text.should == 'static page'
  end

  it "should support setting multiple cookies" do
    visit "/root/multiple_cookies"
    page.driver.cookies['foo1'].value.should == 'bar1'
    page.driver.cookies['foo2'].value.should == 'bar2'
    page.driver.cookies['foo3'].value.should == 'bar3'
  end

end
