 class DispatcherNotification
    CHANNELS = {
      telegram: TelegramNotification,
      logs: LogNotification,
      email: EmailNotification,
    }.freeze

    def self.dispatch(payload, channels: [])
      channels.each do |channel_key|
        klass = CHANNELS[channel_key.to_sym]
        next unless klass
        klass.new.notify(payload)
      end
    end
  end

