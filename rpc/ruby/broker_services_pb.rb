# Generated by the protocol buffer compiler.  DO NOT EDIT!
# Source: broker.proto for package 'jiji.rpc'

require 'grpc'
require 'broker_pb'

module Jiji
  module Rpc
    module BrokerService
      class Service

        include GRPC::GenericService

        self.marshal_class_method = :encode
        self.unmarshal_class_method = :decode
        self.service_name = 'jiji.rpc.BrokerService'

        rpc :GetAccount, GetAccountRequest, Account
        rpc :GetPairs, GetPairsRequest, GetPairsResponse
        rpc :GetTick, GetTickRequest, Tick
        rpc :RetrieveRates, RetrieveRatesRequest, Rates
        rpc :GetPositions, GetPositionsRequest, Positions
        rpc :GetOrders, GetOrdersRequest, Orders
        rpc :Order, OrderRequest, OrderResponse
        rpc :ModifyOrder, ModifyOrderRequest, ModifyOrderResponse
        rpc :CancelOrder, CancelOrderRequest, CancelOrderResponse
        rpc :ModifyPosition, ModifyPositionRequest, ModifyPositionResponse
        rpc :ClosePosition, ClosePositionRequest, ClosePositionResponse
        rpc :RetrieveEconomicCalendarInformations, RetrieveEconomicCalendarInformationsRequest, EconomicCalendarInformations
      end

      Stub = Service.rpc_stub_class
    end
  end
end
