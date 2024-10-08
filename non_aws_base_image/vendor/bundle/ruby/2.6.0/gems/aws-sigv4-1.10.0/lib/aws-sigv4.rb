# frozen_string_literal: true

require_relative 'aws-sigv4/asymmetric_credentials'
require_relative 'aws-sigv4/credentials'
require_relative 'aws-sigv4/errors'
require_relative 'aws-sigv4/signature'
require_relative 'aws-sigv4/signer'

module Aws
  module Sigv4
    VERSION = File.read(File.expand_path('../VERSION', __dir__)).strip
  end
end