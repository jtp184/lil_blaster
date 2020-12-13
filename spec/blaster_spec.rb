RSpec.describe LilBlaster::Blaster, :hardware do
  it 'can transmit a transmission' do
    code = LilBlaster::Transmission.new(data: [517, 1732, 517, 609])
    LilBlaster::Blaster.transmit(code)
  end

  it 'can perform basic blinking' do
    expect(LilBlaster::Blaster.turn_on && LilBlaster::Blaster.on?).to eq(true)

    expect(LilBlaster::Blaster.turn_off && LilBlaster::Blaster.off?).to eq(true)
  end

  it 'can check its active status' do
    expect(LilBlaster::Blaster.on?).not_to eq(LilBlaster::Blaster.off?)
  end

  it 'can send codes from a codex' do
    cdx = FactoryBot.build(:codex)

    expect(LilBlaster::Blaster.send_code(:test, codex: cdx)).to be(true)
  end
end
