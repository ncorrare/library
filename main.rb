require 'json'
require 'nomad'
require 'sinatra'
require './models/books'
require './models/vault'

@@vault = LocalVault.new
@@books = Books.new
set :bind, '0.0.0.0'
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
  if key == @@vault.getAPIKey
    payload = {
      :Meta => {
        :ISBN => params['isbn']
      }
    }.to_json
    if @@books.by_isbn(params['isbn'])[0].to_s == 'false'
      dispatchkey = @@vault.getNomadDispatchToken
      logger.info dispatchkey
      #begin
        logger.info 'define uri'
        uri = URI.parse("https://nomad.stn.corrarello.net/v1/job/addbook/dispatch")
        logger.info 'define header'
        header = {'X-Nomad-Token': dispatchkey}
        logger.info 'define request'
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        request = Net::HTTP::Post.new(uri.request_uri, header)
        logger.info payload
        request.body = payload
        response = http.request(request)
      #rescue
      #  return [false, "Cannot connect to Nomad"].to_json
      #end
      if response.code == 200
        jobstatus = JSON.parse(response.body)
        readkey = @@vault.getConsulReadToken
        response = [true, readkey].to_json
        response
      else
        halt 500, response.body
      end

    else
      halt 500, "Book already exists".to_json
    end
  else halt 401, "Unauthorized".to_json
end
end
