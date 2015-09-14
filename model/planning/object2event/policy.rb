require_relative '../event'
module Planning

  class Policy
    BUILDING_OBJECTIVES_DAY = -3 * IceCube::ONE_DAY #on decale d'un  jour j-3
    BUILDING_OBJECTIVES_HOUR = 12 * IceCube::ONE_HOUR #heure de démarrage est 12h du matin
    BUILDING_MATRIX_AND_PAGES_DAY = -1 * IceCube::ONE_DAY #on decale d'un  jour j-1
    BUILDING_MATRIX_AND_PAGES_HOUR = 0 * IceCube::ONE_HOUR #heure de démarrage est 0h du matin
    attr :label,
         :website_id,
         :policy_id,
         :count_weeks,
         :monday_start

      #TODO meo ces données dans statupweb
    MIN_COUNT_PAGE_ADVERTISER = 10 # nombre de page min consultées chez l'advertiser : fourni par statupweb
    MAX_COUNT_PAGE_ADVERTISER = 15 # nombre de page max consultées chez l'advertiser : fourni par statupweb
    MIN_DURATION_PAGE_ADVERTISER = 60 # durée de lecture min d'une page max consultées chez l'advertiser : fourni par statupweb
    MAX_DURATION_PAGE_ADVERTISER = 120 # durée de lecture max d'une page max consultées chez l'advertiser : fourni par statupweb
    PERCENT_LOCAL_PAGE_ADVERTISER = 80 # pourcentage de page consultées localement à l'advertiser fournit par statupweb
    DURATION_REFERRAL = 20 # durée de lecture du referral : fourni par statupweb
    MIN_COUNT_PAGE_ORGANIC = 4 #nombre min de page de resultat du moteur de recherche consultées : fourni par statupweb
    MAX_COUNT_PAGE_ORGANIC = 6 #nombre min de page de resultat du moteur de recherche consultées : fourni par statupweb
    MIN_DURATION_PAGE_ORGANIC = 10 #durée de lecture min d'une page de resultat fourni par le moteur de recherche : fourni par statupweb
    MAX_DURATION_PAGE_ORGANIC = 30 #durée de lecture max d'une page de resultat fourni par le moteur de recherche : fourni par statupweb

    MIN_DURATION_SURF = 5 # temps en seconde min de lecture d'une page d'un site consulté avant d'atterrir sur le website
    MAX_DURATION_SURF = 10 # temps en seconde min de lecture d'une page d'un site consulté avant d'atterrir sur le website
    # 10, #min_durations  #TODO à variabiliser un jour ?
    #                   2, #min_pages #TODO à variabiliser un jour ?

    def initialize(data)
      @label = data["label"]
      @monday_start = Time.local(data["monday_start"].year, data["monday_start"].month, data["monday_start"].day) unless data["monday_start"].nil? # iceCube a besoin d'un Time et pas d'un Date
      @count_weeks = data["count_weeks"]
      @website_id=data["website_id"]
      @policy_id=data["policy_id"]
    end


  end

end