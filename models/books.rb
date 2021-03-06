require 'json'
require 'diplomat'
require './models/vault'

class Books

  def initialize
    @vault = LocalVault.new
  end

  def by_isbn(isbn)
    #book = @consul.kv.get("/library/#{isbn}")
    encdata = Diplomat::Kv.get("library/#{isbn}",{ http_addr: ENV['CONSUL_HTTP_ADDR'], dc: "stn", token: @vault.getConsulToken},  not_found = :return, found = :return)
    if (encdata != nil and encdata != "")
      data = JSON.parse(encdata)
      if data["title"].include? 'vault'
        book = {
          "isbn" => data["isbn"],
          "title" => @vault.decrypt(data["title"].to_s, 'library', 'morbury'),
          "thumbnail_url" => @vault.decrypt(data["thumbnail_url"].to_s, 'library', 'morbury'),
          "subtitle" => @vault.decrypt(data["subtitle"].to_s, 'library', 'morbury'),
          "url" => @vault.decrypt(data["url"].to_s, 'library', 'morbury'),
          "publish_date" => @vault.decrypt(data["publish_date"].to_s, 'library', 'morbury'),
          "author" => @vault.decrypt(data["author"].to_s, 'library', 'morbury'),
          "publishers" => @vault.decrypt(data["publishers"].to_s, 'library', 'morbury'),
        }
      else
        book = data
      end
      return [true, book]
    else
      return [false, nil]
    end
  end

  def all()
    keys = Diplomat::Kv.get("library/", { keys: true, http_addr: ENV['CONSUL_HTTP_ADDR'], dc: "stn", token: @vault.getConsulToken})
    if keys != nil
      books = []
      keys.drop(1).each { |path| books.push(path.partition('/').last) }
      return [true, books]
    else
      return [false, nil]
    end
  end

  def create(isbn)
    unless isbn.nil?
      if self.by_isbn(isbn)[0] == false
        begin
          uri = URI("https://openlibrary.org/api/books?bibkeys=ISBN:#{isbn}&jscmd=data&format=json")
          response = Net::HTTP.get(uri)
        rescue
          return [false, "Cannot connect to OpenLibrary API"]
        end
        if response != nil
          key, data = JSON.parse(response).first
          unless data.nil?
            if data["authors"].nil?
              authors = 'Unknown'
            else
              authors = data["authors"][0]["name"].to_s
            end
            if data["identifiers"].key? 'isbn_10'
              isbnadd = data["identifiers"]["isbn_10"][0]
            else
              isbnadd = data["identifiers"]["isbn_13"][0]
            end
            if data.key? 'cover'
              if data["cover"].key? 'large'
                image = data["cover"]["large"].to_s
              else
                if data["cover"].key? 'small'
                  image = data["cover"]["small"].to_s
                else
                  image = "http://104.130.11.24/images/noimage.jpg"
                end
              end
            end
            if data.key? 'subtitle'
              subtitle = data["subtitle"].to_s
            else
              subtitle = '-'
            end
            book = {
              "isbn" => isbnadd,
              "title" => @vault.encrypt(data["title"].to_s, 'library', 'morbury'),
              "thumbnail_url" => @vault.encrypt(image, 'library', 'morbury'),
              "subtitle" => @vault.encrypt(subtitle, 'library', 'morbury'),
              "url" => @vault.encrypt(data["url"].to_s, 'library', 'morbury'),
              "publish_date" => @vault.encrypt(data["publish_date"].to_s, 'library', 'morbury'),
              "author" => @vault.encrypt(authors, 'library', 'morbury'),
              "publishers" => @vault.encrypt(data["publishers"][0]["name"].to_s, 'library', 'morbury'),
            }
            if Diplomat::Kv.put("library/#{isbn}", book.to_json, { http_addr: ENV['CONSUL_HTTP_ADDR'], dc: "stn", token: @vault.getConsulToken})
              return [true, isbn]
            else
              return [false, "Error storing book with ISBN #{isbn}"]
            end
          else
            return [false, "Book not found in the OpenLibrary API"]
          end
        else
          return [false, "Book not found in the OpenLibrary API"]
        end
      else
        return [false, "ISBN already exist"]
      end
    else
      return [false, "ISBN cannot be empty"]
    end
  end

def delete(isbn)
  unless isbn.nil?
    if self.by_isbn(isbn)[0] == true
      if Diplomat::Kv.delete("library/#{isbn}", { http_addr: ENV['CONSUL_HTTP_ADDR'], dc: "stn", token: @vault.getConsulToken})
        return [true, isbn]
      else
        return [false, "Error deleting book with ISBN #{isbn}"]
      end
    else
      return [false, "ISBN does not exist"]
    end
  else
    return [false, "ISBN cannot be empty"]
  end
end

end
