require 'json'
require 'nomad'
require 'sinatra'
require './models/books'
require './models/vault'

@@vault = LocalVault.new
@@books = Books.new
get '/' do
  booklist = @@books.all
  bookshelf = []
  booklist[1].each { |isbn| bookshelf.push(@@books.by_isbn(isbn)[1])}
  logger.info 'Posting full book list via WebUI'
  erb :bookshelf, :locals => {:content => bookshelf}
end

get '/v1/books' do
  content_type :json
  booklist = @@books.all
  bookshelf = []
  booklist[1].each { |isbn| bookshelf.push(@@books.by_isbn(isbn)[1])}
  logger.info 'Posting full book list via API'
  response = bookshelf.to_json
  if status == true
    response
  else
    halt 400, response
  end
end

post '/v1/books/:isbn' do
  content_type :json
  key = params['key']
  if key = @@vault.getAPIKey
    content = JSON.parse(params[:content])
    unless @@books.by_isbn(content[:isbn])
      output = @@books.Create(content[:isbn], content[:title], content[:subtitle], content[:published], content[:authors], content[:cover])
      status = output[0]
      response = output[1].to_json
      if status != true
        halt 500, response
      end
    else
      halt 500, "Book already exists"
    end
  else halt 401, "Unauthorized"
end
end
