# coding: utf-8

require 'encase'
require 'jiji/configurations/mongoid_configuration'
require 'jiji/utils/value_object'
require 'thread'
require 'jiji/web/transport/transportable'
require 'jiji/model/trading/internal/worker_mixin'

module Jiji::Model::Trading
  class BackTestProperties

    include Encase
    include Mongoid::Document
    include Jiji::Utils::ValueObject
    include Jiji::Web::Transport::Transportable

    needs :backtest_thread_pool
    needs :tick_repository
    needs :position_repository
    needs :pairs
    needs :securities_provider

    store_in collection: 'backtests'
    has_many :graphs,
      class_name: 'Jiji::Model::Graphing::Graph', dependent: :destroy
    has_many :logdata,
      class_name: 'Jiji::Model::Logging::LogData'
    has_many :agent_settings,
      class_name: 'Jiji::Model::Agents::AgentSetting', dependent: :destroy
    has_many :positions,
      class_name: 'Jiji::Model::Trading::Position'
    has_many :notifications,
      class_name: 'Jiji::Model::Notification::Notification'

    field :name,          type: String
    field :created_at,    type: Time
    field :memo,          type: String
    field :spread,        type: Float, default: 0.0

    field :start_time,       type: Time
    field :end_time,         type: Time
    field :tick_interval_id, type: Symbol, default: :fifteen_seconds
    field :pair_names,       type: Array
    field :balance,          type: Integer, default: 0
    field :status,           type: Symbol,  default: :wait_for_start

    field :cancelled_state, type: Hash

    validates :name,
      length:   { maximum: 200, strict: true },
      presence: { strict: true }

    validates :memo,
      length:      { maximum: 2000, strict: true },
      allow_nil:   true,
      allow_blank: true

    validates :created_at,
      presence: { strict: true }
    validates :start_time,
      presence: { strict: true }
    validates :end_time,
      presence: { strict: true }
    validates :pair_names,
      presence: { strict: true },
      length:   { minimum: 1 }
    validates :balance,
      presence:     { strict: true },
      numericality: {
        only_integer:             true,
        greater_than_or_equal_to: 0,
        strict:                   true
    }

    index(
      { created_at: 1, id: 1 },
      unique: true, name: 'backtests_created_at_id_index')

    attr_reader :process, :agents, :trading_context

    def to_h
      hash = {
        id:         _id,
        name:       name,
        memo:       memo,
        created_at: created_at,
        spread:     spread
      }
      insert_broker_setting_to_hash(hash)
      insert_status_to_hash(hash)
      hash
    end

    def retrieve_status_from_context
      @process.post_exec do |context, _queue|
        {
          status:       context.status,
          progress:     context[:progress],
          current_time: context[:current_time]
        }
      end.value
    end

    private

    def insert_broker_setting_to_hash(hash)
      hash.merge!({
        pair_names:       pair_names,
        start_time:       start_time,
        end_time:         end_time,
        tick_interval_id: tick_interval_id,
        balance:          balance
      })
    end

    def insert_status_to_hash(hash)
      if status == :running
        hash.merge!(retrieve_status_from_context)
      else
        hash[:status] = status
      end
    end

  end

  class BackTest < BackTestProperties

    include Jiji::Errors
    include Jiji::Model::Trading
    include Jiji::Model::Trading::Internal::WorkerMixin

    def setup
      self.created_at = created_at || time_source.now
      create_components
    end

    def start
      @process.start(create_default_jobs)

      self.status = :running
      save
    end

    def pause
      @process.pause if @process
      save_state if status == :running
    end

    def cancel
      illegal_state if @trading_context.finished?
      @process.cancel if @process
      save_state if status == :running
    end

    def retrieve_process_status
      @trading_context.status
    end

    def display_info
      { id: _id, name: name }
    end

    def start_on_startup?
      status == :wait_for_start || status == :paused
    end

    def destroy(*args)
      Position.where(backtest_id: id).delete
      super
    end

    private

    def save_state
      @agents.save_state

      status = retrieve_status_from_context
      self.status = status[:status]
      self.cancelled_state = collect_cancelled_state(status)
      save
    end

    def collect_cancelled_state(status)
      return nil if status[:current_time].nil?
      {
        cancelled_time: status[:current_time],
        orders:         @broker.orders.map { |o| o.to_h },
        balance:        @broker.account.balance
      }
    end

    def create_default_jobs
      [Jobs::NotifyNextTickJobForBackTest.new(start_time, end_time)]
      # ここで渡すstart_timeは全体の進捗率を算出する際の起点となる。
      # cancel して再開したときも、cancelled_time ではなく start_time を渡す
    end

    def calcurate_start_time
      cancelled_time = cancelled_state && cancelled_state[:cancelled_time]
      cancelled_or_paused? && cancelled_time ? cancelled_time + 15 : start_time
    end

    def create_components
      @logger          = logger_factory.create(self)
      @graph_factory   = create_graph_factory(self, -1)
      @broker          = create_broker
      @agents          = create_agents(self, true)
      @trading_context = create_trading_context(
        @broker, @agents, @graph_factory)
      @process         = create_process(@trading_context)
    end

    def cancelled_or_paused?
      status == :cancelled || status == :paused
    end

    def create_broker
      pairs = (pair_names || []).map { |p| @pairs.get_by_name(p) }
      Brokers::BackTestBroker.new(self, calcurate_start_time,
        end_time, tick_interval_id, pairs, restore_balance, restore_order, {
          tick_repository:     @tick_repository,
          securities_provider: @securities_provider,
          position_repository: @position_repository,
          pairs:               @pairs
        })
    end

    def create_trading_context(broker, agents, graph_factory)
      TradingContext.new(agents,
        broker, graph_factory, time_source, @logger)
    end

    def create_process(trading_context)
      Process.new(trading_context, backtest_thread_pool, true, -10)
    end

    def restore_order
      return [] unless cancelled_state && cancelled_state[:orders]
      cancelled_state[:orders].map do |o|
        order = Order.new(nil, nil, nil, nil, nil)
        order.from_h(o)
        order
      end
    end

    def restore_balance
      (cancelled_state && cancelled_state[:balance]) || balance
    end

  end

  def BackTest.create_from_hash(hash)
    BackTest.new do |b|
      b.name          = hash['name']
      b.memo          = hash['memo']
      b.spread        = hash['spread']

      load_broker_setting_from_hash(b, hash)
    end
  end

  def BackTest.load_broker_setting_from_hash(backtest, hash)
    backtest.pair_names  = (hash['pair_names'] || []).map { |n| n.to_sym }
    backtest.start_time  = hash['start_time']
    backtest.end_time    = hash['end_time']
    backtest.tick_interval_id = !hash['tick_interval_id'].nil? \
      ? hash['tick_interval_id'].to_sym : :fifteen_seconds
    backtest.balance = hash['balance'] || 0
  end
end
