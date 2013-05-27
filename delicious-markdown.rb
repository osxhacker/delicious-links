#!/usr/bin/env ruby
# @(#) Script to convert a Delicious.com export into Markdown files
#

require 'rubygems'

require 'fileutils'
require 'nokogiri'
require 'ostruct'
require 'set'


class String
  def unindent 
    gsub(/^#{scan(/^\s*/).min_by{|l|l.length}}/, "")
  end
end


class DeliciousLink
	attr_accessor :title, :tags, :href, :description, :added

	def initialize(title, href, tags, added)
		@title = title;
		@href = href;
		@tags = tags.gsub('"', '').split(/,/);
		@added = added;
	end

	def ==(other_link)
		href == other_link.href;
	end

	def to_markdown
		"[#{title}](#{href}) #{description}\n"
	end

	def to_s
		"title=#{title} href=#{href} tags=#{tags}";
	end
end

class TaggedLinks
	attr_accessor :category, :links

	def initialize(category)
		@category = category.sub(/^\./, 'Dot-');
		@links = [];
	end

	def ==(other_tagged)
		category == other_tagged.category;
	end

	def filename
		"#{category}.md";
	end

	def formatted_links
		sorted = links.sort do |a, b|
			a.title.downcase <=> b.title.downcase;
		end

		sorted.collect do |l|
			l.to_markdown
		end.join("\n");
	end

	def to_markdown
		header = <<-EOT.unindent
			#{category}
			#{'=' * category.length}
			EOT

		header + "\n\n" + formatted_links;
	end

	def to_s
		"category=#{category} links=#{links}";
	end

	def self.empty_hash
		Hash.new do |h, k|
			h[k] = TaggedLinks.new(k) unless (h.include?(k));
		end
	end
end

class Wiki
	def self.create
		if (Dir.exists? location)
			Dir.new(location).each do |file|
				File.delete("#{location}/#{file}") unless (File.directory? file);
			end
		else
			FileUtils.mkdir_p location;
		end
	end

	def self.exists?
		Dir.exists? location;
	end

	def self.location
		"target/wiki"
	end

	def self.file(base_name)
		name = location + "/" + base_name;

		File.open(name, "w") do |fd|
			yield fd;
		end
	end
end


########################################################################
# main
########################################################################
source = ARGV[0] || "delicious.html";
export = Nokogiri::HTML(open(source));

# First thing to do is get the links and any optional descriptions from
# the Delicious raw HTML.
definitions = export.xpath('//a | //dd').inject(
	OpenStruct.new ({ :links => Set.new, :prior => nil })
	) do |state, candidate|
	case candidate.name
	when 'a'
		state.prior = DeliciousLink.new(
			candidate.text(),
			candidate['href'],
			candidate['tags'],
			candidate['add_date']
			);
		state.links.add(state.prior);
	when 'dd'
		state.prior.description = candidate.text
	end

	state;
end.links;


# Now, pivot the definitions on the tags so we can produce a file
# for each one.
categories = definitions.inject(TaggedLinks.empty_hash) do |accum, link|
	link.tags.each do |tag|
		accum[tag].links << link;
	end

	accum;
end.values;


# Finally, send each category to its own markdown file.
Wiki.create;

categories.each do |group|
	Wiki.file(group.filename) do |fd|
		fd << group.to_markdown
	end
end

