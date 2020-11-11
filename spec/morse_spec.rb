RSpec.describe 'Morse Code' do
  before :all do
    @klass = LilBlaster::Protocol::Morse

    @proto = @klass.new

    @message = "It's not the best choice, it's Spacer's Choice"

    @fuzzy = @proto.encode(@message).tap { |t| t.data.map! { |n| n + rand(-200..200) } }
  end

  it 'can encode a message into a transmission' do
    tr = @proto.encode(@message)

    expect(tr).to be_a(LilBlaster::Transmission)
  end

  it 'can identify a properly formatted transmission' do
    expect(@klass.match?(@fuzzy)).to be(true)
  end

  it 'can decode a properly formatted transmission' do
    expect(@klass.match?(@fuzzy)).to be(true)
    expect(@klass.decode(@fuzzy)[1]).to eq(@message.upcase)
  end
end
