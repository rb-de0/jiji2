# coding: utf-8

require 'oanda_api'

module Jiji::Model::Securities::Internal::Virtual
  module RateRetriever
    include Jiji::Errors
    include Jiji::Model::Trading

    def init_rate_retriever_state(start_time, end_time,
      pairs, interval_id = :fifteen_seconds, spread)
      check_period(start_time, end_time)
      @current_time = @start_time = start_time
      @end_time    = end_time
      @interval_id = interval_id
      @buffer      = []
      @pairs       = pairs
      @spread      = spread
    end

    def retrieve_pairs
      @pairs
    end

    def retrieve_current_tick
      fill_buffer if @buffer.empty?
      raw_tick= @buffer.shift

      if @spread.nil? || @spread == 0
        @current_tick = raw_tick
      else
        values = {}
        raw_tick.each { |key, value|
          values[key] = Tick::Value.new(value.bid, value.bid + @spread)
        }
        @current_tick =  Tick.new(values, raw_tick.timestamp)
      end
      
      update_orders(@current_tick)
      update_positions(@current_tick)

      @current_tick
    end

    def retrieve_tick_history(pair_name, start_time, end_time)
      unsupported
    end

    def retrieve_rate_history(pair_name, interval, start_time, end_time)
      @securities_provider.get.retrieve_rate_history(
        pair_name, interval, start_time, end_time)
    end

    def next?
      fill_buffer if @buffer.empty?
      !@buffer.empty?
    end

    private

    def fill_buffer
      load_next_ticks while @buffer.empty? && @current_time < @end_time
    end

    def load_next_ticks
      interval = Intervals.instance.get(@interval_id)
      start_time  = @current_time
      next_period = @current_time + (interval.ms / 1000) * 1000
      end_time    = @end_time > next_period ? next_period : @end_time
      pair_names  = @pairs.map { |p| p.name }
      @buffer += @tick_repository.fetch(pair_names,
        start_time, end_time, @interval_id)
      @current_time = end_time
    end

    def check_period(start_time, end_time)
      if !start_time || !end_time || start_time >= end_time
        illegal_argument('illegal period.',
          start_time: start_time, end_time: end_time)
      end
    end

    def retrieve_pair_by_name(name)
      retrieve_pairs.find { |p| p.name == name }
    end
  end
end
