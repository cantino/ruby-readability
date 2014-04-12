class AuthorsFinder

  AUTHOR_PATTERNS = [
    '//*[contains(@class, "vcard")]//*[contains(@class, "fn")]',
    '//a[@rel = "author"]',
    '//*[@id = "author"]'
  ].freeze

  attr_reader :doc

  def initialize(doc)
    @doc = doc.is_a?(String) ? Nokogiri::HTML(doc) : doc
  end

  def author
    @authors ||= find_possible_authors
    @authors.first
  end

  def find_possible_authors
    authors = []
    authors += find_authors_from_meta_tag
    authors += find_authors_from_patterns
  end

  private

  def find_authors_from_meta_tag
    # <meta name="dc.creator" content="Finch - http://www.getfinch.com" />
    author_elements = @doc.xpath('//meta[@name = "dc.creator"]')
    author_elements.inject([]) { |authors, element| authors << element['content'].strip if element['content'] }
  end

  def find_authors_from_patterns
    # <span class="byline author vcard"><span>By</span><cite class="fn">Austin Fonacier</cite></span>
    # <div class="author">By</div><div class="author vcard"><a class="url fn" href="http://austinlivesinyoapp.com/">Austin Fonacier</a></div>
    # <a rel="author" href="http://dbanksdesign.com">Danny Banks (rel)</a>
    # TODO: strip out the (rel)?
    AUTHOR_PATTERNS.inject([]) do |authors, pattern|
      author_elements = @doc.xpath(pattern)
      author_elements.each { |element| authors << element.text.strip if element.text }
      authors
    end
  end

end