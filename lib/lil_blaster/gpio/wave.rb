module LilBlaster
  module GPIO
    # Models the hardware level signal processing
    class Wave
      class << self
        # Takes in +tuples+ of marks and spaces and returns an array of wave ids
        def tuples_to_wave(data)
          data.tuples.each.with_object([]) do |pulse, wids|
            mark, space = pulse

            wids << add_mark_wave(data, mark)
            wids << add_space_wave(space)
          end
        end

        # A pulse which turns the transmitter pin on for +length+
        def on_pulse(length = 1)
          [1 << LilBlaster.transmitter_pin, 0, length]
        end

        # A pulse which turns the transmitter pin off for +length+
        def off_pulse(length = 1)
          [0, 1 << LilBlaster.transmitter_pin, length]
        end

        # A pulse with a +length+ and no signal
        def empty_pulse(length = 1)
          [0, 0, length]
        end

        # Syntax sugar, calls begin_wave, runs the block, and calls end_wave
        def within_wave(&blk)
          begin_wave
          blk.call
          end_wave
        end

        # Syntax sugar for wavetuner#add_new
        def begin_wave
          wavetuner.add_new
        end

        # Syntax sugar for wavetuner#create
        def end_wave
          wavetuner.create
        end

        # Syntax sugar for wavetuner#add_generic, converts the array 3-tuples into pulses
        def add_to_wave(data)
          wavetuner.add_generic(data.map { |x| wavetuner.pulse(*x) })
        end

        # Chains the waves with ids +wids+ together
        def chain_waves(wids)
          wavetuner.chain(wids)
        end

        # Clears the waves in the wavetuner
        def clear_waves
          wavetuner.clear
        end

        # Exposes the waveform creation and execution interface
        def wavetuner
          @wavetuner ||= GPIO.connection.wave
        end

        private

        # Takes in the Transmission +data+ and the specific mark +plen+ to add a pulse to the wave
        def add_mark_wave(data, plen)
          mark_wave = if data.carrier_wave?
                        carrier(data.carrier_wave_options.merge(length: plen))
                      else
                        [on_pulse(plen), off_pulse(1)]
                      end

          within_wave { add_to_wave(mark_wave) }
        end

        # Takes in the +plen+ and generates an empty pulse of that length
        def add_space_wave(plen)
          within_wave { add_to_wave([empty_pulse(plen)]) }
        end

        # Creates a carrier wave, taking arguments for the frequency,
        # gpio_pin, pulse_length, and cycle_length
        def carrier(args = {})
          timer = 0
          math = cycle_math(args)

          math[:cycle_count].times.with_object([]) do |cy, wave|
            target = ((cy + 1) * math[:cycle]).round

            timer += math[:blink_length]
            delay = (target - timer)
            timer += delay

            wave << on_pulse(math[:blink_length])
            wave << off_pulse(delay)
          end
        end

        # Tidy up the carrier function by breaking out the math here
        def cycle_math(args)
          ret = {}

          ret[:cycle] = args.fetch(:cycle_length, 1000.0).to_f / args.fetch(:frequency, 38.0)
          ret[:cycle_count] = (args.fetch(:length) / ret[:cycle]).round
          ret[:blink_length] = (ret[:cycle] / 2.0).round

          ret
        end
      end
    end
  end
end