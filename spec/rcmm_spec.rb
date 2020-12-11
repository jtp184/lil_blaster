RSpec.describe 'RCMM Protocol' do
  before :all do
    @klass = LilBlaster::Protocol::RCMM
    @proto = FactoryBot.build(:rcmm_protocol)

    @cmd = 27

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
      expect(@klass.mode_data(@tr)).to eq(:keyboard)
    end

    it 'can determine the address data of a transmission' do
      expect(@klass.address_data(@tr)).to eq(0)
    end

    it 'can return an instance based off a transmission' do
      protocol, command = @proto.decode(@tr)

      expect(protocol).to be_a(LilBlaster::Protocol::RCMM)
      expect(command).to be_a(Integer)

      # binding.pry

      expect(command).to eq(@cmd)
    end
  end

  describe 'Instance functions' do
  end
end
