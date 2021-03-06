describe "initial mock game", :shared => true do
  before :each do
    @game = mock(:MockGame)
  end
end

describe "initial mock container", :shared => true do
  before :each do
    @container = mock(:MockContainer, :input => mock('input mock', :null_object => true))
  end
end

describe "initial mock state", :shared => true do
  it_should_behave_like 'initial mock container'
  
  before :each do
    @state = mock('MockState')
    @state.stub!(:name => 'mock')
    Jemini::GameState.active_state = @state
  end
end

describe "test state", :shared => true do
  it_should_behave_like 'initial mock game'
  it_should_behave_like 'initial mock container'
  it_should_behave_like 'resourceless game state'
  before :each do
    @game_state = TestState.new(@container, @game)
    Jemini::GameState.active_state = @state
  end
end

describe "resourceless game state", :shared => true do
  before :each do
    Jemini::GameState.stub_instance(:load_resources)
  end

  after :each do
    Jemini::GameState.unstub_instance(:load_resources)
  end
end