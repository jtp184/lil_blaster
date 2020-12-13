RSpec.describe 'RCMM Protocol' do
  before :all do
    @klass = LilBlaster::Protocol::RCMM
    @proto = FactoryBot.build(:rcmm_protocol)

    @ch_mode = proc do |t, m|
      t.data[2] = @proto.pulse_values[m][0]
      t.data[3] = @proto.pulse_values[m][1]
      t
    end

    @x_mode = proc do |t, m|
      t.data[2] = @proto.pulse_values[:zero][0]
      t.data[3] = @proto.pulse_values[:zero][1]

      t.data[4] = @proto.pulse_values[m][0]
      t.data[5] = @proto.pulse_values[m][1]
      t
    end
  end

  before :each do
    @cmd = rand(1..1000)
    @tr = @proto.encode(@cmd)
    @alt = FactoryBot.build(:alternate_rcmm).encode(@cmd)
    @wr = LilBlaster::Transmission.new(data: Array.new(32) { rand(200..1000) })
  end

  describe 'Class functions' do
    it 'can identify properly formatted transmissions' do
      expect(@klass.match?(@tr)).to be(true)
      expect(@klass.match?(@wr)).to be(false)
    end

    it 'can determine the mode data of a transmission' do
      expect(@klass.mode_data(@ch_mode[@tr, :one])).to eq(:mouse)
      expect(@klass.mode_data(@ch_mode[@tr, :two])).to eq(:keyboard)
      expect(@klass.mode_data(@ch_mode[@tr, :three])).to eq(:gamepad)

      expect(@klass.mode_data(@x_mode[@tr, :zero])).to eq(:oem)
      expect(@klass.mode_data(@x_mode[@tr, :one])).to eq(:x_mouse)
      expect(@klass.mode_data(@x_mode[@tr, :two])).to eq(:x_keyboard)
      expect(@klass.mode_data(@x_mode[@tr, :three])).to eq(:x_gamepad)
    end

    it 'can determine the address data of a transmission' do
      expect(@klass.address_data(@tr)).to eq(1)
    end

    it 'can return an instance based off a transmission' do
      protocol, command = @proto.decode(@tr)

      expect(protocol).to be_a(LilBlaster::Protocol::RCMM)
      expect(command).to be_a(Integer)

      expect(command).to eq(@cmd)
    end

    it 'can create 4bit bytestrings' do
      str = @klass.bytestring_for(@tr)

      expect(str).to(satisfy { |s| (s.chars.uniq - %w[0 1 2 3]).empty? })
    end
  end

  describe 'Instance functions' do
  end
end
