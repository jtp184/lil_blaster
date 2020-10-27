RSpec.describe LilBlaster::GPIO::Wave, :hardware do
  it 'can convert tuples to waves' do
    code = LilBlaster::Transmission.new(data: [517, 1732, 517, 609])
    LilBlaster::GPIO::Wave.tuples_to_wave(code)
  end
end
