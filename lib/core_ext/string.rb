require_relative 'constants'

class String
  include Constants

  def to_date
    t = Time.parse(self)
    t.localtime.strftime(DATE_FORMAT)
  end

  def to_report_date
    t = Time.parse(self)
    t.localtime.strftime('%A, %d %b %Y %H:%M')
  end

  # Naive conversion to title case.
  def to_title_case
    split.map(&:capitalize).join(' ')
  end
end
