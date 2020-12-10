RSpec.describe 'RCMM Protocol' do
  before :all do
    @klass = LilBlaster::Protocol::RCMM
    @proto = FactoryBot.build(:rcmm_protocol)

    @cmd = 109

    @tr = @proto.encode(@cmd)
    @alt = FactoryBot.build(:alternate_rcmm).encode(@cmd)
  end

  describe 'Class functions' do
    xit 'can identify properly formatted transmissions' do
      expect(@klass.match?(@tr)).to be(true)
      expect(@klass.match?(LilBlaster::Transmission.new(data: []))).to be(false)
    end

    it 'can determine the mode data of a transmission' do
      expect(@klass.mode_data(@tr)).to eq(:oem)
    end

    xit 'can determine the address data of a transmission' do
      expect(@klass.address_data(@tr)).to eq(nil)
    end

    xit 'can return an instance based off a transmission' do
      protocol, command = @proto.decode(@tr)

      expect(protocol).to be_a(LilBlaster::Protocol::RCMM)
      expect(command).to be_a(Integer)

      expect(command).to eq(@cmd)
    end
  end

  describe 'Instance functions' do
  end
end
