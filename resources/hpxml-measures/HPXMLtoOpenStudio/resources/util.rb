# frozen_string_literal: true

# Adapted from https://stackoverflow.com/questions/6934185/ruby-net-http-following-redirects.
module UrlResolver
  # Fetch specified outfile from specified uri_str.
  #
  # @param uri_str [String] uniform resource identifier string
  # @param outfile [Tempfile] instance of a class for managing temporary files
  # @param agent [String] a string of text that a web browser sends to a web server to identify itself and provide information about the browser's capabilities
  # @param max_attempts [Integer] the maximum number of attempts
  # @param timeout [Integer] both the number of seconds to (1) wait for the connection to open and (2) wait for one block to be read (via one read(2) call)
  # @return [nil]
  def self.fetch(uri_str, outfile, agent = 'curl/7.43.0', max_attempts = 10, timeout = 10)
    attempts = 0
    cookie = nil

    until attempts >= max_attempts
      attempts += 1

      url = URI.parse(uri_str)
      http = Net::HTTP.new(url.host, url.port)
      http.open_timeout = timeout
      http.read_timeout = timeout
      path = url.path
      path = '/' if path == ''
      path += '?' + url.query unless url.query.nil?

      params = { 'User-Agent' => agent, 'Accept' => '*/*' }
      params['Cookie'] = cookie unless cookie.nil?
      request = Net::HTTP::Get.new(path, params)

      if url.instance_of?(URI::HTTPS)
        require 'openssl'
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end

      http.request request do |response|
        case response
        when Net::HTTPSuccess then
          total = response.header['Content-Length'].to_i
          if total == 0
            fail 'Did not successfully download zip file.'
          end

          size = 0
          progress = 0
          open outfile, 'wb' do |io|
            response.read_body do |chunk|
              io.write chunk
              size += chunk.size
              new_progress = (size * 100) / total
              unless new_progress == progress
                puts 'Downloading %s (%3d%%) ' % [url.path, new_progress]
              end
              progress = new_progress
            end
          end
          return
        when Net::HTTPRedirection then
          location = response['Location']
          cookie = response['Set-Cookie']
          new_uri = URI.parse(location)
          uri_str = if new_uri.relative?
                      url + location
                    else
                      new_uri.to_s
                    end
        else
          raise 'Unexpected response: ' + response.inspect
        end
      end

    end
    raise 'Too many http redirects' if attempts == max_attempts
  end
end

# Collection of methods related to file paths.
module FilePath
  # Check the existence of an absolute file path, or a file path relative a given directory.
  #
  # @param path [String] the file path to check
  # @param relative_dir [String] relative directory for which to check file path against
  # @param name [String] the name to report in case file path does not exist
  # @return [String] the absolute file path if it exists
  def self.check_path(path, relative_dir, name)
    return if path.nil?
    return File.absolute_path(path) if File.exist? path

    filepath = File.expand_path(File.join(relative_dir, path))
    if not File.exist? filepath
      fail "#{name} file path '#{path}' does not exist."
    end

    return File.absolute_path(filepath)
  end
end
