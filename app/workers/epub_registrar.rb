class EpubRegistrar
  @queue = :registry_queue
  class << self
    def perform(book_id)
      book =  Book.find(book_id)
      epub = EPUB::Parser.parse(book.location.url)
      epub.each_content do |content|
        next unless content.media_type == 'application/xhtml+xml'
        xhtml = content.read
        doc = Nokogiri.XML(xhtml)
        body = doc.search('body').first
        book.contents << Content.new(content: body.content)
      end
    end
  end
end
