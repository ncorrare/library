require 'json'
require 'nomad'
require 'sinatra'
require './models/books'
require './models/vault'

@@vault = LocalVault.new
@@books = Books.new
set :bind, '0.0.0.0'
set :port, ARGV[0]
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

delete '/v1/books/:isbn' do
  content_type :json
  key = params['key']
  if key == @@vault.getAPIKey
    if @@books.by_isbn(params['isbn'])[0].to_s == 'true'
      if (@@books.delete(params['isbn'])[0].to_s == 'true')
        output = [true, "Book #{params['isbn']} deleted"].to_json
        status 200
        output
      else
        halt 500, "Could not delete book #{params['isbn']}"
      end
    else
      halt 500, "Book does not exists".to_json
    end
  else halt 401, "Unauthorized".to_json
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
      #begin
        uri = URI.parse("http://192.168.50.16:4646/v1/job/addbook/dispatch")
        header = {'X-Nomad-Token': dispatchkey}
        logger.info "Making request to Nomad to add Book #{params['isbn']}"
        http = Net::HTTP.new(uri.host, uri.port)
        request = Net::HTTP::Post.new(uri.request_uri, header)
        logger.info payload
        request.body = payload
        response = http.request(request)
        success = response.code
        logger.info "Nomad's response is #{success}"
      #rescue
      #  return [false, "Cannot connect to Nomad"].to_json
      #end
      if success.to_s == '200'
        jobstatus = JSON.parse(response.body)
        readkey = @@vault.getConsulReadToken
        logger.info "Job to add isbn #{params['isbn']} dispatched succesfully"
        output = [true, readkey, jobstatus].to_json
        status 200
        output
      else
        halt 500, response.body
      end

    else
      halt 500, "Book already exists".to_json
    end
  else halt 401, "Unauthorized".to_json
end
end
