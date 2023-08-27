require "marcel"

class ContentType
  def initialize(path)
    @content_type = Marcel::MimeType.for(path)
  end

  def image?
    content_type.start_with?("image/")
  end

  attr_reader :content_type
end
