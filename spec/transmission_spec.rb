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

  it 'can get the length of a transmission, in microts' do
    expect(@transmission.length).to eq(@transmission.data.reduce(&:+))
  end

  it 'can get the count of a transmission, in number of pulses' do
    expect(@transmission.count).to eq(@transmission.data.count)
  end

  it 'can recalculate a transmission based on a replacement matrix' do
    offsetter = Array.new(10) do
      @transmission.clone.tap do |t|
        t.data.map! { |d| d + rand(-100..100) }
      end
    end

    offsetter << @transmission.clone
    offsetter = offsetter.reduce(&:+)

    repl = LilBlaster::NoiseReducer.replacement_matrix(offsetter.data)

    result = @transmission % repl

    expect(result.data.uniq.count).to eq(6)
    all_from_replacement = ->(d) { d.all? { |n| repl.reduce(&:merge).values.uniq.include?(n) } }
    expect(result.data.uniq).to satisfy(&all_from_replacement)
  end
end
