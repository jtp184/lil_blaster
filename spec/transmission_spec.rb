RSpec.describe LilBlaster::Transmission do
  before :all do
    @raw_data = [
      4511, 4540, 517, 1732,
      517, 1732, 517, 1732,
      517, 609, 517, 609,
      517, 609, 517, 609,
      517, 609, 517, 1732,
      517, 1732, 517, 1732,
      517, 609, 517, 609,
      517, 609, 517, 609,
      517, 609, 517, 609,
      517, 1732, 517, 609,
      517, 609, 517, 609,
      517, 609, 517, 609,
      517, 609, 517, 1732,
      517, 609, 517, 1732,
      517, 1732, 517, 1732,
      517, 1732, 517, 1732,
      517, 1732, 517, 47_312
    ]

    @transmission = LilBlaster::Transmission.new(data: @raw_data)
  end

  it 'can create a transmission from pulses' do
    ex = LilBlaster::Transmission.new(data: @raw_data)

    expect(ex).not_to be_nil

    expect(ex).to respond_to(:tuples)
    expect(ex).to respond_to(:data)

    expect(ex.data).to eq(@raw_data)
    expect(ex.tuples).to eq(@raw_data.each_slice(2).to_a)
  end

  it 'can create a pulse that does not use a carrier wave' do
    ex = LilBlaster::Transmission.new(data: @raw_data, carrier_wave: false)

    expect(ex.carrier_wave?).to eq(false)
  end

  it 'can create a pulse with custom carrier wave options' do
    ex_one = LilBlaster::Transmission.new(data: @raw_data, carrier_wave: 38.0)

    ex_two = LilBlaster::Transmission.new(
      data: @raw_data,
      carrier_wave: { frequency: 38.0, cycle_length: 2000 }
    )

    expect(ex_one.carrier_wave?).to eq(true)
    expect(ex_two.carrier_wave?).to eq(true)

    expect(ex_one.carrier_wave_options).to have_key(:frequency)
    expect(ex_two.carrier_wave_options).to have_key(:cycle_length)

    expect(ex_one.carrier_wave_options).not_to have_key(:cycle_length)
  end
end
