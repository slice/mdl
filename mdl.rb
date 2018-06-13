#!/usr/bin/env ruby

require 'uri'
require 'nokogiri'
require 'open-uri'

module Curseforge
  HOST = 'minecraft.curseforge.com'
  WEBSITE = 'https://' + HOST

  Mod = Struct.new(:id, :slug, :name, :description, :author, keyword_init: true) do
    def to_s
      "#{name} by #{author} (#{id})"
    end
  end

  Jar = Struct.new(:link, :name, :size, :uploaded, :uploaded_human, :mc_version, :downloads, keyword_init: true) do
    def to_s
      "#{name} for #{mc_version} (uploaded #{uploaded_human}, #{downloads} downloads, #{size})"
    end
  end

  def self.files(slug)
    doc = self.request("/projects/#{slug}/files")
    doc.css('tr.project-file-list-item').map do |file|
      twitch_link = file.css('.twitch-link').attr('href').value
      id = twitch_link[/\d+$/].to_i
      link = "#{WEBSITE}/projects/#{slug}/files/#{id}/download"

      # --- old download link grabber logic: wouldn't work for modpacks
      # link = file.css('.project-file-download-button a').attr('href').value
      # link = WEBSITE + link

      Jar.new(
        link: link,
        name: file.css('.twitch-link').text,
        size: file.css('.project-file-size').text.strip,
        uploaded_human: file.css('.project-file-date-uploaded abbr').text.strip,
        uploaded: Time.at(file.css('.project-file-date-uploaded abbr').attr('data-epoch').value.to_i),
        mc_version: file.css('.version-label').text,
        downloads: file.css('.project-file-downloads').text.gsub(',', '').to_i,
      )
    end
  end

  # Makes a request to Curseforge's website.
  def self.request(endpoint, query = {})
    uri = URI::HTTP.build(
      protocol: 'https',
      path: endpoint,
      host: HOST,
      query: URI.encode_www_form(query)
    )
    Nokogiri::HTML(open(uri.to_s))
  end

  def self.search(query)
    doc = self.request('/search', search: query)
    results = doc.css('table[class*=listing] tbody tr.results')
    results.map do |result|
      link = result.css('.results-name a')
      uri = URI(link.attr('href'))
      Mod.new(
        id: uri.query[/\d+/].to_i,
        slug: uri.path.split('/')[-1],
        name: link.text,
        description: result.css('.results-summary').text.strip,
        author: result.css('.results-owner a').text
      )
    end
  end
end

def download_interactive(uri, dest)
  require 'down'
  require 'tty-progressbar'

  bar = TTY::ProgressBar.new('Downloading. :eta remaining. [:bar] (:percent)') do |config|
    config.total = 20
    config.complete = '█'
    config.head = '█'
  end
  bar.start

  begin
    total = 0
    Down.download(uri, destination: dest,
      content_length_proc: -> (content_length) {
        total = content_length
      },
      progress_proc: -> (progress) {
        bar.ratio = progress / total unless progress.zero?
      },
      max_redirects: 10)
  rescue Down::ResponseError => error
    uri = URI(URI.escape(error.response['location']))
    retry
  end
end

if __FILE__ == $0
  require 'tty-prompt'
  prompt = TTY::Prompt.new

  loop do
    # --- search for a mod
    query = prompt.ask('Search:')
    mods = Curseforge.search(query)
    if mods.empty?
      puts 'No results.'
      next
    end

    # --- select a result
    mod = prompt.select('Choose a mod to download.') do |q|
      mods.each do |mod|
        q.choice(mod.to_s, mod)
      end
    end

    # --- select a file
    files = Curseforge.files(mod.slug)
    file = prompt.select('Choose a file.') do |q|
      files.sort_by { |file| file[:uploaded] }.reverse.each do |file|
        q.choice(file.to_s, file)
      end
    end

    puts("Downloading #{file.link} to #{file.name}.")
    download_interactive(URI(URI.escape(file.link)), file.name)

    break
  end
end
