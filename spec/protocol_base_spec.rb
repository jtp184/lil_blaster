RSpec.describe 'Protocol Base Class' do
  %i[identify identify!].each do |sym|
    it "Class can respond to #{sym}" do
      expect(LilBlaster::Protocol::Protocol).to respond_to(sym)
    end
  end

  %i[call ==].each do |sym|
    it "Instance can respond to #{sym}" do
      expect(LilBlaster::Protocol::Protocol.new).to respond_to(sym)
    end
  end
end
