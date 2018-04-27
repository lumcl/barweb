module NavbarHelper

  def active_tab(tab)
    (params[:controller] == tab) ? 'active' : ''
  end

  def spinner_tag(id)
    # Assuming spinner image is called "spinner.gif"
    image_tag('spinner.gif', id: id, alt: t('label.loading'), style: 'display:none')
  end

  def avatar_url(user)
    return user.image_url if user.image_url?
    gravatar_id = Digest::MD5::hexdigest(user.email).downcase # rubocop:disable all
    "http://gravatar.com/avatar/#{gravatar_id}.png?r=g&s=30&d=mm"
  end

end
