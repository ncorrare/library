require 'vault'
require 'base64'

##
# This object abstract the crypto / secrets management functions of HashiCorp Vault
class LocalVault
  def initialize
    @vault = Vault::Client.new
  end

##
# Obtain a set of credentials for anything we may need
  def getConsulToken
    credentials = @vault.logical.read("consul/creds/library")
    return credentials.data[:token]
  end

  def getNomadDispatchToken
    credentials = @vault.logical.read("nomad/creds/dispatch")
    return credentials.data[:secret_id]
  end

  def getConsulReadToken
    credentials = @vault.logical.read("consul/creds/library-read")
    return credentials.data[:token]
  end

  def getAPIKey
    credentials = @vault.logical.read("kv/library")
    return credentials.data[:apikey]
  end

##
# Encrypt a value with a defined key and context for symmetric encryption.
  def encrypt(value,key,context)
    cyphertext = @vault.logical.write("transit/encrypt/#{key}", plaintext: Base64.encode64(value).gsub('\n',''), context: Base64.encode64(context).gsub('\n',''))
    return cyphertext.data[:ciphertext]
  end

##
# Decrypt a value with a defined key and context.
  def decrypt(value,key,context)
    plaintext = @vault.logical.write("transit/decrypt/#{key}", ciphertext: value, context: Base64.encode64(context).gsub('\n',''))
    return Base64.decode64(plaintext.data[:plaintext]).gsub('\n','')
  end
end
