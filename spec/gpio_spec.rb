RSpec.describe 'GPIO', :hardware do
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
