class BaseNotification
  def notify(message)
    raise NotImplementedError, "Subclasses must implement #notify"
  end
end
