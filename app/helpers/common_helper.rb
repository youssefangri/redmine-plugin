module CommonHelper
  def user_or_anonymous(user)
    user.nil? ? User.anonymous : user
  end

  def user_name_or_anonymous(user)
    user.nil? ? l(:label_user_anonymous) : user.name
  end

  def user_name_or_anonymous_by_id(user_id)
    user = Principal.find_by(:id => user_id)
    user_name_or_anonymous(user)
  end

  def transform_user(record)
    {
      id: record.id,
      name: record.name,
      type: record.type
    }
  end

  def shorten_text(text, length = 30)
    return "" if text.nil?
    text.length > length ? '<strong>"' + text[0,length].to_s+ '..."</strong>' : '<strong>"' + text.to_s + '"</strong>'
  end

  def html_strong(text)
    '<strong>' + text.to_s + '</strong>'
  end

  def html_s(text)
    '<s>' + text.to_s + '</s>'
  end

end