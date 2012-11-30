class Objective
  COUNT_VISIT = 100
  attr :label,
       :date
  def initialize(label, date)
    @date = date
    @label = label
  end

  def count_visits()
    COUNT_VISIT
  end

  def landing_pages()
    direct_medium_percent = 60 # sera calculé en fonction des objectif
    organic_medium_percent = 20 # sera calculé en fonction des objectif
    referral_medium_percent = 20 # sera calculé en fonction des objectif

    [COUNT_VISIT, direct_medium_percent,organic_medium_percent, referral_medium_percent]
  end

  def behaviour()
    visit_bounce_rate = 60
    page_views_per_visit = 2
    avg_time_on_site = 120
    min_durations = 1
    min_pages = 2
    [COUNT_VISIT,visit_bounce_rate,page_views_per_visit, avg_time_on_site, min_durations, min_pages ]
  end

  def details()
    account_ga = "UA-XXXXXX"
    return_visitor_rate = 40
    [COUNT_VISIT,account_ga,return_visitor_rate ]
  end

  def daily_planification()
    hourly_distribution = "0;0;0;1;2;3;3.5;3.5;3;2;1;0.5;1;2;3;6;8;10;11;12;12;11.5;2;2"
    [COUNT_VISIT, hourly_distribution]
  end
end