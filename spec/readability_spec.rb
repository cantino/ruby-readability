# encoding: UTF-8

require 'spec_helper'
require 'readability'

describe Readability do
  before do
    @simple_html_fixture = <<-HTML
      <html>
        <head>
          <title>title!</title>
        </head>
        <body class='comment'>
          <div>
            <p class='comment'>a comment</p>
            <div class='comment' id='body'>real content</div>
            <div id="contains_blockquote"><blockquote>something in a table</blockquote></div>
          </div>
        </body>
      </html>
    HTML

    @simple_html_with_img_no_text = <<-HTML
    <html>
      <head>
        <title>title!</title>
      </head>
      <body class='main'>
        <div class="article-img">
          <img src="http://img.thesun.co.uk/multimedia/archive/01416/dim_1416768a.jpg">
        </div>
      </body>
      </html>
    HTML

    @simple_html_with_img_in_noscript = <<-HTML
    <html>
      <head>
        <title>title!</title>
      </head>
      <body class='main'>
        <div class="article-img">
        <img src="http://img.thesun.co.uk/multimedia/archive/00703/sign_up_emails_682__703711a.gif" width="660"
        height="317" alt="test" class="lazy"
        data-original="http://img.thesun.co.uk/multimedia/archive/01416/dim_1416768a.jpg">
        <noscript><img src="http://img.thesun.co.uk/multimedia/archive/01416/dim_1416768a.jpg"></noscript>
        </div>
      </body>
      </html>
    HTML
  end

  describe "images" do
    before do
      @bbc      = File.read(File.dirname(__FILE__) + "/fixtures/bbc.html")
      @nytimes  = File.read(File.dirname(__FILE__) + "/fixtures/nytimes.html")
      @thesun   = File.read(File.dirname(__FILE__) + "/fixtures/thesun.html")
      @ch       = File.read(File.dirname(__FILE__) + "/fixtures/codinghorror.html")
      @nested   = File.read(File.dirname(__FILE__) + "/fixtures/nested_images.html")

      FakeWeb::Registry.instance.clean_registry

      FakeWeb.register_uri(:get, "http://img.thesun.co.uk/multimedia/archive/01416/dim_1416768a.jpg",
                           :body => File.read(File.dirname(__FILE__) + "/fixtures/images/dim_1416768a.jpg"))

      FakeWeb.register_uri(:get, "http://img.thesun.co.uk/multimedia/archive/00703/sign_up_emails_682__703711a.gif",
                           :body => File.read(File.dirname(__FILE__) + "/fixtures/images/sign_up_emails_682__703711a.gif"))

      FakeWeb.register_uri(:get, "http://img.thesun.co.uk/multimedia/archive/00703/sign_up_emails_682__703712a.gif",
                           :body => File.read(File.dirname(__FILE__) + "/fixtures/images/sign_up_emails_682__703712a.gif"))

      # Register images for codinghorror
      FakeWeb.register_uri(:get, 'http://blog.codinghorror.com/content/images/2014/Sep/JohnPinhole.jpg',
                           :body => File.read(File.dirname(__FILE__) + "/fixtures/images/JohnPinhole.jpg"))
      FakeWeb.register_uri(:get, 'http://blog.codinghorror.com/content/images/2014/Sep/Confusion_of_Tongues.png',
                           :body => File.read(File.dirname(__FILE__) + "/fixtures/images/Confusion_of_Tongues.png"))
    end

    it "should show one image, but outside of the best candidate" do
      @doc = Readability::Document.new(@thesun)
      expect(@doc.images).to eq(["http://img.thesun.co.uk/multimedia/archive/01416/dim_1416768a.jpg", "http://img.thesun.co.uk/multimedia/archive/00703/sign_up_emails_682__703711a.gif", "http://img.thesun.co.uk/multimedia/archive/00703/sign_up_emails_682__703712a.gif"])
      expect(@doc.best_candidate_has_image).to eq(false)
    end

    it "should show one image inside of the best candidate" do
      @doc = Readability::Document.new(@nytimes)
      expect(@doc.images).to eq(["http://graphics8.nytimes.com/images/2011/12/02/opinion/02fixes-freelancersunion/02fixes-freelancersunion-blog427.jpg"])
      expect(@doc.best_candidate_has_image).to eq(true)
    end

    it "should expand relative image url" do
      url = 'http://blog.codinghorror.com/standard-flavored-markdown/'
      @doc = Readability::Document.new(@ch, tags: %w[div p img a],
                                            attributes: %w[src href],
                                            remove_empty_nodes: false)
      @doc.images_with_fqdn_uris!(url)

      expect(@doc.content).to include('http://blog.codinghorror.com/content/images/2014/Sep/JohnPinhole.jpg')
      expect(@doc.content).to include('http://blog.codinghorror.com/content/images/2014/Sep/Confusion_of_Tongues.png')

      expect(@doc.images).to match_array([
        'http://blog.codinghorror.com/content/images/2014/Sep/JohnPinhole.jpg',
        'http://blog.codinghorror.com/content/images/2014/Sep/Confusion_of_Tongues.png'
      ])
    end

    it "should be able to preserve deeply nested image tags in the article's content by whitelisting all tags" do
      @doc = Readability::Document.new(@nested, attributes: ["src"])
      expect(@doc.images).to be_empty

      @doc = Readability::Document.new(@nested, attributes: ["src"], tags: ["figure", "image"])
      expect(@doc.images).to be_empty

      @doc = Readability::Document.new(@nested, attributes: ["src"], tags: ["*"])
      expect(@doc.content).to include('<img src="http://example.com/image.jpeg" />')
    end

    it "should be able to whitelist all attributes" do
      @doc = Readability::Document.new(@nested, attributes: ["*"], tags: ["*"])
      expect(@doc.content).to include('<img src="http://example.com/image.jpeg" />')
    end

    it "should not try to download local images" do
      @doc = Readability::Document.new(<<-HTML)
        <html>
          <head>
            <title>title!</title>
          </head>
          <body class='comment'>
            <div>
              <img src="/something/local.gif" />
            </div>
          </body>
        </html>
      HTML
      expect(@doc).not_to receive(:get_image_size)
      expect(@doc.images).to eq([])
    end

    describe "no images" do
      it "shouldn't show images" do
        @doc = Readability::Document.new(@bbc, :min_image_height => 600)
        expect(@doc.images).to eq([])
        expect(@doc.best_candidate_has_image).to eq(false)
      end
    end

    describe "poll of images" do
      it "should show some images inside of the best candidate" do
        @doc = Readability::Document.new(@bbc)
        expect(@doc.images).to match_array(["http://news.bbcimg.co.uk/media/images/57027000/jpg/_57027794_perseus_getty.jpg",
                               "http://news.bbcimg.co.uk/media/images/57027000/jpg/_57027786_john_capes229_rnsm.jpg",
                               "http://news.bbcimg.co.uk/media/images/57060000/gif/_57060487_sub_escapes304x416.gif",
                               "http://news.bbcimg.co.uk/media/images/57055000/jpg/_57055063_perseus_thoctarides.jpg"])
        expect(@doc.best_candidate_has_image).to eq(true)
      end

      it "should show some images inside of the best candidate, include gif format" do
        @doc = Readability::Document.new(@bbc, :ignore_image_format => [])
        expect(@doc.images).to eq(["http://news.bbcimg.co.uk/media/images/57027000/jpg/_57027794_perseus_getty.jpg", "http://news.bbcimg.co.uk/media/images/57027000/jpg/_57027786_john_capes229_rnsm.jpg", "http://news.bbcimg.co.uk/media/images/57060000/gif/_57060487_sub_escapes304x416.gif", "http://news.bbcimg.co.uk/media/images/57055000/jpg/_57055063_perseus_thoctarides.jpg"])
        expect(@doc.best_candidate_has_image).to eq(true)
      end

      describe "width, height and format" do
        it "should show some images inside of the best candidate, but with width most equal to 400px" do
          @doc = Readability::Document.new(@bbc, :min_image_width => 400, :ignore_image_format => [])
          expect(@doc.images).to eq(["http://news.bbcimg.co.uk/media/images/57027000/jpg/_57027794_perseus_getty.jpg"])
          expect(@doc.best_candidate_has_image).to eq(true)
        end

        it "should show some images inside of the best candidate, but with width most equal to 304px" do
          @doc = Readability::Document.new(@bbc, :min_image_width => 304, :ignore_image_format => [])
          expect(@doc.images).to eq(["http://news.bbcimg.co.uk/media/images/57027000/jpg/_57027794_perseus_getty.jpg", "http://news.bbcimg.co.uk/media/images/57060000/gif/_57060487_sub_escapes304x416.gif", "http://news.bbcimg.co.uk/media/images/57055000/jpg/_57055063_perseus_thoctarides.jpg"])
          expect(@doc.best_candidate_has_image).to eq(true)
        end

        it "should show some images inside of the best candidate, but with width most equal to 304px and ignoring JPG format" do
          @doc = Readability::Document.new(@bbc, :min_image_width => 304, :ignore_image_format => ["jpg"])
          expect(@doc.images).to eq(["http://news.bbcimg.co.uk/media/images/57060000/gif/_57060487_sub_escapes304x416.gif"])
          expect(@doc.best_candidate_has_image).to eq(true)
        end

        it "should show some images inside of the best candidate, but with height most equal to 400px, no ignoring no format" do
          @doc = Readability::Document.new(@bbc, :min_image_height => 400, :ignore_image_format => [])
          expect(@doc.images).to eq(["http://news.bbcimg.co.uk/media/images/57060000/gif/_57060487_sub_escapes304x416.gif"])
          expect(@doc.best_candidate_has_image).to eq(true)
        end

        it "should not miss an image if it exists by itself in a div without text" do
          @doc = Readability::Document.new(@simple_html_with_img_no_text,:tags => %w[div p img a], :attributes => %w[src href], :remove_empty_nodes => false, :do_not_guess_encoding => true)
          expect(@doc.images).to eq(["http://img.thesun.co.uk/multimedia/archive/01416/dim_1416768a.jpg"])
        end

        it "should not double count an image between script and noscript" do
          @doc = Readability::Document.new(@simple_html_with_img_in_noscript,:tags => %w[div p img a], :attributes => %w[src href], :remove_empty_nodes => false, :do_not_guess_encoding => true)
          expect(@doc.images).to eq(["http://img.thesun.co.uk/multimedia/archive/00703/sign_up_emails_682__703711a.gif", "http://img.thesun.co.uk/multimedia/archive/01416/dim_1416768a.jpg"])
        end

      end
    end
  end

  describe "transformMisusedDivsIntoParagraphs" do
    before do
      @doc = Readability::Document.new(@simple_html_fixture)
      @doc.transform_misused_divs_into_paragraphs!
    end

    it "should transform divs containing no block elements into <p>s" do
      expect(@doc.html.css("#body").first.name).to eq("p")
    end

    it "should not transform divs that contain block elements" do
      expect(@doc.html.css("#contains_blockquote").first.name).to eq("div")
    end
  end

  describe "author" do
    it "should pick up <meta name='dc.creator'></meta> as an author" do
      doc = Readability::Document.new(<<-HTML)
        <html>
          <head>
            <meta name='dc.creator' content='Austin Fonacier' />
          </head>
          <body></body>
        </html>
      HTML
      expect(doc.author).to eql("Austin Fonacier")
    end

    it "should pick up readability's recommended author format" do
      doc = Readability::Document.new(<<-HTML)
        <html>
          <head>
          </head>
          <body>
            <p class="byline author vcard">
            By <cite class="fn">Austin Fonacier</span>
            </p>
          </body>
        </html>
      HTML
      expect(doc.author).to eql("Austin Fonacier")
    end

    it "should pick up vcard fn" do
      doc = Readability::Document.new(<<-HTML)
        <html>
          <head>
          </head>
          <body>
            <div class="author">By</div>
            <div class="author vcard">
              <a class="url fn" href="http://austinlivesinyotests.com/">Austin Fonacier</a>
            </div>
          </body>
        </html>
      HTML
      expect(doc.author).to eql("Austin Fonacier")
    end

    it "should pick up <a rel='author'>" do
      doc = Readability::Document.new(<<-HTML)
        <html>
          <head></head>
          <body>
            <a rel="author" href="http://google.com">Danny Banks (rel)</a>
          </body>
        </html>
      HTML
      expect(doc.author).to eql("Danny Banks (rel)")
    end

    it "should pick up <div id='author'>" do
      doc = Readability::Document.new(<<-HTML)
        <html>
          <head></head>
          <body>
            <div id="author">Austin Fonacier (author)</div>
          </body>
        </html>
      HTML
      expect(doc.author).to eql("Austin Fonacier (author)")
    end
  end

  describe "score_node" do
    before do
      @doc = Readability::Document.new(<<-HTML)
        <html>
          <body>
            <div id='elem1'>
              <p>some content</p>
            </div>
            <th id='elem2'>
              <p>some other content</p>
            </th>
          </body>
        </html>
      HTML
      @elem1 = @doc.html.css("#elem1").first
      @elem2 = @doc.html.css("#elem2").first
    end

    it "should like <div>s more than <th>s" do
      expect(@doc.score_node(@elem1)[:content_score]).to be > @doc.score_node(@elem2)[:content_score]
    end

    it "should like classes like text more than classes like comment" do
      @elem2.name = "div"
      expect(@doc.score_node(@elem1)[:content_score]).to eq(@doc.score_node(@elem2)[:content_score])
      @elem1['class'] = "text"
      @elem2['class'] = "comment"
      expect(@doc.score_node(@elem1)[:content_score]).to be > @doc.score_node(@elem2)[:content_score]
    end
  end

  describe "remove_unlikely_candidates!" do
    before do
      @doc = Readability::Document.new(@simple_html_fixture)
      @doc.remove_unlikely_candidates!
    end

    it "should remove things that have class comment" do
      expect(@doc.html.inner_html).not_to match(/a comment/)
    end

    it "should not remove body tags" do
      expect(@doc.html.inner_html).to match(/<\/body>/)
    end

    it "should not remove things with class comment and id body" do
      expect(@doc.html.inner_html).to match(/real content/)
    end
  end

  describe "score_paragraphs" do
    before(:each) do
      @doc = Readability::Document.new(<<-HTML)
        <html>
          <head>
            <title>title!</title>
          </head>
          <body id="body">
            <div id="div1">
              <div id="div2>
                <p id="some_comment">a comment</p>
              </div>
              <p id="some_text">some text</p>
            </div>
            <div id="div3">
              <p id="some_text2">some more text</p>
            </div>
          </body>
        </html><!-- " -->
      HTML
      @candidates = @doc.score_paragraphs(0)
    end

    it "should score elements in the document" do
      expect(@candidates.values.length).to eq(3)
    end

    it "should prefer the body in this particular example" do
      expect(@candidates.values.sort { |a, b|
        b[:content_score] <=> a[:content_score]
      }.first[:elem][:id]).to eq("body")
    end

    context "when two consequent br tags are used instead of p" do
      it "should assign the higher score to the first paragraph in this particular example" do
        @doc = Readability::Document.new(<<-HTML)
          <html>
            <head>
              <title>title!</title>
            </head>
            <body id="body">
              <div id="post1">
                This is the main content!<br/><br/>
                Zebra found killed butcher with the chainsaw.<br/><br/>
                If only I could think of an example, oh, wait.
              </div>
              <div id="post2">
                This is not the content and although it's longer if you meaure it in characters,
                it's supposed to have lower score than the previous paragraph. And it's only because
                of the previous paragraph is not one paragraph, it's three subparagraphs
              </div>
            </body>
          </html>
        HTML
        @candidates = @doc.score_paragraphs(0)
        expect(@candidates.values.sort_by { |a| -a[:content_score] }.first[:elem][:id]).to eq('post1')
      end
    end

    it "does not include short paragraphs as related siblings in the output" do
      @doc = Readability::Document.new(<<-HTML, min_text_length: 1, elements_to_score: ["h1", "p"])
        <html>
          <head>
            <title>title!</title>
          </head>
          <body>
            <section>
              <p>Paragraph 1</p>
              <p>Paragraph 2</p>
            </section>
            <section>
              <p>Too short</p>
            </section>
            #{'<a href="/">This link lowers the body score.</a>' * 5}
          </body>
        </html>
      HTML

      expect(@doc.content).to include("Paragraph 1")
      expect(@doc.content).to include("Paragraph 2")
      expect(@doc.content).not_to include("Too short")
    end

    it "includes long paragraphs as related siblings in the output" do
      @doc = Readability::Document.new(<<-HTML, min_text_length: 1, elements_to_score: ["h1", "p"])
        <html>
          <head>
            <title>title!</title>
          </head>
          <body>
            <section>
              <p>Paragraph 1</p>
              <p>Paragraph 2</p>
            </section>
            <p>This paragraph is longer than 80 characters so should be included as a sibling in the output.</p>
            #{'<a href="/">This link lowers the body score.</a>' * 5}
          </body>
        </html>
      HTML

      expect(@doc.content).to include("Paragraph 1")
      expect(@doc.content).to include("Paragraph 2")
      expect(@doc.content).to include("This paragraph is longer")
    end

    it "does not include non-paragraph tags in the output, even when longer than 80 characters" do
      @doc = Readability::Document.new(<<-HTML, min_text_length: 1, elements_to_score: ["h1", "p"])
        <html>
          <head>
            <title>title!</title>
          </head>
          <body>
            <section>
              <p>Paragraph 1</p>
              <p>Paragraph 2</p>
            </section>
            <section>
              <p>Although this paragraph is longer than 80 characters, the sibling is the section so it should not be included.</p>
            </section>
            #{'<a href="/">This link lowers the body score.</a>' * 5}
          </body>
        </html>
      HTML

      expect(@doc.content).to include("Paragraph 1")
      expect(@doc.content).to include("Paragraph 2")
      expect(@doc.content).not_to include("Although this paragraph")
    end

    it "does include non-paragraph tags in the output if their content score is high enough" do
      @doc = Readability::Document.new(<<-HTML, min_text_length: 1, elements_to_score: ["h1", "p"])
        <html>
          <head>
            <title>title!</title>
          </head>
          <body>
            <section>
              <p>Paragraph 1</p>
              #{'<p>Paragraph 2</p>' * 10} <!-- Ensure this section remains the best_candidate. -->
            </section>
            <section>
              <p>This should be included in the output because the content is score is high enough.<p>
              <p>The, inclusion, of, lots, of, commas, increases, the, score, of, an, element.</p>
            </section>
            #{'<a href="/">This link lowers the body score.</a>' * 5}
          </body>
        </html>
      HTML

      expect(@doc.content).to include("Paragraph 1")
      expect(@doc.content).to include("Paragraph 2")
      expect(@doc.content).to include("This should be included")
    end

    it "can optionally include other related siblings in the output if they meet the 80 character threshold" do
      @doc = Readability::Document.new(<<-HTML, min_text_length: 1, elements_to_score: ["h1", "p"], likely_siblings: ["section"])
        <html>
          <head>
            <title>title!</title>
          </head>
          <body>
            <section>
              <p>Paragraph 1</p>
              #{'<p>Paragraph 2</p>' * 10} <!-- Ensure this section remains the best_candidate. -->
            </section>
            <section>
              <p>This paragraph is longer than 80 characters and inside a section that is a sibling of the best_candidate.</p>
              <p>The likely_siblings now include the section tag so it should be included in the output.</p>
            </section>
            #{'<a href="/">This link lowers the body score.</a>' * 5}
          </body>
        </html>
      HTML

      expect(@doc.content).to include("Paragraph 1")
      expect(@doc.content).to include("Paragraph 2")
      expect(@doc.content).to include("should be included")
    end
  end

  describe "the cant_read.html fixture" do
    it "should work on the cant_read.html fixture with some allowed tags" do
      allowed_tags = %w[div span table tr td p i strong u h1 h2 h3 h4 pre code br a]
      allowed_attributes = %w[href]
      html = File.read(File.dirname(__FILE__) + "/fixtures/cant_read.html")
      expect(Readability::Document.new(html, :tags => allowed_tags, :attributes => allowed_attributes).content).to match(/Can you talk a little about how you developed the looks for the/)
    end
  end

  describe "general functionality" do
    before do
      @doc = Readability::Document.new("<html><head><title>title!</title></head><body><div><p>Some content</p></div></body>",
                                       :min_text_length => 0, :retry_length => 1)
    end

    it "should return the main page content" do
      expect(@doc.content).to match("Some content")
    end

    it "should return the page title if present" do
      expect(@doc.title).to match("title!")

      doc = Readability::Document.new("<html><head></head><body><div><p>Some content</p></div></body>",
                                       :min_text_length => 0, :retry_length => 1)
      expect(doc.title).to be_nil
    end
  end

  describe "ignoring sidebars" do
    before do
      @doc = Readability::Document.new("<html><head><title>title!</title></head><body><div><p>Some content</p></div><div class='sidebar'><p>sidebar<p></div></body>",
                                       :min_text_length => 0, :retry_length => 1)
    end

    it "should not return the sidebar" do
      expect(@doc.content).not_to match("sidebar")
    end
  end

  describe "inserting space for block elements" do
    before do
      @doc = Readability::Document.new(<<-HTML, :min_text_length => 0, :retry_length => 1)
        <html><head><title>title!</title></head>
          <body>
            <div>
              <p>a<br>b<hr>c<address>d</address>f/p>
            </div>
          </body>
        </html>
      HTML
    end

    it "should not return the sidebar" do
      expect(@doc.content).not_to match("a b c d f")
    end
  end

  describe "outputs good stuff for known documents" do
    before do
      @html_files = Dir.glob(File.dirname(__FILE__) + "/fixtures/samples/*.html")
      @samples = @html_files.map {|filename| File.basename(filename, '.html') }
    end

    it "should output expected fragments of text" do
      checks = 0
      @samples.each do |sample|
        html = File.read(File.dirname(__FILE__) + "/fixtures/samples/#{sample}.html")
        doc = Readability::Document.new(html).content

        load "fixtures/samples/#{sample}-fragments.rb"
        #puts "testing #{sample}..."

        $required_fragments.each do |required_text|
          expect(doc).to include(required_text)
          checks += 1
        end

        $excluded_fragments.each do |text_to_avoid|
          expect(doc).not_to include(text_to_avoid)
          checks += 1
        end
      end
      #puts "Performed #{checks} checks."
    end
  end

  describe "encoding guessing" do
    if RUBY_VERSION =~ /^1\.9\./
      context "with ruby 1.9.2" do
        it "should correctly guess and enforce HTML encoding" do
          doc = Readability::Document.new("<html><head><meta http-equiv='content-type' content='text/html; charset=LATIN1'></head><body><div>hi!</div></body></html>")
          content = doc.content
          expect(content.encoding.to_s).to eq("ISO-8859-1")
          expect(content).to be_valid_encoding
        end

        it "should allow encoding guessing to be skipped" do
          expect(GuessHtmlEncoding).to_not receive(:encode)
          doc = Readability::Document.new(@simple_html_fixture, :do_not_guess_encoding => true)
          doc.content
        end

        it "should allow encoding guessing to be overridden" do
          expect(GuessHtmlEncoding).to_not receive(:encode)
          doc = Readability::Document.new(@simple_html_fixture, :encoding => "UTF-8")
          doc.content
        end
      end
    end
  end

  describe "#make_html" do
    it "should strip the html comments tag" do
      doc = Readability::Document.new("<html><head><meta http-equiv='content-type' content='text/html; charset=LATIN1'></head><body><div>hi!<!-- bye~ --></div></body></html>")
      content = doc.content
      expect(content).to include("hi!")
      expect(content).not_to include("bye")
    end

    it "should not error with empty content" do
      expect(Readability::Document.new('').content).to eq('<div><div></div></div>')
    end

    it "should not error with a document with no <body>" do
      expect(Readability::Document.new('<html><head><meta http-equiv="refresh" content="0;URL=http://example.com"></head></html>').content).to eq('<div><div></div></div>')
    end
  end

  describe "No side-effects" do
    before do
      @bbc      = File.read(File.dirname(__FILE__) + "/fixtures/bbc.html")
      @nytimes  = File.read(File.dirname(__FILE__) + "/fixtures/nytimes.html")
      @thesun   = File.read(File.dirname(__FILE__) + "/fixtures/thesun.html")
    end

    it "should not have any side-effects when calling content() and then images()" do
      @doc=Readability::Document.new(@nytimes, :tags => %w[div p img a], :attributes => %w[src href], :remove_empty_nodes => false,
      :do_not_guess_encoding => true)
      expect(@doc.images).to eq(["http://graphics8.nytimes.com/images/2011/12/02/opinion/02fixes-freelancersunion/02fixes-freelancersunion-blog427.jpg"])
      @doc.content
      expect(@doc.images).to eq(["http://graphics8.nytimes.com/images/2011/12/02/opinion/02fixes-freelancersunion/02fixes-freelancersunion-blog427.jpg"])
    end

    it "should not have any side-effects when calling content() multiple times" do
       @doc=Readability::Document.new(@nytimes, :tags => %w[div p img a], :attributes => %w[src href], :remove_empty_nodes => false,
        :do_not_guess_encoding => true)
       expect(@doc.content).to eq(@doc.content)
    end

    it "should not have any side-effects when calling content and images multiple times" do
       @doc=Readability::Document.new(@nytimes, :tags => %w[div p img a], :attributes => %w[src href], :remove_empty_nodes => false,
        :do_not_guess_encoding => true)
       expect(@doc.images).to eq(["http://graphics8.nytimes.com/images/2011/12/02/opinion/02fixes-freelancersunion/02fixes-freelancersunion-blog427.jpg"])
       expect(@doc.content).to eq(@doc.content)
       expect(@doc.images).to eq(["http://graphics8.nytimes.com/images/2011/12/02/opinion/02fixes-freelancersunion/02fixes-freelancersunion-blog427.jpg"])
    end

  end

  describe "Code blocks" do
    before do
      @code = File.read(File.dirname(__FILE__) + "/fixtures/code.html")
      @content  = Readability::Document.new(@code,
                                        :tags => %w[div p img a ul ol li h1 h2 h3 h4 h5 h6 blockquote strong em b code pre],
                                        :attributes => %w[src href],
                                        :remove_empty_nodes => false).content
      @doc = Nokogiri::HTML(@content)
    end

    it "preserve the code blocks" do
      expect(@doc.css("code pre").text).to eq("\nroot\n  indented\n    ")
    end

    it "preserve backwards code blocks" do
      expect(@doc.css("pre code").text).to eq("\nsecond\n  indented\n    ")
    end
  end

  describe "remove all tags" do
    it "should work for an incomplete piece of HTML" do
      doc = Readability::Document.new('<div>test</div', :tags => [])
      expect(doc.content).to eq('test')
    end

    it "should work for a HTML document" do
      doc = Readability::Document.new('<html><head><title>title!</title></head><body><div><p>test</p></div></body></html>',
                                      :tags => [])
      expect(doc.content).to eq('test')
    end

    it "should work for a plain text" do
      doc = Readability::Document.new('test', :tags => [])
      expect(doc.content).to eq('test')
    end
  end

  describe "boing boing" do
    let(:boing_boing) {
      File.read(File.dirname(__FILE__) + "/fixtures/boing_boing.html")
    }

    it "contains incorrect data by default" do
      # NOTE: in an ideal world this spec starts failing
      #  and readability correctly detects content for the
      #  boing boing sample.

      doc = Readability::Document.new(boing_boing)

      content = doc.content
      expect(content !~ /Bees and Bombs/).to eq(true)
      expect(content).to match(/ADVERTISE/)
    end

    it "should apply whitelist" do

      doc = Readability::Document.new(boing_boing,
                                      whitelist: ".post-content")
      content = doc.content
      expect(content).to match(/Bees and Bombs/)
    end

    it "should apply blacklist" do
      doc = Readability::Document.new(boing_boing, blacklist: "#sidebar_adblock")
      content = doc.content
      expect(content !~ /ADVERTISE/).to eq(true)

    end
  end

  describe "clean_conditionally_reason?" do
    let (:list_fixture) { "<div><p>test</p>#{'<li></li>' * 102}" }

    it "does not raise error" do
      @doc = Readability::Document.new(list_fixture)
      expect { @doc.content }.to_not raise_error
    end
  end

  describe "debug" do
    it "can set a debug function, e.g. to send output to Rails logger" do
      output = []
      debug_fn = lambda { |str| output << str }

      Readability::Document.new(@simple_html_fixture, debug: debug_fn).content
      expect(output).not_to be_empty
    end
  end
end
