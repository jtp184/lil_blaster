RSpec.describe LilBlaster::Blaster, :hardware do
  it 'can transmit a transmission' do
    code = LilBlaster::Transmission.new(data: [517, 1732, 517, 609])
    LilBlaster::Blaster.transmit(code)
  end
end
