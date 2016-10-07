require "tilt/erubis"
require "sinatra"
require "sinatra/reloader" if development?

before do
  @contents = File.readlines('data/toc.txt')
end

helpers do
  def in_paragraphs(text)
    par_num = 0
    pars = text.split("\n\n")
    pars.map! do |par|
      par_num += 1
      "<p id='#{par_num}'>" + par + "</p>"
    end
    pars.join
  end

  def highlighted(text, query)
    #text.gsub(query, "<b>#{query}</b>")
    pattern = Regexp.new(query, Regexp::IGNORECASE)
    text.gsub(pattern, '<b>\0</b>')
  end
end

def get_chapters(&block)
  @contents.each_with_index do |name, idx|
    number = idx + 1
    text = File.read("data/chp#{number}.txt")
    yield name, number, text
  end
end

def chapter_match(query)
  output = []
  return output unless query

  get_chapters do |name, number, text|
    next unless text.downcase.include?(query.downcase)
    par_match = { name: name, number: number, matches: {} }
    pars = text.split("\n\n")
    pars.each_with_index do |par, idx|
      if par.downcase.include?(query.downcase)
        par_match[:matches][idx + 1] = "#{par}"
      end
    end
    output << par_match
  end

  output
end

get "/" do
  @title = 'The Adventures of Sherlock Holmes'

  erb :home
end

get "/chapter/:number" do
  num = params[:number].to_i
  redirect "/" unless (1..@contents.size).include?(num)

  @title = "Chapter #{num}:  " + @contents[num - 1]
  @chapter = File.read("data/chp#{num}.txt")

  erb :chapter
end

get "/search" do
  @results = chapter_match(params[:query])

  erb :search
end

not_found do
  redirect "/"
end
