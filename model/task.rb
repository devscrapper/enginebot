 # definition des conditions d'exécution des taches
  # à chaque tache est associé un nombre d'operation qui doit être réalisée en amont
  #COUNT_TASK_BEFORE_BUILDING_DEVICE_PLATFORME = 2 #tasks : file(Device_platform_plugin), file(Device_platform_resolution)
  #COUNT_TASK_BEFORE_BUILDING_VISITS = 3  #tasks : Choosing_device_platform, Choosing_landing_pages, Calendar
  # hash faisant le suivi de l'etat des conditions de démarrage par task, en fonction du label
  # @@condition_start = {label => {Building_device_platform => COUNT_TASK_BEFORE_BUILDING_DEVICE_PLATFORME},
  #                               {Building_visits} => COUNT_TASK_BEFORE_BUILDING_VISITS}

class Start_conditions
  attr :conditions

  def initialize()
     @conditions = {}
  end

  def add(task)
    @conditions[task.label] = {} if @conditions[task.label].nil?
    @conditions[task.label][task.name] = task.count_prior_tasks if     @conditions[task.label][task.name].nil?
  end

  def decrement(task)
    @conditions[task.label][task.name] -= 1
  end

  def execute?(task)
    @conditions[task.label][task.name] == 0
  end

  def delete(task)
    @conditions[task.label].delete(task.name) if @conditions[task.label][task.name] <= 0
    @conditions.delete(task.label) if @conditions[task.label].empty?
  end
end


class Task
  attr_reader :count_prior_tasks,
              :label,
              :name


  def initialize(name, label, count_prior_tasks)
    @count_prior_tasks = count_prior_tasks
    @name = name
    @label = label
  end

end


class Task_building_device_platform < Task
  def initialize(label)
    super("Building_device_platform", label, 2)
  end
end

class Task_building_visits  < Task
  def initialize(label)
    super("Building_visits", label, 3)
  end
end


class Task_building_objectives  < Task
  def initialize(label)
    super("Building_objectives", label, 1)
  end
end