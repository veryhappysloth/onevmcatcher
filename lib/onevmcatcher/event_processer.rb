module Onevmcatcher

  class EventProcesser

    attr_reader :vmc_configuration, :options

    def initialize(vmc_configuration, options)
      fail ArgumentError, '"vmc_configuration" must be an instance ' \
        'of Onevmcatcher::VmcatcherConfiguration' unless vmc_configuration.kind_of? Onevmcatcher::VmcatcherConfiguration

      @vmc_configuration = vmc_configuration
      @options = options

    end

    def process!
      Onevmcatcher::Log.info "[#{self.class.name}] Processing eventes stored in "
    
      archived_events do |event, event_file|
        begin
          event_handler = Onevmcatcher::EventHandlers.const_get("#{event.type}EventHandler")
          event_handler = event_handler.new(vmc_configuration, options)
          event_handler.handle!(event)

          clean_up_event!(event, event_file)
        end
      end
    end

    def archived_events(&block)
        arch_events = ::Dir.glob(::File.join(options.metadata_dir, '*.json'))
        arch_events.sort!

        Onevmcatcher::Log.debug "[#{self.class.name}] Foud events: #{arch_events.inspect}"
        arch_events.each do |json|
          json_short = json.split(::File::SEPARATOR).last

          unless Onevmcatcher::EventHandlers::BaseEventHandler::Event_FILE_REGEXP =~ json_short
            Onevmcatcher::Log.error "[#{self.class.name}] #{json.inspect} doesn't match the required format"
            next
          end

          vmc_event_from_json = read_event(json)
          block.call(json, vmc_event_from_json) if vmc_event_from_json
        end
    end

    def read_event(json)
      begin
        Onevmcatcher::VmcatcherEvent.new(::File.read(json))
      rescue => ex
        Onevmcatcher::Log.error "[]Failed to load event"
        return
      end
    end

    def clean_event!(event, event_file)
      Onevmcatcher::Log.info "[#{self.class.name}] Cleaning up"

      begin
        ::FileUtils.rm_-f event_file
      rescue => ex
        Onevmcatcher::Log.fatal "Failed to clean up event"
      end
    end

  end
end