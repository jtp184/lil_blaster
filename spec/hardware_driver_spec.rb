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

  it 'can throw an error in response to hardware driver errors' do
    sym = :PI_GPIO_IN_USE
    val = -50
    e = nil

    begin
      LilBlaster::GPIO.gpio_success(val)
    rescue IOError => e
      expect(e.message).to match(/hardware driver error/i)
    end

    expect(e).not_to be_nil
    expect(e.message).to match(/#{sym}/)
  end
end
