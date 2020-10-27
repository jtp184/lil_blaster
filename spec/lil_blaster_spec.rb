RSpec.describe LilBlaster do
  it 'has a version number' do
    expect(LilBlaster::VERSION).not_to be nil
  end

  describe 'constants' do
    it 'can read and write the transmitter pin' do
      expect(LilBlaster.transmitter_pin).not_to be_nil

      og = LilBlaster.transmitter_pin

      LilBlaster.transmitter_pin = 69
      expect(LilBlaster.transmitter_pin).to eq(69)
      LilBlaster.transmitter_pin = og
    end

    it 'can read and write the reader pin' do
      expect(LilBlaster.reader_pin).not_to be_nil

      og = LilBlaster.reader_pin

      LilBlaster.reader_pin = 69
      expect(LilBlaster.reader_pin).to eq(69)
      LilBlaster.reader_pin = og
    end
  end
end
