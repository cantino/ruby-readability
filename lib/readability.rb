require 'rubygems'
require 'nokogiri'

module Readability
  class Document

    def initialize(input, options = {})
      @options = options
      @html = Nokogiri::HTML(input, nil, 'UTF-8')
    end


    def content

      # Get all parent elements containing a <p> tag
      @parents = @html.css("p").map { |p| p.parent }.compact.uniq

      sanitize(@parents.map { |p| [p, score(p)] }.max { |a, b| a[1] <=> b[1] }[0])

    end

    def score(parent)
      s = 0

      # Adjust score based on parent's "class" attribute
      s -= 50 if parent[:class] =~ /(comment|meta|footer|footnote)/i
      s += 25 if parent[:class] =~ /((^|\s)(post|hentry|entry[-]?(content|text|body)?|article[-]?(content|text|body)?)(\s|$))/i

      # Adjust score based on parent id
      s -= 50 if parent[:id] =~ /(comment|meta|footer|footnote)/i
      s += 25 if parent[:id] =~ /^(post|hentry|entry[-]?(content|text|body)?|article[-]?(content|text|body)?)$/i

      # Adjust score based on # of <p> elements inside parent
      s += parent.css("p").size

      # Adjust score based on # of commas inside parent
      s += parent.text.count ","

      s
    end

    def sanitize(node)

      # Get rid of divs full of non-text items
      node.css("div").each do |el|
        counts = %w[p img li a embed].inject({}) { |m, kind| m[kind] = el.css(kind).length; m }
        el.remove if (el.text.count(",") < 10) && (counts["p"] == 0 || counts["embed"] > 0 || counts["a"] > counts["p"] || counts["li"] > counts["p"] || counts["img"] > counts["p"])
      end

      # We'll sanitize all elements using a whitelist
      whitelist = @options[:tags] || %w[div p]

      # Use a hash for speed (don't want to make a million calls to include?)
      whitelist = Hash[ whitelist.zip([true] * whitelist.size) ]

      ([node] + node.css("*")).each do |el|

        # If element is in whitelist, delete all its attributes
        if whitelist[el.node_name]
          el.attributes.each { |a, x| el.delete(a) unless @options[:attributes] && @options[:attributes].include?(a.to_s) }

        # Otherwise, replace the element with its contents
        else
          el.swap(el.text)
        end

      end

      # Get rid of duplicate whitespace
      node.to_html.gsub(/[\r\n\f]+/, "\n" ).gsub(/[\t ]+/, " ").gsub(/&nbsp;/, " ")
    end

  end
end
