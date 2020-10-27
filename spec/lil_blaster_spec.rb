RSpec.describe LilBlaster do
  it 'has a version number' do
    expect(LilBlaster::VERSION).not_to be nil
  end

  describe 'constants' do
    it 'can read and write the transmitter pin' do
      expect(LilBlaster.transmitter_pin).not_to be_nil

      LilBlaster.transmitter_pin = 69
      expect(LilBlaster.transmitter_pin).to eq(69)
    end
  end
end
