require 'rho/rhoevent'

describe "Events" do

  before(:all) do
    events = Rho::RhoEvent.find(:all)
    events.each do |key, val|
      Rho::RhoEvent.destroy(key)
    end    
  end

  it "should create" do
    title = 'Random'

    events = Rho::RhoEvent.find(:all)
    #puts "events: #{events.inspect.to_s}"
    events.should_not be_nil

    event = {}
    event['title'] = title
    event['location'] = 'loc1'
    event['notes'] = 'notes1'
    event['reminder'] = 60 if System::get_property('platform') == 'Blackberry'
    event['privacy'] = 'private'
    start_date = Time.now+600
    start_date -= start_date.usec.to_f/1000000
    end_date = Time.now+3600
    end_date -= end_date.usec.to_f/1000000
    event['start_date'] = start_date
    event['end_date'] = end_date

    puts "event: #{event}"    
    Rho::RhoEvent.create!(event)

    newevents = Rho::RhoEvent.find(:all)
    #puts "newevents: #{newevents.inspect.to_s}"
    newevents.should_not be_nil

    diff = newevents #.diff(events)
    diff.size.should == 1 
    diff.keys.size.should ==  1 
    c = diff[diff.keys.first]
    puts "c: #{c}"
    
    @id = c['id']
        
    c['title'].should == title
    c['location'].should == 'loc1'
    c['notes'].should == 'notes1'
    c['reminder'].should == 60 if System::get_property('platform') == 'Blackberry'
    c['privacy'].should == 'private' unless System::get_property('platform') == 'APPLE'
    c['start_date'].should == start_date
    c['end_date'].should == end_date
    
    #@revision = c['revision']
    #c['revision'].should_not be_nil


    #puts "id: #{@id}"
  end

  it "should find by dates" do
    start = Time.now
    end_time = start + 3600

    events = Rho::RhoEvent.find(:all, :start_date => start, :end_date => end_time, :find_type => 'starting', 
        :include_repeating => true )
        
    events.should_not be_nil
    events.size.should == 1 
  end
    
  it "should update" do
    #puts "id: #{@id}"
    
    start_date = Time.now
    start_date -= start_date.usec.to_f/1000000
    end_date = Time.now+1800
    end_date -= end_date.usec.to_f/1000000
    
    Rho::RhoEvent.update_attributes( 'id' => @id, 'title' => "RANDOM", 'location' => 'loc2', 'notes' => 'notes2', 
        'reminder' => 100, 'privacy' => 'confidential', 'start_date' => start_date, 'end_date' => end_date )

    event = Rho::RhoEvent.find(@id)
    #puts "event: #{event.inspect.to_s}"
    event.should_not be_nil

    event['title'].should ==  'RANDOM' 
    event['location'].should == 'loc2'
    event['notes'].should == 'notes2'
    event['reminder'].should == 100 if System::get_property('platform') == 'Blackberry'
    event['privacy'].should == 'confidential' unless System::get_property('platform') == 'APPLE'
    event['start_date'].should.to_s == start_date.to_s
    event['end_date'].should.to_s == end_date.to_s
    #@revision.should_not == event['revision']
  end

  it "should update recurrence" do
    # https://www.pivotaltracker.com/story/show/5484747
    # https://www.pivotaltracker.com/story/show/5484751
    if System::get_property('platform') == 'Blackberry'
      recValues = {'frequency'=>'daily', "interval"=>2 }
      Rho::RhoEvent.update_attributes( 'id' => @id, 'recurrence' => recValues )
      event = Rho::RhoEvent.find(@id)
      #puts "event: #{event.inspect.to_s}"
      event.should_not be_nil
      event['recurrence'].should == recValues

      recValues = {"frequency"=>"yearly", "interval"=>1, "end_date"=>Time.now + 60000, "days"=>[0, 0, 1, 0, 0, 0, 0], "months"=>[0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0], "weeks"=>[0, 0, 1, 0, 0]}
      Rho::RhoEvent.update_attributes( 'id' => @id, 'recurrence' => recValues )
      event = Rho::RhoEvent.find(@id)
      #puts "event: #{event.inspect.to_s}"
      event.should_not be_nil
      event['recurrence']['end_date'].to_s.should == recValues['end_date'].to_s
      event['recurrence']['end_date'] = ''
      recValues['end_date'] = ''
      #event['recurrence']['days'] = recValues['days']
      event['recurrence'].should == recValues

      recValues = {"frequency"=>"weekly", "interval"=>4, "end_date"=>Time.now + 60000, "days"=>[1, 1, 1, 1, 0, 0, 0]}
      Rho::RhoEvent.update_attributes( 'id' => @id, 'recurrence' => recValues )
      event = Rho::RhoEvent.find(@id)
      #puts "event: #{event.inspect.to_s}"
      event.should_not be_nil
      event['recurrence']['end_date'].to_s.should == recValues['end_date'].to_s
      event['recurrence']['end_date'] = ''
      recValues['end_date'] = ''
      event['recurrence'].should == recValues

      recValues = {"frequency"=>"weekly", "interval"=>5, "days"=>[0, 1, 1, 0, 0, 0, 1]}
      Rho::RhoEvent.update_attributes( 'id' => @id, 'recurrence' => recValues )
      event = Rho::RhoEvent.find(@id)
      #puts "event: #{event.inspect.to_s}"
      event.should_not be_nil
      event['recurrence'].should == recValues

      recValues =  {"frequency"=>"monthly", "interval"=>9, "days"=>[0, 0, 1, 0, 0, 0, 0], "weeks"=>[0, 0, 1, 0, 0]}
      Rho::RhoEvent.update_attributes( 'id' => @id, 'recurrence' => recValues )
      event = Rho::RhoEvent.find(@id)
      #puts "event: #{event.inspect.to_s}"
      event.should_not be_nil
      event['recurrence'].should == recValues
    end

  end

  it "should remove" do
    events = Rho::RhoEvent.find(:all)
    #puts "events: #{events.inspect.to_s}"
    events.should_not be_nil
    events.size.should >= 1 

    size = events.size

    Rho::RhoEvent.destroy(@id)

    events = Rho::RhoEvent.find(:all)
    puts "new events: #{events.inspect.to_s}"
    events.should_not be_nil

    (size - events.size).should == 1 
  end

end