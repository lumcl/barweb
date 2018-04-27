module FlashHelper

  def flash_messages
    messages = []
    flash.each do |key, msg|
      next if msg.blank?
      next unless msg.is_a? String
      bootstrap_class = "alert fade in alert-#{bootstrap_flash_type(key)}"
      messages << content_tag(:div, content_tag(:button, raw('&times;'),
                                                class: 'close',
                                                data: {dismiss: 'alert'}) + msg.html_safe, class: bootstrap_class)
    end
    flash.clear # empty so doesn't linger
    messages.join("\n").html_safe
  end

  private

  def bootstrap_flash_type(flash_type)
    return 'info' if flash_type == 'notice'
    return 'warning' if flash_type == 'alert'
    return 'danger' if flash_type == 'error'
    flash_type.to_s
  end

end
