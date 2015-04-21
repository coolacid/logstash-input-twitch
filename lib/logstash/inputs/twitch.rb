# encoding: utf-8
require 'logstash/inputs/base'
require 'logstash/namespace'
require 'socket' # for Socket.gethostname

class LogStash
  class Inputs
    # This class queries the twitch api for any given stream
    # and gives out statistics to logstash
    class Twitch < LogStash::Inputs::Base
      config_name 'twitch'
      milestone 1

      # List of channels
      config :channels, validate: :array, required: true

      # Interval to run the command. Value is in seconds.
      config :interval, validate: :number, default: 60

      public

      def register
        require 'faraday'
        @logger.info('Registering Twitch Input', interval: @interval)
      end # def register

      public

      def query_stream(channel)
        response = Faraday.get format('https://api.twitch.tv/kraken/streams/%s', channel)
        result = JSON.parse(response.body)
        status = response.status

        @logger.info? && @logger.info('Stats',
                                      channel: channel,
                                      status: status,
                                      body: response.body,
                                      result: result['stream']
                                                      )

        if !result['stream'].nil? && state[channel].nil? && status == 200
          @state[channel] = true
          @event['state'] = 'Stream Started'
          @event['title'] = result['stream']['channel']['status']
        elsif result['stream'].nil? && !state[channel].nil? && status == 200
          @state[channel] = nil
          @event['state'] = 'Stream Ended'
        end

        @event['streamid'] = result['stream']['_id']
        @event['Game'] = result['stream']['game']
        @event['Viewers'] = result['stream']['viewers']
        @event['Follower'] = result['stream']['followers']
        @event['Views'] = result['stream']['views']
      end

      def query_chat(channel)
        response = Faraday.get format('http://tmi.twitch.tv/group/user/%s/chatters', channel)
        result = JSON.parse(response.body)

        @event['chat'] = {}
        @event['chat']['all'] = result['chatter_count']
        @event['chat']['mods'] = result['chatters']['moderators'].count
        @event['chat']['staff'] = result['chatters']['staff'].count
        @event['chat']['admins'] = result['chatters']['admins'].count
        @event['chat']['viewers'] = result['chatters']['viewers'].count
      end

      def query(channel, queue)
        @event = LogStash::Event.new
        @event['channel'] = channel
        begin
          query_stream(channel)
          query_chat(channel)

          decorate(@event)
          queue << @event
        rescue StandardError => e
          @logger.debug? && @logger.debug('Failed to parse streams event',
                                          error: e)
        end
      end

      def poller(queue)
        start = Time.now

        @channels.each do | channel |
          query(channel, queue)
        end

        duration = Time.now - start
        @logger.info? && @logger.info('poll completed', command: @command,
                                                        duration: duration)
      end

      def run(queue)
        state = {}
        @channels.each do | channel |
          state[channel] = nil
        end

        Stud.interval(@interval) do
          poller(queue)
        end # loop
      end # def run
    end # class LogStash::Inputs::Exec
  end
end
