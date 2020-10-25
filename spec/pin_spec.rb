RSpec.describe LilBlaster::GPIO::Pin, :hardware do
  before :all do
    @input_test_pin = 27
    @output_test_pin = 17
  end

  before :each do
    @input_pin = LilBlaster::GPIO::Pin.new(@input_test_pin)
    @output_pin = LilBlaster::GPIO::Pin.new(@output_test_pin, :output)
  end

  it 'Can be initialized for input' do
    expect(@input_pin).not_to be_nil
  end

  it 'Knows what pin number to track' do
    expect(@input_pin).to respond_to(:id)
    expect(@input_pin.id).to eq(@input_test_pin)
    expect(@input_pin.gpio_pin).not_to be_nil
  end

  it 'Can change direction of pin settings' do
    expect(@output_pin.direction).to eq(:output)

    @output_pin.direction = :input

    expect(pin.direction).to eq(:input)
  end

  it 'Can check the value of the input pin attached to' do
    a = @input_pin.on?
    b = @input_pin.off?

    expect(a).not_to eq(b)
  end

  it 'Can write the value of the output pin attached to' do
    @output_pin.turn_on
    expect(@output_pin.on?).to be(true)

    @output_pin.turn_off
    expect(@output_pin.on?).to be(false)
  end
end
