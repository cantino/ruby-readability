# Ruby Readability

Ruby Readability is a tool for extracting the primary readable content of a webpage.  It is a Ruby port of arc90's readability project.

## Install

Command line:

    (sudo) gem install ruby-readability

Bundler:

    gem "ruby-readability", :require => 'readability'

## Example

    require 'rubygems'
    require 'readability'
    require 'open-uri'

    source = open('http://lab.arc90.com/experiments/readability/').read
    puts Readability::Document.new(source).content

## Options

You may provide options to Readability::Document.new, including:

    :tags                - the base whitelist of tags to sanitize, defaults to %w[div p]
    :remove_empty_nodes  - remove <p> tags that have no text content; also removes p tags that contain only images
    :attributes          - whitelist of allowed attributes
    :debug               - provide debugging output, defaults false
    :encoding            - if the page is of a known encoding, you can specify it; if left unspecified,
                           the encoding will be guessed (only in Ruby 1.9.x).  If you wish to disable guessing,
                           supply :do_not_guess_encoding => true.
    :html_headers        - in Ruby 1.9.x these will be passed to the guess_html_encoding gem
                           to aid with guessing the HTML encoding
    :ignore_image_format - for use with .images.  For example: :ignore_image_format => ["gif", "png"]
    :min_image_height    - set a minimum image height for .images
    :min_image_width     - set a minimum image width for .images

## Command Line Tool

Readability comes with a command-line tool for experimentation in bin/readability.

    Usage: readability [options] URL
        -d, --debug                      Show debug output
        -i, --images                     Keep images and links
        -h, --help                       Show this message

## Images

You can get a list of images in the content area with `.images`.  This feature requires that the `mini_magick` gem be installed    

    rbody = Readability::Document.new(body, :tags => %w[div p img a], :attributes => %w[src href], :remove_empty_nodes => false)
    rbody.images

## Potential Issues

If you're on a Mac and are getting segmentation faults, see the discussion at https://github.com/sparklemotion/nokogiri/issues/404 and consider updating your version of libxml2.  Version 2.7.8 of libxml2, installed with `brew`, worked for me:

    gem install nokogiri -- --with-xml2-include=/usr/local/Cellar/libxml2/2.7.8/include/libxml2 --with-xml2-lib=/usr/local/Cellar/libxml2/2.7.8/lib --with-xslt-dir=/usr/local/Cellar/libxslt/1.1.26

Or if you're using bundler and Rails 3, you can run this command to make bundler always globally build `nokogiri` this way

    bundle config build.nokogiri -- --with-xml2-include=/usr/local/Cellar/libxml2/2.7.8/include/libxml2 --with-xml2-lib=/usr/local/Cellar/libxml2/2.7.8/lib --with-xslt-dir=/usr/local/Cellar/libxslt/1.1.26

# Change Log

 * Version 0.5.1, released 3/13/2012 - The `ignore_image_format` option now defaults to an empty array, no longer excluding gif files by default.  MiniMagic fetches are no longer attempted on local images.

# License

This code is under the Apache License 2.0.  http://www.apache.org/licenses/LICENSE-2.0

Ruby port by starrhorne, libc, and iterationlabs.  Special thanks to fizx and marcosinger.
