RSpec.describe 'Hardware driver spec' do
  it 'has a hardware driver when pigpio is defined' do
    # Fake constant to trick #defined?

    delink = if defined?(Pigpio)
               false
             else
               Pigpio = 1
               true
             end

    expect(LilBlaster::GPIO.driver).to be(Pigpio)
    Object.send(:remove_const, :Pigpio) if delink
  end

  it 'has a hardware driver when pigpio is undefined, and issues a warning' do
    backup = defined?(Pigpio) ? Pigpio : nil
    og_stderr = $stderr

    Object.send(:remove_const, :Pigpio) if defined?(Pigpio)
    $stderr = StringIO.new

    expect(LilBlaster::GPIO.driver).to be(nil)

    $stderr.rewind

    expect($stderr.string.chomp).to match('WARN: ')

    $stderr = og_stderr
    Pigpio = backup
  end

  it 'can memoize and return a hash of constants from the driver' do
    cns = LilBlaster::GPIO.pi_constants

    expect(cns).to be_a(Hash)
    expect(LilBlaster::GPIO.pi_constants.object_id).to eq(cns.object_id)
  end
end
