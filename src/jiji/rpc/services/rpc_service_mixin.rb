# coding: utf-8

require 'grpc'
require 'jiji/rpc/converters/converters'

module Jiji::Rpc::Services
  module RpcServiceMixin
    include Encase
    include Jiji::Errors
    include GRPC::Core
    include Jiji::Rpc::Converters

    needs :logger_factory
    needs :agent_proxy_pool

    def handle_exception(exception, call)
      log_exception(exception)
      raise GRPC::BadStatus.new(
        resolve_error_code(exception),
        extract_detail(exception))
    end

    def get_agent_instance(instance_id)
      agent_proxy_pool[instance_id] \
      || not_found(Jiji::Model::Agents::Agent, instance_id: instance_id)
    end

    private

    def resolve_error_code(exception)
      if exception.is_a?(NotFoundException)
        StatusCodes::NOT_FOUND
      elsif exception.is_a?(ArgumentError)
        StatusCodes::INVALID_ARGUMENT
      elsif exception.is_a?(ActiveModel::StrictValidationFailed)
        StatusCodes::FAILED_PRECONDITION
      elsif exception.is_a?(IllegalStateException)
        StatusCodes::FAILED_PRECONDITION
      else
        StatusCodes::INTERNAL
      end
    end

    def extract_detail(exception)
      "#{exception.message} (#{exception.class}) \n" \
        + exception.backtrace.join("\n\t")
    end

    def log_exception(exception)
      logger.warn(exception)
    end

    def logger
      @logger ||= logger_factory.create_system_logger
    end
  end
end
