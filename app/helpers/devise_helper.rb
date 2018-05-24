# frozen_string_literal: true

module DeviseHelper

  def devise_error_messages!
    flash_alerts = []
    error_key = 'errors.messages.not_saved'

    if !flash.empty?
      flash_alerts.push(flash[:error]) if flash[:error]
      flash_alerts.push(flash[:alert]) if flash[:alert]
      flash_alerts.push(flash[:notice]) if flash[:notice]
      error_key = 'devise.failure.invalid' unless flash[:notice].present?
    end

    return '' if resource.errors.empty? && flash_alerts.empty?

    errors = resource.errors.empty? ? flash_alerts : resource.errors.full_messages

    messages = errors.map { |msg| content_tag(:li, msg) }.join

    sentence = unless flash[:notice].present?
                 I18n.t(error_key, :count    => errors.count,
                                   :resource => resource.class.model_name.human.downcase)
               else
                 ''
               end

    html = <<-HTML
    <div id="error_explanation">
      <h2>#{sentence}</h2>
      <ul>#{messages}</ul>
    </div>
    HTML

    html.html_safe
  end

end
