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
end

require 'test/unit/assertions'
include Test::Unit::Assertions

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
        inputs[:distance] / plane[:efficiency]
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
