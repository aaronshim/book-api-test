require 'sinatra'

get '/' do
  send_file 'index.html'
end

post '/isbn' do
  content_type :json
  params[:isbn].to_json
end