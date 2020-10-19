RSpec.describe LilBlaster::GPIO do
  it 'has a hardware driver when pigpio is defined' do
    # Fake constant to trick #defined?
    Pigpio = 1

    expect(LilBlaster::GPIO.driver).to be(Pigpio)

    Object.send(:remove_const, :Pigpio)
  end

  it 'has a hardware driver when pigpio is undefined, and issues a warning' do
    og_stderr = $stderr
    $stderr = StringIO.new

    expect(LilBlaster::GPIO.driver).to be(nil)

    $stderr.rewind

    expect($stderr.string.chomp).to eq('Pigpio is not defined, please require it.')

    $stderr = og_stderr
  end
end
