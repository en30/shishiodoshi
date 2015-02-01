require 'sinatra/base'
require 'time'
require 'eventmachine'
require 'logger'

module Shishiodoshi
  class App < Sinatra::Base
    def self.build_logger(name)
      Logger.new("#{settings.root}/log/#{name}.log")
    end

    def self.start_worker!
      worker_logger = build_logger('worker')
      EM.add_periodic_timer(settings.poll_per) do
        shishiodoshis.delete_if do |id, shishiodoshi|
          if shishiodoshi.flush?
            worker_logger.info "#{id} was flushed"
            shishiodoshi.flush!
            true
          end
        end
      end
    end

    def self.run!(daemon: false)
      Process.daemon(true) if daemon

      EM.run do
        EM.defer do
          super
        end

        start_worker!

        handler = proc do
          quit!
          EM.stop
        end
        Signal.trap(:INT, &handler)
        Signal.trap(:TERM, &handler)
      end
    end

    configure do
      set :poll_per, 10
      set :shishiodoshis, {}
      set :shishiodoshi_type, ::Shishiodoshi::Base
      set :root, File.expand_path('..', $0)
      set :error_logger, build_logger('error')
      use Rack::CommonLogger, build_logger(settings.environment)
    end

    configure :production, :development do
      enable :logging
    end

    helpers do
      def shishiodoshis
        settings.shishiodoshis
      end

      def shishiodoshi
        settings.shishiodoshis[params[:id]]
      end
    end

    before { env["rack.errors"] = settings.error_logger }

    post '/shishiodoshis/:id' do
      shishiodoshis[params[:id]] = settings.shishiodoshi_type.new(
        id: params[:id],
        flushed_at: params[:flushed_at] ? Time.parse(params[:flushed_at]) : Time.now,
        max_items: (params[:max_items] || 5).to_i
      )
    end

    delete '/shishiodoshis/:id' do
      if shishiodoshi
        shishiodoshis.delete(params[:id])
        status 200
      else
        status 404
      end
    end

    post '/shishiodoshis/:id/item' do
      if shishiodoshi
        shishiodoshi.push(params)
        status 200
      else
        status 404
      end
    end
  end
end
