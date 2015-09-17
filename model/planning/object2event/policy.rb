require_relative '../event'
module Planning

  class Policy
    BUILDING_OBJECTIVES_DAY = -3 * IceCube::ONE_DAY #on decale d'un  jour j-3
    BUILDING_OBJECTIVES_HOUR = 12 * IceCube::ONE_HOUR #heure de démarrage est 12h du matin
    BUILDING_MATRIX_AND_PAGES_DAY = -1 * IceCube::ONE_DAY #on decale d'un  jour j-1
    BUILDING_MATRIX_AND_PAGES_HOUR = 0 * IceCube::ONE_HOUR #heure de démarrage est 0h du matin
    attr :website_label,
         :website_id,
         :policy_id,
         :count_weeks,
         :monday_start,
         :min_count_page_advertiser,
         :max_count_page_advertiser,
         :min_duration_page_advertiser,
         :max_duration_page_advertiser,
         :percent_local_page_advertiser,
         :duration_referral,
         :min_count_page_organic,
         :max_count_page_organic,
         :min_duration_page_organic,
         :max_duration_page_organic,
         :min_duration,
         :max_duration,
         :min_duration_website,
         :min_pages_website

    def initialize(data)
      @website_label = data[:website_label]
      @monday_start = Time.local(data[:monday_start].year, data[:monday_start].month, data[:monday_start].day) unless data[:monday_start].nil? # iceCube a besoin d'un Time et pas d'un Date
      @count_weeks = data[:count_weeks]
      @website_id = data[:website_id]
      @policy_id = data[:policy_id]
      @min_count_page_advertiser = data[:min_count_page_advertiser]
      @max_count_page_advertiser = data[:max_count_page_advertiser]
      @min_duration_page_advertiser = data[:min_duration_page_advertiser]
      @max_duration_page_advertiser = data[:max_duration_page_advertiser]
      @percent_local_page_advertiser = data[:percent_local_page_advertiser]
      @duration_referral = data[:duration_referral]
      @min_count_page_organic = data[:min_count_page_organic]
      @max_count_page_organic = data[:max_count_page_organic]
      @min_duration_page_organic = data[:min_duration_page_organic]
      @max_duration_page_organic = data[:max_duration_page_organic]
      @min_duration = data[:min_duration]
      @max_duration = data[:max_duration]
      @min_duration_website = data[:min_duration_website]
      @min_pages_website = data[:min_pages_website]
    end



  end

end