require 'rubygems'
require 'bundler/setup'

require 'httparty'
require 'instagram'
require 'json'

# Instagram access token
access_token = ''

# Slack incoming webhook URL
webhook_url = ''

Instagram.configure do |config|
	# Instagram client information https://instagram.com/developer/clients/manage/
	config.client_id = ''
	config.client_secret = ''
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

client = Instagram.client(:access_token => access_token)

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
	:channel => '#news',
	:text => 'New Instagram ' + (attachments.length == 1 ? 'post' : 'posts') + ' from *@' + client.user(user).username.to_s + '*',
	:username => 'ig beta',
	:attachments => attachments,
}

# puts payload

HTTParty.post(webhook_url, body: { payload: payload.to_json })
f = File.new(min_timestamp_file, 'w')
f.write(min_timestamp)
f.close
