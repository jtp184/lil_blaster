RSpec.describe 'Manchester Protocol' do
  before :all do
    @klass = LilBlaster::Protocol::Manchester

    @proto = LilBlaster::Protocol::Manchester.new(
      header: [4501, 4509],
      gap: 47_000,
      pulse_values: {
        zero_value: [520, 610],
        one_value: [520, 1710]
      },
      system_data: 0xE0E0,
      post_bit: 520
    )

    @cmd = 0x40BF

    @tr = @proto.encode @cmd

    @eq = LilBlaster::Protocol::Manchester.new(
      header: [4501, 4509],
      gap: 47_000,
      pulse_values: {
        zero_value: [509, 603],
        one_value: [509, 1701]
      },
      system_data: 0xE0E0,
      post_bit: 509
    ).encode(@cmd)
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
      protocol, command = @klass.decode(@tr)

      expect(protocol).to be_a(LilBlaster::Protocol::Manchester)
      expect(command).to be_a(Integer)

      expect(command).to eq(@cmd)
    end

    it 'can compare two different transmissions with the same data' do
      compare = @klass.same_data?(@tr, @eq)

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
  end
end
