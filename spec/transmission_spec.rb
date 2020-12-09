RSpec.describe LilBlaster::Transmission do
  before :all do
    @transmission = FactoryBot.build(:transmission)
    @raw_data = @transmission.data
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

  it 'can add transmissions together' do
    combo = @transmission + @transmission

    expect(combo.data.length).to eq(@transmission.data.length * 2)
  end

  it 'can multiply a transmission by a value' do
    repeat = @transmission * 3

    expect(repeat.data.length).to eq(@transmission.data.length * 3)
  end
end
