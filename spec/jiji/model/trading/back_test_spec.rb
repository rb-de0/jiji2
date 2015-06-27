# coding: utf-8

require 'jiji/test/test_configuration'

describe Jiji::Model::Trading::BackTest do
  before(:example) do
    @data_builder = Jiji::Test::DataBuilder.new

    @container    = Jiji::Test::TestContainerFactory.instance.new_container
    @repository   = @container.lookup(:backtest_repository)
    @time_source  = @container.lookup(:time_source)
    @registory    = @container.lookup(:agent_registry)
    @repository.load

    @registory.add_source('aaa', '', :agent, @data_builder.new_agent_body(1))
    @registory.add_source('bbb', '', :agent, @data_builder.new_agent_body(2))
  end

  after(:example) do
    @repository.stop
    @data_builder.clean
  end

  it 'to_hでハッシュに変換できる' do
    test = @repository.register({
      'name'          => 'テスト',
      'start_time'    => Time.at(100),
      'end_time'      => Time.at(2000),
      'memo'          => 'メモ',
      'pair_names'    => [:EURJPY, :EURUSD],
      'agent_setting' => [
        { name: 'TestAgent1@aaa', properties: { 'a' => 1, 'b' => 'bb' } },
        { name: 'TestAgent1@aaa', properties: {} },
        { name: 'TestAgent2@bbb' }
      ]
    })

    sleep 0.2

    hash = test.to_h
    expect(hash[:name]).to eq 'テスト'
    expect(hash[:memo]).to eq 'メモ'
    expect(hash[:start_time]).to eq Time.at(100)
    expect(hash[:end_time]).to eq Time.at(2000)
    expect(hash[:pair_names]).to eq [:EURJPY, :EURUSD]
    expect(hash[:balance]).to eq 0
    expect(hash[:agent_setting].length).to be 3
    expect(hash[:status]).to eq :running
    expect(hash[:progress]).to be >= 0
    expect(hash[:current_time]).not_to be nil

    @repository.stop
    @container    = Jiji::Test::TestContainerFactory.instance.new_container
    @repository   = @container.lookup(:backtest_repository)
    @repository.load

    test = @repository.all[0]
    hash = test.to_h
    expect(hash[:name]).to eq 'テスト'
    expect(hash[:memo]).to eq 'メモ'
    expect(hash[:start_time]).to eq Time.at(100)
    expect(hash[:end_time]).to eq Time.at(2000)
    expect(hash[:pair_names]).to eq [:EURJPY, :EURUSD]
    expect(hash[:balance]).to eq 0
    expect(hash[:agent_setting].length).to be 3
    expect(hash[:status]).to eq :cancelled
    expect(hash[:progress]).to be nil
    expect(hash[:current_time]).to be nil
  end
end