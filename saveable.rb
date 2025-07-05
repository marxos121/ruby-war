module Saveable
  def save(filename = nil)
    filename ||= default_filename
    
    File.open(filename, 'wb') do |file|
      Marshal.dump(save_state, file)
    end
    puts "Game saved successfully!"
  end

  def load(filename = nil)
    filename ||= default_filename
    return false unless File.exist?(filename)

    begin
      saved_state = File.open(filename, 'rb') { |file| Marshal.load(file) }
      load_state(saved_state)
      true
    rescue => e
      puts "Error loading save file: #{e.message}"
      false
    end
  end

  private

  def default_filename
    "#{self.class.name.downcase}_save.dat"
  end

  
  def save_state
    raise NotImplementedError, "#{self.class} needs to implement save_state"
  end

  def load_state(state)
    raise NotImplementedError, "#{self.class} needs to implement load_state"
  end
end