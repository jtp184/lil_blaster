RSpec.describe LilBlaster::Blaster, :hardware do
  it 'can transmit a transmission' do
    code = LilBlaster::Transmission.new(data: [517, 1732, 517, 609])
    LilBlaster::Blaster.transmit(code)
  end

  it 'can perform basic blinking' do
    LilBlaster::Blaster.turn_on

    expect(LilBlaster::Blaster.on?).to eq(true)

    LilBlaster::Blaster.turn_off
    
    expect(LilBlaster::Blaster.off?).to eq(true)
  end

  it 'can check its active status' do
    expect(LilBlaster::Blaster.on?).not_to eq(LilBlaster::Blaster.off?)
  end
end
