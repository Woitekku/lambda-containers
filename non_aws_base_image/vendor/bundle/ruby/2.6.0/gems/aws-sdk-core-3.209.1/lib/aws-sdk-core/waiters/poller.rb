# frozen_string_literal: true

module Aws
  module Waiters

    # Polls a single API operation inspecting the response data and/or error
    # for states matching one of its acceptors.
    # @api private
    class Poller

      # @api private
      RAISE_HANDLER = Seahorse::Client::Plugins::RaiseResponseErrors::Handler

      # @option options [required, String] :operation_name
      # @option options [required, Array<Hash>] :acceptors
      # @api private
      def initialize(options = {})
        @operation_name = options.fetch(:operation_name)
        @acceptors = options.fetch(:acceptors)
      end

      # @return [Symbol]
      attr_reader :operation_name

      # Makes an API call, returning the resultant state and the response.
      #
      # * `:success` - A success state has been matched.
      # * `:failure` - A terminate failure state has been matched.
      # * `:retry`   - The waiter may be retried.
      # * `:error`   - The waiter encountered an un-expected error.
      #
      # @example A trivial (bad) example of a waiter that polls indefinetly.
      #
      #   loop do
      #
      #     state, resp = poller.call(client:client, params:{})
      #
      #     case state
      #     when :success then return true
      #     when :failure then return false
      #     when :retry   then next
      #     when :error   then raise 'oops'
      #     end
      #
      #   end
      #
      # @option options [required,Client] :client
      # @option options [required,Hash] :params
      # @return [Array<Symbol,Response>]
      def call(options = {})
        response = send_request(options)
        @acceptors.each do |acceptor|
          if acceptor_matches?(acceptor, response)
            return [acceptor['state'].to_sym, response]
          end
        end
        [response.error ? :error : :retry, response]
      end

      private

      def send_request(options)
        req = options[:client].build_request(@operation_name, options[:params])
        req.handlers.remove(RAISE_HANDLER)
        Aws::Plugins::UserAgent.metric('WAITER') do
          req.send_request
        end
      end

      def acceptor_matches?(acceptor, response)
        send("matches_#{acceptor['matcher']}?", acceptor, response)
      end

      def matches_path?(acceptor, response)
        if response.data
          JMESPath.search(path(acceptor), response.data) == acceptor['expected']
        else
          false
        end
      end

      def matches_pathAll?(acceptor, response)
        non_empty_array(acceptor, response) do |values|
          values.all? { |value| value == acceptor['expected'] }
        end
      end

      def matches_pathAny?(acceptor, response)
        non_empty_array(acceptor, response) do |values|
          values.any? { |value| value == acceptor['expected'] }
        end
      end

      def matches_status?(acceptor, response)
        response.context.http_response.status_code == acceptor['expected']
      end

      def matches_error?(acceptor, response)
        case acceptor['expected']
        when 'false' then response.error.nil?
        when 'true' then !response.error.nil?
        else
          response.error.is_a?(Aws::Errors::ServiceError) &&
            response.error.code == acceptor['expected'].delete('.')
        end
      end

      def path(acceptor)
        acceptor['argument']
      end

      def non_empty_array(acceptor, response, &block)
        if response.data
          values = JMESPath.search(path(acceptor), response.data)
          values.is_a?(Array) && values.count > 0 ? yield(values) : false
        else
          false
        end
      end

    end
  end
end
