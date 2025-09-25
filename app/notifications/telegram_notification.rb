class TelegramNotification < BaseNotification
  def notify(message)
    Rails.logger.info("[Telegram] #{message}")

    token   = ENV["TG_BOT_TOKEN"]
    chat_id = ENV["TG_CHAT_ID"]

    unless token.present? && chat_id.present?
      Rails.logger.warn("TelegramNotification skipped: missing TG_BOT_TOKEN or TG_CHAT_ID")
      return
    end

    require 'telegram/bot'
    Telegram::Bot::Client.run(token) do |bot|
      bot.api.send_message(chat_id: chat_id.to_i, text: message)
    end

    Rails.logger.info("TelegramNotification sent successfully to chat_id=#{chat_id}")
  rescue Telegram::Bot::Exceptions::ResponseError => e
    Rails.logger.error("TelegramNotification failed (Telegram API): #{e.message}")
  rescue => e
    Rails.logger.error("TelegramNotification failed (unexpected): #{e.class} #{e.message}")
  end
end
