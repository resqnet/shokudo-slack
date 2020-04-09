require "rubygems"
require "bundler"
Bundler.require

def hello(event:, context:)
  kms_client = Aws::KMS::Client.new(region: "ap-northeast-1")
  # SlackToken
  slack_token = kms_client.decrypt(ciphertext_blob: Base64.decode64(ENV["SLACK_TOKEN"]))[:plaintext]

  # SlackChannel
  slack_channel = ENV["SLACK_CHANNEL"]

  # ShokudoログインID
  shokudo_id = kms_client.decrypt(ciphertext_blob: Base64.decode64(ENV["SHOKUDO_ID"]))[:plaintext]

  # Sshokudoログインパスワード
  shokudo_pass = kms_client.decrypt(ciphertext_blob: Base64.decode64(ENV["SHOKUDO_PASS"]))[:plaintext]

  postData = {
    "token" => slack_token,
    "channel" => slack_channel,
    "text" => "",
  }

  # LOGIN
  url = "https://minnano.shokudou.jp/users/sign_in"

  charset = nil
  agent = Mechanize.new
  agent.verify_mode = OpenSSL::SSL::VERIFY_NONE

  page = agent.get(url)
  form = page.form_with(:id => "new_user")
  form["user[email]"] = shokudo_id
  form["user[password]"] = shokudo_pass
  menu_page = agent.submit(form)

  doc = Nokogiri::HTML(menu_page.content.toutf8)

  # みんなの食堂がおやすみの可能性を考慮
  date_section = doc.xpath('//ul[@class="date-list"]/li/section/h2[@class="date__ttl"]/span').first.text.strip
  date_array = /(\d+)\/(\d+)\(/.match(date_section).to_a
  menu_date = Date.new(Date.today.year, date_array[1].to_i, date_array[2].to_i)

  # 献立を取得
  main_section = doc.xpath('//ul[@class="date-list"]/li/section/ul[@class="menu-list"]/li').first
  main_dish_info = {
    :image => main_section.search('img[@class="menu__img"]').attr("src").value + "?v=#{Time.now.to_i}",
    :name => main_section.search('h3[@class="menu__ttl"]').text.strip,
  }

  if main_dish_info[:name].empty? || main_dish_info[:image].empty? || menu_date != Date.today
    return {
      statusCode: 200,
      body: {
        message: "rest",
        input: event,
      }.to_json,
    }
  end

  text = "【今日のご飯】 \n#{main_dish_info[:name]}\n#{main_dish_info[:image]}\n\n予約: https://minnano.shokudou.jp/daily_menus"

  postData["text"] = text

  res = Net::HTTP.post_form(URI.parse("https://slack.com/api/chat.postMessage"), postData)

  {
    statusCode: 200,
    body: {
      message: "done",
      input: event,
    }.to_json,
  }
end
