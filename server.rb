require 'sinatra'
require 'yaml'
require 'curb'

# If there is a file, we set env variables (QUICK HACK)
begin
  config = YAML.load(IO.read('config.yml'))
  config.each { |k, v| ENV[k] = v }
rescue
end

get '/' do
  send_file 'index.html'
end

post '/isbn' do
  # do the API search
  http = Curl.get("https://www.googleapis.com/books/v1/volumes?q=isbn:#{params[:isbn]}&key=#{ENV['GOOGLE_BOOKS_API_KEY']}")

  # deal with the data we got
  response = JSON.parse(http.body_str)
  book = response['items'].first
  isbn_10 = nil
  isbn_13 = nil
  book['volumeInfo']['industryIdentifiers'].each do |h|
    if h['type'] == 'ISBN_10'
      isbn_10 = h['identifier']
    elsif h['type'] == 'ISBN_13'
      isbn_13 = h['identifier']
    end
  end
  puts JSON.pretty_generate(book)

  # give it back to the frontend
  content_type :json
  {
    num: response['totalItems'],
    google_books_id: book['id'],
    title: book['volumeInfo']['title'],
    authors: book['volumeInfo']['authors'],
    date: book['volumeInfo']['publishedDate'],
    isbn_10: isbn_10,
    isbn_13: isbn_13,
    pages: book['volumeInfo']['pageCount'],
    image_link: book['volumeInfo']['imageLinks']['thumbnail']
  }.to_json
end