delicious-links
===============

Due to questionable errors in accessing the links I've collected over
the past 8+ years in delicious.com, I've exported them and am making
a simple Ruby script which will convert the extract into Markdown.

The script is delicious-markdown.rb located peer to my delicious.html
file.

## Requirements ##

The following must be able to run in your Ruby install without error :

	require 'rubygems'
	require 'fileutils'
	require 'nokogiri'
	require 'ostruct'
	require 'set'


## Execution ##

The script takes either a named export file name or will default to
using `"delicious.html"` in the current directory.  *It replaces* the
`target/wiki` directory with the contents of what's in the export file.


## Example ##

See the wiki in this GitHub project :-).

