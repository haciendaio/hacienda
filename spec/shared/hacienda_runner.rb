require 'net/http'

module Hacienda
  module Test

    class HaciendaRunner

      PLEASE_TERMINATE = 'TERM'
      A_HOPEFULLY_NICELY_TERMINATING_WEB_SERVER = 'thin'

      def initialize(hostname, port)
        @hostname = hostname
        @port = port
      end

      def start
        print 'starting service...'
        app_root = File.join(File.dirname(__FILE__), '..', '..')
        Dir.chdir app_root do
          @service_pid = Process.spawn("rackup config.ru -p #{@port} --server #{A_HOPEFULLY_NICELY_TERMINATING_WEB_SERVER} --env test")
        end
        wait_until_service_is_ready
        puts 'started'
        self
      end

      def stop
        print "...stopping service, sending signal #{PLEASE_TERMINATE} to #{@service_pid}..."
        Process.kill PLEASE_TERMINATE, @service_pid
        Process.wait @service_pid
        puts 'stopped'
      end

      private

      def wait_until_service_is_ready
        response = ''
        last_error = Exception.new 'Timeout'
        timeout_time = five_seconds_from_now()
        until (response == '200' || Time.now > timeout_time)
          begin
            response = Net::HTTP.get_response(URI.parse("http://#{@hostname}:#{@port}/status")).code
            sleep(0.05)
          rescue StandardError => last_error
            sleep(0.05)
          end
        end
        raise last_error unless response == '200'
      end

      def five_seconds_from_now
        Time.now + 5
      end
    end
  end
end
