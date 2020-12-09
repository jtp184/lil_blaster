RSpec.describe 'Manchester Protocol' do
  before :all do
    @klass = LilBlaster::Protocol::Manchester
    @proto = FactoryBot.build(:manchester_protocol)

    @cmd = 0x40BF

    @tr = @proto.encode @cmd
    @alt = FactoryBot.build(:alternate_manchester).encode(@cmd)
  end

  describe 'Class functions' do
    it 'can identify properly formatted transmissions' do
      expect(@klass.match?(@tr)).to be(true)
      expect(@klass.match?(LilBlaster::Transmission.new(data: []))).to be(false)
    end

    it 'can determine system data of a transmission' do
      expect(@klass.system_data(@tr)).to eq(0xE0E0)
    end

    it 'can determine command data of a transmission' do
      expect(@klass.command_data(@tr)).to eq(0x40BF)
    end

    it 'can return an instance based off a transmission' do
      protocol, command = @proto.decode(@tr)

      expect(protocol).to be_a(LilBlaster::Protocol::Manchester)
      expect(command).to be_a(Integer)

      expect(command).to eq(@cmd)
    end

    it 'can compare two different transmissions with the same data' do
      compare = @klass.same_data?(@tr, @alt)

      expect(compare).to be(true)
    end
  end

  describe 'Instance functions' do
    it 'can encode various commands' do
      ex = [0x2020, 0x1234, 0xABCD, 0xDEAD, 0xBEEF]

      transmissions = ex.map { |x| @proto.encode(x) }
      bytestrings = ex.map { |x| @proto.to_bytestring(x) }

      expect(transmissions.map { |x| @klass.command_data(x) }).to eq(ex)
      expect(bytestrings.map { |x| x[0..15] }.uniq.length).to eq(1)
      expect(bytestrings.map { |x| x[16..-1] }.uniq.length).to eq(ex.length)
    end

    it 'can determine whether it is shift or space encoded' do
      shif = FactoryBot.build(:manchester_protocol)
      spac = FactoryBot.build(:manchester_protocol)

      %i[zero one].each { |i| spac.pulse_values[i].reverse! }

      expect(shif.encoding).to eq(:shift)
      expect(spac.encoding).to eq(:space)
    end

    describe 'with a repeat code' do
      before :all do
        @repeat = FactoryBot.build(:manchester_protocol)
        @repeat.pulse_values[:repeat] = @repeat_pulse = [4500, 2800]

        @repeat_transmission = LilBlaster::Transmission.new(data: [4500, 2800, 520, 80_000])
      end

      it 'can detect a repeat transmission' do
        expect(@repeat.decode(@repeat_transmission)[1]).to eq(-1)
      end

      it 'can encode repeats into the transmission' do
        repeat_count = rand(1..10)
        trns = @repeat.encode(0xBEEF, repeat_count)

        expect(trns.tuples.count(@repeat_pulse)).to eq(repeat_count)
      end
    end
  end
end
