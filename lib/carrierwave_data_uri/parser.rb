require 'data_uri'

module CarrierWave
  module DataUri
    class Parser
      attr_reader :type, :encoder, :data, :extension

      DATA_REGEXP          = /data:/
      MEDIA_TYPE_REGEXP    = /[-\w.+]+\/[-\w.+]+(;[-\w.+]+=[^;,]+)*/
      BASE64_REGEXP        = /;base64/
      CONTENT_SEPARATOR    = /,/
      DEFAULT_CONTENT_TYPE = "text/plain"

      def initialize(data_uri)
        scanner = StringScanner.new(data_uri)
        scanner.scan(DATA_REGEXP) or raise ParseError, "data URI has invalid format"
        media_type = scanner.scan(MEDIA_TYPE_REGEXP)
        base64 = scanner.scan(BASE64_REGEXP)
        scanner.scan(CONTENT_SEPARATOR) or raise ParseError, "data URI has invalid format"
        content_type = media_type[/^[^;]+/] if media_type
        params = media_type.split(';')[1..-1].map { |param| param.split('=') }.to_h

        @type = content_type
        @extension = @type.split('/')[1]
        @data = Base64.decode64(scanner.post_match)
        @original_filename = params['name']
      rescue URI::InvalidURIError
        raise InvalidData, 'Cannot parse data'
      end

      def binary_data
        @data
      end

      def to_file(options = {})
        @file ||= begin
          file = Tempfile.new ['data_uri_upload', ".#{extension}"]
          file.binmode
          file << binary_data
          file.rewind
          file.original_filename = options[:original_filename] || @original_filename
          file.content_type = options[:content_type] || @type
          file
        end
      end
    end

    class InvalidData < StandardError; end
  end
end
