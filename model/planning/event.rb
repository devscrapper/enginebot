require 'ice_cube'
require 'json'
require 'uuid'
require 'eventmachine'

module TasksClient
  include EM::P::ObjectProtocol

  attr :event

  def initialize(event)
    @event = event
  end

  def post_init
    begin
      send_object @event

    rescue Exception => e
      raise "cannot send event to task_server : #{e.message}"

    end
  end

end

module Planning
  class Event

    PARAMETERS = "tasks_server.rb"

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
    # pre_tasks est un Array de object Event
    def initialize(label, periodicity, business, pre_tasks=[])
      raise "argument missing" if label.empty? or label.nil? or
          periodicity.nil? or
          business.empty? or business.nil?

      pre_tasks.each{|pt| raise "one pre_tasks is not Event class" unless pt.is_a?(Event)}

      @label = label
      @periodicity = periodicity
      @business = business
      # les pre-tasks contiennent l'id de l'event et pas le label, cela permet d'être assuré que l'event référence est lebon
      # independemment des dates et de la policy, des task qui sont a cheval sur plusieurs jours
      @pre_tasks = pre_tasks.map{|pt| pt.id}


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
      @key.merge!({:building_date => @business[:building_date].to_s}) if @periodicity.rrules[0].is_a?(IceCube::DailyRule) or
          @periodicity.rrules[0].is_a?(IceCube::HourlyRule)

    end

    def <=>(event)
      if has_pre_task?(event)
        event
      else
        self
      end
    end


    # retourne true si event est une pre-task de l'instance courante
    # il faut posseder l'id de vent pre-task
    def has_pre_task?(event)
      @pre_tasks.include?(event.id)
    end

    # deplace la task de l'event de pre_tasks_running vers pre_tasks_over
    def add_pre_task_over(event)
      @pre_tasks_over << event.id
      delete_pre_task_running(event)
    end

    # affect l'event dans le pre_rask_runing
    def add_pre_task_running(event)
      @pre_tasks_running << event.id
    end

    #retourne true si toutes les pre_task sont terminées
    # intersecion des 2 array et comparaison des tailles pour s"assurer qu'ils sont identiques
    def all_pre_tasks_over?
      (@pre_tasks_over & @pre_tasks).size == @pre_tasks.size
    end

    #TODO à supprimer qd toutes les task auront été refondu avec un object Task dans Task_server
    def business
      @business
    end

    # retourne la date de building de la clé si c'est une Event quotidien
    # sinon ""
    def building_date
      @key[:building_date].nil? ? "" : @key[:building_date]
    end

    # supprime l'event du pre_rask_runing
    def delete_pre_task_running(event)
      @pre_tasks_running.delete(event.id)
    end

    def execute
      begin
        parameters = Parameter.new(PARAMETERS)

      rescue Exception => e
        raise "cannot get task_server port : #{e.message}"

      else
        tasks_server_port = parameters.listening_port #TODO remplacer par une variable passée à la Connectiontask qui la passera à l'object Task dont héritera toutes les actions
        if tasks_server_port.nil?
          raise "task_server port not define"

        else
          EventMachine.connect "localhost", tasks_server_port, TasksClient, self

        end
      end

    end

    def failed
      @state = FAIL
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

    #self is before e
    def is_before?(e)
      (@periodicity.start_time.hour < e.periodicity.start_time.hour) or
          (@periodicity.start_time.hour == e.periodicity.start_time.hour and @periodicity.start_time.min < e.periodicity.start_time.min)
    end

    def is_finished
      @state = OVER
      @pre_tasks_over = []
    end

    def is_objective?
      !@business[:objective_id].nil?
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

    def policy_type
      @business[:policy_type]
    end

    def task_label
      @key[:task_label]
    end
    def to_s(*a)
      @key.to_s(*a)
    end


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
              #{building_date_display}
          #{pre_task_or_start_time_display}
          #{btn_execute_display}
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

    def website_label
      @business[:website_label]
    end


    private
    def btn_execute_display
      if $debugging
        <<-_end_of_html_
          <div class="sign">
            <a href="/tasks/execute/?id=#{@id}" class='button'>Execute</a>
          </div>
        _end_of_html_
      end
    end

    def building_date_display
      if !@key[:building_date].nil?
        <<-_end_of_html_
        <p>Building date : <span>#{@key[:building_date]}</span></p>
        _end_of_html_
      end
    end

    def pre_task_or_start_time_display
      if has_pre_tasks?
        <<-_end_of_html_
      <p>Pre tasks<br><span>#{@pre_tasks.join("<br>")}</span></p>
        _end_of_html_
      else
        <<-_end_of_html_
      <p>Start time : <span>#{@periodicity.start_time.hour}h#{@periodicity.start_time.min}</span></p>
        _end_of_html_
      end
    end


  end
end

