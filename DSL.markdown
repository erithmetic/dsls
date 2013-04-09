!SLIDE

# DSLs

## Derek Kastner (@dkastner)

!SLIDE

# What?

!SLIDE

# What?

* Domain Model + Lanugage = DSL

!SLIDE

# Domain Model

* Vocabulary to describe models and processes
* Use the same vocabulary as your domain experts
  * Maybe they can even write some code...

!SLIDE

# Language Continuum

![Continuum](continuum.png)

!SLIDE

# Language

## Cucumber

@@@ ruby
    Background:
      Given aircraft data is loaded

    Scenario:
      Given distance is 500km
      And airline is United Airlines
      When I compute the results
      Then the emissions should be 768kg of CO2e
@@@

!SLIDE

# Library

## Rails Router

@@@ ruby
    Rails::Application.draw_routes do
      resources :flights do
        member do
          get :stats
          put :itinerary
        end
      end

      root to: controller: :flights, action: :index
    end
@@@

!SLIDE

# Problem:

## Carbon Emissions for a flight

* kg CO2 = [Fuel CO2 intensity] * [mass/vol of fuel burned]
* kg CO2 = [      CO2/l       ] * [    liters of fuel     ]
* kg CO2 =        0.721         * [    liters of fuel     ]

!SLIDE

# Mass of fuel burned

* X l = [distance (km)] / [Aircraft    km/l]
* X l = [distance (km)] / [20.833 (avg) km/l]

!SLIDE

# Inputs

* Aircraft
  * Airline
  * Distance
  * Origin/Destination pairs
* Aircraft km/l
  * Aircraft type
* Distance
  * Origin Airport
  * Destination Airport

!SLIDE

# NO

@@@ ruby
    def carbon(distance = nil, airline = nil, aircraft = nil,
               fuel_efficiency = nil, origin = nil, destination = nil)
      distance ||= if origin && destination
        distance_between(origin, destination)
      else
        airline.average_distance
      end
      airline  ||= Airline.default
      aircraft ||= airline.aircraft.find_by_distance(distance)
      if aircraft
        fuel_efficiency ||= aircraft.fuel_efficiency
      elsif airline
        fuel_efficiency ||= airline.average_fuel_efficiency
      end
      # ...
      0.721 * (distance / fuel_efficiency)
    end
@@@

!SLIDE

@@@ ruby
    committee :aircraft do
      quorum :from_airline_and_distance, needs: [:airline, :distance] do |inputs|
        inputs[:airline].aircraft.
          find_by_distance(inputs[:distance])
      end
      quorum :from_distance, needs: [:distance] do |inputs|
        Aircraft.find_by_distance(inputs[:distance])
      end
      quorum :from_airline, needs: [:airline] do |inputs|
        inputs[:airline].average_aircraft
      end
    end
@@@

!SLIDE

# Extending

@@@ ruby
    committee :aircraft do
      quorum :from_airline_and_distance, needs: [:airline, :distance],
                                                      complies: :ghg do |inputs|
        inputs[:airline].aircraft.
          aircraft_by_distance(inputs[:distance])
      end
      quorum :from_origin_and_destination, needs: [:airline, :distance],
                                                      complies: :ghg do |inputs|
        inputs[:airline].aircraft.
          find_by_distance(inputs[:distance])
      end
      quorum :from_distance, needs: [:distance] do |inputs|
        Aircraft.find_by_distance(inputs[:distance])
      end
      quorum :from_airline, needs: [:airline] do |inputs|
        inputs[:airline].average_aircraft
      end
    end
@@@

!SLIDE

# CODE TIME

!SLIDE

# Real-world examples

* [Carbon Middleware](http://impact.brighterplanet.com/) (http://impact.brighterplanet.com/)
* [Flight Calculation](http://brighterplanet.github.io/flight/impact_model.html) (http://brighterplanet.github.io/flight/impact\_model.html)
* [Leap](http://github.com/rossmeissl/leap) (http://github.com/rossmeissl/leap)

# Tools

* [Blockenspiel](https://github.com/dazuma/blockenspiel) (https://github.com/dazuma/blockenspiel)
