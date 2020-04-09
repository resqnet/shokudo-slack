require "rubygems"
require "bundler"
Bundler.require

kms_client = Aws::KMS::Client.new(region: "ap-northeast-1")

arn = ""

text = ARGV[0]
resp = kms_client.encrypt(key_id: arn, plaintext: text)
encrypt = Base64.strict_encode64(resp.ciphertext_blob)
decrypt = kms_client.decrypt(ciphertext_blob: Base64.decode64(encrypt))[:plaintext]

pp encrypt
p "Done" if text == decrypt
