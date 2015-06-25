require './config/app'
require 'config/app'
require 'rubygems'
require 'bundler/setup'

require 'httparty'
require 'instagram'
require 'json'

Instagram.configure do |config|
	config.client_id = InstagramSlack::Config::Instagram[:client_id]
	config.client_secret = InstagramSlack::Config::Instagram[:client_secret]
end

user = ARGV[0]

min_timestamp_file = user + '-min_timestamp'

min_timestamp = ''

begin
	f = File.new(min_timestamp_file, 'r')
	min_timestamp = f.readline
rescue
	# rescue
ensure
	f.close unless f.nil?
end

client = Instagram.client(:access_token => InstagramSlack::Config::Instagram[:access_token])

recent_media = client.user_recent_media(user, :min_timestamp => min_timestamp)

attachments = Array.new

for media_item in recent_media.reverse
	caption = ''
	created_time = media_item.created_time

	unless media_item.caption.nil?
		caption = media_item.caption.text
	end

	attachment = {
		:fallback => caption + ': ' + media_item.link.strip,
		:image_url => media_item.images.standard_resolution.url,
		:title => media_item.link,
		:thumb_url => media_item.images.thumbnail.url,
		:title_link => media_item.link,
		:text => caption,
	}

	attachments.push(attachment)

	min_timestamp = created_time.to_i + 1
end

if attachments.length == 0
	exit
end

payload = {
	:text => 'New Instagram ' + (attachments.length == 1 ? 'post' : 'posts') + ' from *@' + client.user(user).username.to_s + '*',
	:username => 'ig beta',
	:attachments => attachments,
}

if defined? InstagramSlack::Config::Slack[:channel]
	payload[:channel] = InstagramSlack::Config::Slack[:channel]
end

# puts payload

HTTParty.post(InstagramSlack::Config::Slack[:webhook_url], body: { payload: payload.to_json })

f = File.new(min_timestamp_file, 'w')
f.write(min_timestamp)
f.close
