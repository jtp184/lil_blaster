RSpec.describe 'Protocol Base Class' do
  %i[identify identify!].each do |sym|
    it "Class can respond to #{sym}" do
      expect(LilBlaster::Protocol::BaseProtocol).to respond_to(sym)
      expect(LilBlaster::Protocol::BaseProtocol.send(sym, nil)).not_to be_nil
    end
  end

  %i[call ==].each do |sym|
    it "Instance can respond to #{sym}" do
      expect(LilBlaster::Protocol::BaseProtocol.new).to respond_to(sym)
      expect(LilBlaster::Protocol::BaseProtocol.new.send(sym, nil)).not_to be_nil
    end
  end
end
