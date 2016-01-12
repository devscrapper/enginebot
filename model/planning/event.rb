require 'ice_cube'
require 'json'
require 'uuid'


module Planning
  class Event

    #states
    OVER = "over"
    START = "start"
    INIT = 'init'
    FAIL = "fail"


    attr :key, # Hash de symbol
         :periodicity, #IceCube::Schedule
         :business, #Hash de symbol
         :state, #String
         :pre_tasks_over, #Array
         :pre_tasks_running, #Array
         :pre_tasks #Array

    attr_reader :id, #UUID
                :label #String

    # cree un objet Event (utilisé lors de la conversion d'un objet Objective/Traffic/Rank en liste d'Events)
    def initialize(label, periodicity, business, pre_tasks=[])
      raise "argument missing" if label.empty? or label.nil? or
          periodicity.nil? or
          business.empty? or business.nil?


      @label = label
      @periodicity = periodicity
      @business = business
      @pre_tasks = pre_tasks


      @id = UUID.generate(:compact)
      @state = INIT
      @pre_tasks_over = []
      @pre_tasks_running = []
      @key = {
          :policy_id => @business[:policy_id],
          :task_label => @label
      }

      # si planification quotidienne alors ajoute la date de planification à la clé
      # :building_date est Objet Date
      @key.merge!({:building_date => periodicity.next_occurrence.start_time.to_date}) if periodicity.rrules[0].is_a?(IceCube::DailyRule)

    end

    def <=>(event)
      if has_pre_task?(event)
        event
      else
        self
      end
    end


    # retourne la date de building de la clé si c'est une Event quotidien
    # sinon ""
    def building_date
      @key[:building_date].nil? ? "" : @key[:building_date]
    end

    # retourne true si event est une pre-task de l'instance courante
    # il faut être de la même policy
    # il faut avoir la même building_date si l'event qui vient de se terminer en a une sinon non
    def has_pre_task?(event)
      @key[:policy_id] == event.policy_id and
          @pre_tasks.include?(event.label) and
          (event.building_date == "" or @key[:building_date] == event.building_date)
    end

    # deplace la task de l'event de pre_tasks_running vers pre_tasks_over
    def add_pre_task_over(event)
      @pre_tasks_over << event.label
      @pre_tasks_running.delete(event.label)
    end

    # affect l'event dans le pre_rask_runing
    def add_pre_task_running(event)
      @pre_tasks_running << event.label
    end


    # supprime l'event du pre_rask_runing
    def delete_pre_task_running(event)
      @pre_tasks_running.delete(event.label)
    end

    #retourn true si event a au moins une pre_task
    def has_pre_tasks?
      !@pre_tasks.empty?
    end

    # retourn true si une pre_task est en cours d'exécution
    def has_pre_tasks_running?
      !@pre_tasks_running.empty?
    end

    def id
      @id
    end

    #retourne true si toutes les pre_task sont terminées
    # intersecion des 2 array et comparaison des tailles pour s"assurer qu'ils sont identiques
    def all_pre_tasks_over?
      (@pre_tasks_over & @pre_tasks).size == @pre_tasks.size
    end

    def failed
      @state = FAIL
    end

    def is_finished
      @state = OVER
      @pre_tasks_over = []
    end

    def is_objective?
      !@business[:objective_id].nil?
    end

    #self is before e
    def is_before?(e)
      (@periodicity.start_time.hour < e.periodicity.start_time.hour) or
          (@periodicity.start_time.hour == e.periodicity.start_time.hour and @periodicity.start_time.min < e.periodicity.start_time.min)
    end

    def is_started
      @state = START
      @pre_tasks_over = []
    end

    def is_started?
      @state == START
    end


    def policy_id
      @key[:policy_id]
    end

    def to_s(*a)
      @key.to_s(*a)
    end

    # def pre_tasks_to_html
    #
    #   @pre_tasks.map { |t|
    #     if @pre_tasks_over.include?(t)
    #       "<span class=\"green\">\"#{t}\"</span>"
    #     elsif @pre_tasks_running.include?(t)
    #       "<span class=\"purple\">\"#{t}\"</span>"
    #     else
    #       "<span class=\"pink\">\"#{t}\"</span>"
    #           end
    #        }.join("<br>")
    #
    # end

    # affiche au format html le contenu de l'event selon 2 niveau de details
    # :summary (par defaut)
    # :complete
    def to_html(details=:summary)
      case @state
        when START
          color="purple"
        when OVER
          color="green"
        when FAIL
          color="red"
        when INIT
          color="pink"
        else
          color="black"
      end

      case details
        when :summary
          <<-_end_of_html_
          <li>
            <div class="top">
              <h5>#{@label}</h5>
              <div class="circle #{color}"> #{@state} </div>
            </div>
            <div class="bottom">
              <p>Website<br><span>#{@business[:website_label]}</span></p>
              <p>Policy id : <span>#{@key[:policy_id]}</span></p>
              <p>Building date<br><span>#{@key[:building_date]}</span></p>
              <p>Pre tasks<br><span>#{@pre_tasks.join("<br>")}</span></p>
              <p>Start time : <span>#{@periodicity.start_time.hour}h#{@periodicity.start_time.min}</span></p>
              <div class="sign">
                <a href="/tasks/execute/?id=#{@id}" class='button'>Execute</a>
              </div>
            </div>
          </li>
          _end_of_html_
        when :complete
          <<-_end_of_html_
          <ul>
            <li><b>id</ b> : #{@id}</li>
            <li><b>key</b> : #{@key}</li>
            <li><b>label</b> : #{@label}</li>
            <li><b>state</b> : <font color="#{color}">#{@state}</font></li>
            <li><b>pre_tasks</ b> : #{@pre_tasks}</li>
            <li><b>pre_tasks_running</b> : #{@pre_tasks_running}</li>
            <li><b>pre_tasks_over</b> : #{@pre_tasks_over}</li>
            <li><b>periodicity</b> : #{@periodicity.to_s}</li>
            <li><b>business</b> : #{@business}</ li>
            <li><a href="/tasks/execute/?id=#{@id}">Execute</a></li>
          </ul>
          _end_of_html_
      end


    end

    def execute
      raise "event #{@label} already starting" if @state == START and $staging != 'development'
      require_relative 'task'
      #TODO reviser l'envoie de la demande en remplacant communication.rb par un objet Task et mak de task_server en accepter un objet
      begin
        data = {
            :event_id => @id,
            :website_label => @business[:website_label],
            :building_date => @key[:building_date] || Date.today}
        data.merge!(@business)
        Tasking::Task.new(@label, data).execute
      rescue Exception => e
        raise "cannot execute event <#{@label}> for <#{@business[:website_label]}> : #{e.message}"
      end
    end

  end


end