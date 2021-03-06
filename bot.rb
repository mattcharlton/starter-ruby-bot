require 'slack-ruby-client'
require 'logging'

logger = Logging.logger(STDOUT)
logger.level = :debug

Slack.configure do |config|
  config.token = ENV['SLACK_TOKEN']
  if not config.token
    logger.fatal('Missing ENV[SLACK_TOKEN]! Exiting program')
    exit
  end
end

client = Slack::RealTime::Client.new

# listen for hello (connection) event - https://api.slack.com/events/hello
client.on :hello do
  logger.debug("Connected '#{client.self['name']}' to '#{client.team['name']}' team at https://#{client.team['domain']}.slack.com.")
end

# listen for channel_joined event - https://api.slack.com/events/channel_joined
client.on :channel_joined do |data|
  if joiner_is_bot?(client, data)
    client.message channel: data['channel']['id'], text: "Thanks for the invite! I don\'t do much yet, but #{help}"
    logger.debug("#{client.self['name']} joined channel #{data['channel']['id']}")
  else
    logger.debug("Someone far less important than #{client.self['name']} joined #{data['channel']['id']}")
  end
end

# listen for message event - https://api.slack.com/events/message
client.on :message do |data|

  case data['text']
  when 'hi', 'bot hi' then
    client.typing channel: data['channel']
    client.message channel: data['channel'], text: "Hello <@#{data['user']}>."
    logger.debug("<@#{data['user']}> said hi")
    
  when 'wifi password', 'wifi password?' then
    client.typing channel: data['channel']
    client.message channel: data['channel'], text: "The wifi password is [REDACTED]. Currently in a public repo, if we paid for this then we could use it a bit more."
    logger.debug("<@#{data['user']}> tyrion")
    
  when 'tyrion' then
    client.typing channel: data['channel']
    client.message channel: data['channel'], text: "Tyrion Lannister, the imp.  He drinks wine and he knows things, that's what he does."
    logger.debug("<@#{data['user']}> tyrion")
    
      when 'sharesave' then
    client.typing channel: data['channel']
    client.message channel: data['channel'], text: "Don't worry, your money is perfectly safe, it's not earning anything, and you're not getting any interest, but its safe.  As houses, in a post-brexit economy.  What could possibly go wrong?"
    logger.debug("<@#{data['user']}> tyrion")
    
      when 'jon snow' then
    client.typing channel: data['channel']
    client.message channel: data['channel'], text: "He knows nothing."
    logger.debug("<@#{data['user']}> tyrion")
    
   when 'got', 'thrones', 'game of thrones' then
    client.typing channel: data['channel']
    client.message channel: data['channel'], text: "You're in the great game now, and the great game is terrifying"
    logger.debug("<@#{data['user']}> got")
    
   when 'nandos', 'chicken' then
    client.typing channel: data['channel']
    client.message channel: data['channel'], text: "I love me some peri-peri, how about you, <@#{data['user']}> ?  We should totally go there for lunch today."
    logger.debug("<@#{data['user']}> chicken")
     
   when 'sync', 'tracker', 'git', 'changes' then
    client.typing channel: data['channel']
    client.message channel: data['channel'], text: "Don't take this the wrong way, but have you double checked that you've done a 'git push' after your commit?"
    logger.debug("<@#{data['user']}> git")
  
    if direct_message?(data)
      client.message channel: data['channel'], text: "It\'s nice to talk to you directly."
      logger.debug("And it was a direct message")
    end

   if direct_message?(data)
      client.message channel: data['channel'], text: "What a spicy message this is."
      logger.debug("And it was a direct message")
    end

    
  when 'attachment', 'bot attachment' then
    # attachment messages require using web_client
    client.web_client.chat_postMessage(post_message_payload(data))
    logger.debug("Attachment message posted")

  when bot_mentioned(client)
    client.message channel: data['channel'], text: 'You really do care about me. :heart:'
    logger.debug("Bot mentioned in channel #{data['channel']}")

  when 'bot help', 'help' then
    client.message channel: data['channel'], text: help
    logger.debug("A call for help")

  when /^bot/ then
    client.message channel: data['channel'], text: "Sorry <@#{data['user']}>, I don\'t understand. \n#{help}"
    logger.debug("Unknown command")
  end
end

def direct_message?(data)
  # direct message channels start with a 'D'
  data['channel'][0] == 'D'
end

def bot_mentioned(client)
  # match on any instances of `<@bot_id>` in the message
  /\<\@#{client.self['id']}\>+/
end

def joiner_is_bot?(client, data)
 /^\<\@#{client.self['id']}\>/.match data['channel']['latest']['text']
end

def help
  %Q(I will respond to the following messages: \n
      `bot hi` for a simple message.\n
      `nandos or chicken` for to see my love of chicken.\n
      `bot attachment` to see a Slack attachment message.\n
      `@<your bot\'s name>` to demonstrate detecting a mention.\n
      `bot help` to see this again.)
end

def post_message_payload(data)
  main_msg = 'Beep Beep Boop is a ridiculously simple hosting platform for your Slackbots.'
  {
    channel: data['channel'],
      as_user: true,
      attachments: [
        {
          fallback: main_msg,
          pretext: 'We bring bots to life. :sunglasses: :thumbsup:',
          title: 'Host, deploy and share your bot in seconds.',
          image_url: 'https://storage.googleapis.com/beepboophq/_assets/bot-1.22f6fb.png',
          title_link: 'https://beepboophq.com/',
          text: main_msg,
          color: '#7CD197'
        }
      ]
  }
end

client.start!
