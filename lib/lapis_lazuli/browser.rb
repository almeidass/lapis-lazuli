require 'selenium-webdriver'
require 'watir-webdriver'
require "watir-webdriver/extensions/alerts"
module LapisLazuli
  class Browser
    @ll
    @browser

    def initialize(ll)
      @ll = ll
      @browser = self.create
    end

    def create
      browser = nil
      browser_name = ENV['BROWSER']
      if browser_name.nil?
        browser_name =  @ll.config('browser', 'firefox')
      end
      case browser_name.downcase
        when 'firefox'
          browser = Watir::Browser.new :firefox
        when 'chrome'
          # Check Platform running script
          if RUBY_PLATFORM.downcase.include?("linux")
            Watir::Browser::Chrome.path = "/usr/lib/chromium-browser/chromium-browser"
          end
          browser = Watir::Browser.new :chrome
        when 'safari'
          browser = Watir::Browser.new :safari
        when 'ie'
          require 'rbconfig'
          if (RbConfig::CONFIG['host_os'] =~ /mswin|mingw|cygwin/)
            browser = Watir::Browser.new :ie
          else
            raise "You can't run IE tests on non-Windows machine"
          end
        when 'ios'
          if RUBY_PLATFORM.downcase.include?("darwin")
            browser = Watir::Browser.new :iphone
          else
            raise "You can't run IOS tests on non-mac machine"
          end
        else
          # Defaults to firefox
          @ll.log.info("Couldn't determine the browser to use. Using firefox")
          browser = Watir::Browser.new :firefox
      end
      return browser
    end

    def restart
      @browser.close
      @browser = self.create
    end

    def wait(settings)
      message = "Waiting"
      timeout = 10
      if settings.has_key? :timeout
        timeout = settings[:timeout].to_i
      end

      block = nil
      if settings.has_key? :text
        text = settings[:text]
        message = "Waiting for text '#{text}'"
        if text.is_a? Regexp
          block = lambda {|arg|
            self.browser.text =~ text
          }
        else
          block = lambda {|arg|
            self.browser.text.include?(text)
          }
        end
      elsif settings.has_key? :html
        html = settings[:html]
        message = "Waiting for html '#{html}'"
        block = lambda {|arg|
          self.browser.html.include?(html)
        }
      end

      if block.nil?
        raise "Incorrect settings"
      elsif settings.has_key? :condition and settings[:condition] == :while
        Watir::Wait.while(timeout, message, &block)
      else
        Watir::Wait.until(timeout, message, &block)
      end
    end

    def findAll(settings)
      error = true
      if settings.has_key? :error and not settings[:error]
        error = false
      end

      if settings.has_key? :text_field
        text_field = settings[:text_field]
        if text_field == :first
          p "First field"
          return @browser.text_fields(:type => "text") ||
            (error and @ll.error("First inputfield not found"))
        elsif text_field.is_a? Hash
          return @browser.text_fields(text_field) ||
            (error and @ll.error("First inputfield not found"))
        else
          text_field = text_field.to_s
          begin
            # Find it based on name or id
            xpath = @browser.text_fields(
                :xpath,
                "//*[@name='#{text_field}' or @id='#{text_field}']"
              )
            return xpath
          rescue
            @ll.error("Could not find a text field with name or id equal to '#{text_field}'")
          end
        end
      end
      @ll.error("Incorrect settings for find")
    end

    def findAllPresent(settings)
      self.findAll(settings).find_all do |element|
        begin
          element.present?
        rescue
          false
        end
      end
    end

    def find(settings)
      result = nil
      if settings.has_key? :present and not settings[:present]
        result = self.findAll(settings)
      else
        result = self.findAllPresent(settings)
      end

      if result.is_a? Watir::ElementCollection
        return result.first
      elsif result.is_a? Array
        return result[0]
      else
        @ll.error("Incorrect settings for find #{result}")
      end
    end

    def has_error?
      if not @ll.has_config?("error_strings")
        return false
      end
      begin
        page_text = @browser.html
        @ll.config("error_strings").each do |error|
          if page_text.scan(error)[0]
            return true
          end
        end
      rescue RuntimeError => err
        @ll.log.debug "Cannot read the html for page #{@browser.url}: #{err}"
      end
      return false
    end

    # Taking a screenshot of the current page. Using the name as defined at the start of every scenario
    def take_screenshot
      begin
        fileloc = @ll.config("screenshot_dir","screenshots") + '/' + @ll.scenario.timecode + '.jpg'
        @browser.driver.save_screenshot(fileloc)
        @ll.log.debug "Screenshot saved: #{fileloc}"
      rescue Exception => e
        @ll.log.debug "Failed to save screenshot. Error message #{e.message}"
      end
    end

    def method_missing(meth, *args, &block)
      if @browser.respond_to? meth
        return @browser.send(meth.to_s, *args, &block)
      end
      raise "Method Missing: #{meth}"
    end
  end
end