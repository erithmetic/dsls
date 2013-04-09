require 'blockenspiel'

aircraft = {
  'dc_9' => {
    average_distance: 500,
    efficiency: 0.3
  },
  'boeing_737' => {
    average_distance: 800,
    efficiency: 0.7
  }
}

module Carbon
  class QuorumSet
    include Blockenspiel::DSL

    attr_accessor :quorums

    def quorum(name, options = {}, &blk)
      self.quorums ||= []

      self.quorums << {
        name: name,
        block: blk,
        needs: options[:needs]
      }

      self
    end
  end

  class CommitteeSet
    include Blockenspiel::DSL

    attr_accessor :committees

    def committee(name, options = {}, &blk)
      self.committees ||= []

      quorums = Blockenspiel.invoke blk, QuorumSet.new
      self.committees << {
        name: name,
        quorums: quorums
      }

      self
    end
  end

  def decide(decision_name, options = {}, &blk)
    committee_set = Blockenspiel.invoke blk, CommitteeSet.new

    class_eval do
      define_method decision_name do
        Carbon.make_decision self, options[:with], committee_set
      end
    end
  end

  def Carbon.make_decision(object, possible_inputs, committee_set)
    inputs = possible_inputs.inject({}) do |hsh, attribute|
      value = object.send(attribute)
      hsh[attribute] = value if value
      hsh
    end

    committee_set.committees.reverse.each do |committee|
      quorum_set = committee[:quorums]
      quorum = quorum_set.quorums.find do |q|
        (Array(q[:needs]) - inputs.keys).empty?
      end
      if quorum
        inputs[committee[:name]] = quorum[:block].call inputs
      else
        raise "Could not solve #{committee[:name]} with inputs #{inputs.inspect}"
      end
    end

    inputs[committee_set.committees.first[:name]]
  end
end

require 'test/unit/assertions'
include Test::Unit::Assertions

q = Carbon::QuorumSet.new
q.quorum :foo, needs: [:bar] do |inputs|
  inputs[:bar] * 3
end

assert_equal q.quorums.first[:block].call({ bar: 2 }), 6

c = Carbon::CommitteeSet.new
c.committee :foo do
  quorum :bar, needs: [:pez] do |inputs|
    inputs[:pez] * 3
  end
end

quorum = c.committees.first[:quorums].quorums.first
assert_equal quorum[:block].call({ pez: 2 }), 6

class Flight
  extend Carbon

  attr_accessor :aircraft, :distance

  decide :emissions, with: [:aircraft, :distance] do
    committee :co2e do
      quorum :from_fuel, needs: [:fuel] do |inputs|
        0.721 * inputs[:fuel]
      end
    end

    committee :fuel do
      quorum :from_aircraft_and_distance, needs: [:aircraft, :distance] do |inputs|
        inputs[:aircraft][:efficiency] * inputs[:distance]
      end
      quorum :from_distance, needs: :distance do |inputs|
        plane = aircraft.find do |name, data|
          data if data[:average_distance] >= inputs[:distance]
        end
      end
      quorum :from_aircraft, needs: :aircraft do |inputs|
        inputs[:aircraft][:average_distance] / inputs[:aircraft][:efficiency]
      end
    end
  end
end

f = Flight.new
f.aircraft = aircraft['boeing_737']

assert_equal 824.0, f.emissions

puts "OK!"
