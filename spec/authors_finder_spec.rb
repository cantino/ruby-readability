# encoding: UTF-8

require 'spec_helper'
require 'authors_finder'

describe AuthorsFinder do

  describe '.new' do
    let(:string_doc) { "<html></html>" }
    context 'doc arg. is String' do
      subject { AuthorsFinder.new(string_doc) }
      its(:doc) { should be_a Nokogiri::HTML::Document }
    end
    context 'doc arg. is Nokogiri doc' do
      let(:nokogiri_doc) { Nokogiri::HTML(string_doc) }
      subject { AuthorsFinder.new(string_doc) }
      its(:doc) { should be_a Nokogiri::HTML::Document }
    end
  end

  describe "author" do
    context 'meta tag in HTML' do
      let(:html) { File.read(File.dirname(__FILE__) + "/fixtures/author_in_meta_tag.html") }
      subject { AuthorsFinder.new(html) }
      its(:author) { should eql("Austin Fonacier") }
    end

    context 'recommended author format' do
      let(:html) { File.read(File.dirname(__FILE__) + "/fixtures/author_format.html") }
      subject { AuthorsFinder.new(html) }
      its(:author) { should eql("Austin Fonacier") }
    end

    context 'vcard fn' do
      let(:html) { File.read(File.dirname(__FILE__) + "/fixtures/author_vcard.html") }
      subject { AuthorsFinder.new(html) }
      its(:author) { should eql("Austin Fonacier") }
    end

    context 'a rel=author' do
      let(:html) { File.read(File.dirname(__FILE__) + "/fixtures/author_rel.html") }
      subject { AuthorsFinder.new(html) }
      its(:author) { should eql("Danny Banks (rel)") }
    end

    context 'div id=author' do
      let(:html) { File.read(File.dirname(__FILE__) + "/fixtures/author_div.html") }
      subject { AuthorsFinder.new(html) }
      its(:author) { should eql("Austin Fonacier (author)") }
    end
  end

  describe 'find_possible_authors' do
    let(:html) { File.read(File.dirname(__FILE__) + "/fixtures/authors.html") }
    subject { AuthorsFinder.new(html) }
    it do
      expect(subject.find_possible_authors.size).to eql(3)
    end
  end

end