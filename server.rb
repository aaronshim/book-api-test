require 'sinatra'
require 'yaml'
require 'curb'

# error handling
set :show_exceptions, :after_handler

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

  begin
    # deal with the data we got
    response = JSON.parse(http.body_str)
    puts http.body_str # hopefully we can see the response code?
    if response['totalItems'] == 0
      # try one more search, but without the isbn keyword bound
      response = JSON.parse(Curl.get("https://www.googleapis.com/books/v1/volumes?q=#{params[:isbn]}&key=#{ENV['GOOGLE_BOOKS_API_KEY']}").body_str)
    end
    raise 'No items found' if response['totalItems'] == 0
    raise "API returned an error: #{response['error']['message']}" if response['error']
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
    unless isbn_10 == params[:isbn] || isbn_13 == params[:isbn]
      isbn_10 += ' (DIFFERENT)'
      isbn_13 += ' (DIFFERENT)'
      book_color = 'blue'
    else
      book_color = 'green'
    end
    puts JSON.pretty_generate(book)

    # give it back to the frontend
    status 200
    content_type :json
    {
      num: response['totalItems'],
      google_books_id: book['id'],
      title: book['volumeInfo']['title'],
      authors: book['volumeInfo']['authors'].map { |x| x.gsub(',','') }.join(','),
      date: book['volumeInfo']['publishedDate'],
      isbn_10: isbn_10,
      isbn_13: isbn_13,
      pages: book['volumeInfo']['pageCount'],
      image_link: book['volumeInfo']['imageLinks']['thumbnail'],
      book_color: book_color
    }.to_json
  rescue RuntimeError => e
    status 404
    return e.message
  end
end