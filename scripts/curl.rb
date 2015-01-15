#!/usr/bin/ruby
require 'json'
require_relative '../app/security/cryptography'

client_id = ENV['CRYPTO_CLIENT_ID']
client_secret = ENV['CRYPTO_CLIENT_SECRET']

timestamp = Time.now.to_i.to_s

data_index = ARGV.index('--data')
content = ''
content = ARGV[data_index + 1] if data_index

authorisation_data = {
    nonce: '84024B89D',
    client_id: client_id,
    timestamp: timestamp,
    secret: client_secret
}

#ACHTUNG: so far, this works only for empty content (which is ok for publishing)
hash = Hacienda::Security::Cryptography.new.generate_authorisation_data(content, authorisation_data[:secret], authorisation_data[:nonce], authorisation_data[:timestamp])[:hash]

headers = { :'Accept-Language' => 'en'}
headers[:nonce] = authorisation_data[:nonce]
headers[:clientid] = authorisation_data[:client_id]
headers[:timestamp] = authorisation_data[:timestamp]
headers[:authorization] = "HMAC #{hash}"

headers_string = headers.map do |key, value|
  "-H '#{key}: #{value}'"
end.join ' '

ARGV[data_index + 1] = "'#{content}'" if data_index

curl_command = "curl #{headers_string} #{ARGV.join ' '}"

puts 'nonce:     ' + authorisation_data[:nonce]
puts 'client_id: ' + authorisation_data[:client_id]
puts 'timestamp: ' + authorisation_data[:timestamp]
puts 'hash:      ' + hash

puts curl_command

puts `#{curl_command}`
