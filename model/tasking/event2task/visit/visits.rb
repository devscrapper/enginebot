#!/usr/bin/env ruby -w
# encoding: UTF-8
require_relative '../../../../lib/logging'
require_relative 'visit'
require_relative 'page'
require_relative '../reporting'
require 'ruby-progressbar'
#------------------------------------------------------------------------------------------
# Pre requis gem
#------------------------------------------------------------------------------------------


module Tasking
  module Visit
    class Visits


      include Tasking
#------------------------------------------------------------------------------------------
# Globals variables
#------------------------------------------------------------------------------------------
      OUTPUT = File.dirname(__FILE__) + "/../../../../output"
      TMP = File.expand_path(File.join("..", "..", "..", "..", "..", "tmp"), __FILE__)
      PROGRESS_BAR_SIZE = 180
      SEPARATOR1=";"
      SEPARATOR2="|"
      SEPARATOR3=","
      EOFLINE ="\n"

# local
      attr :matrix,
           :duration_pages,
           :visits,
           :children,
           :matrix_file,
           :count_visits_by_hour,
           :planed_visits_by_hour_file,
           :label,
           :date_building,
           :policy_type,
           :website_id,
           :policy_id,
           :execution_mode # mode d'execution de la policy : manuel (Piloté au moyen de statupweb) ou auto (piloté par Calendar)
# le mode d'execution n'est utilisé que pour le publishing car on souhaite adapté le comportement
# de la task Publishing en fonction
      def initialize(label, date_building, policy_type, website_id, policy_id, execution_mode=nil)
        @website_label = label
        @date_building = date_building
        @policy_type = policy_type
        @website_id = website_id
        @policy_id = policy_id
        @execution_mode = execution_mode
        @logger = Logging::Log.new(self, :staging => $staging, :debugging => $debugging)
      end

#--------------------------------------------------------------------------------------------------------------
# Building_visits
#--------------------------------------------------------------------------------------------------------------
# Construit les visites en fonction des proprietes de l'objectif du jour :
# le taux de visite rebond
# le nombre de page par visite
# le temps moyen d'une visite sur le site
# la duree minimale d'exposition d'une page
# le nombre de page minimal de page par visite
# --------------------------------------------------------------------------------------------------------------


      def Building_visits(count_visit,
                          visit_bounce_rate,
                          page_views_per_visit,
                          avg_time_on_site,
                          min_durations,
                          min_pages)
        @logger.an_event.debug("Building visits for <#{@policy_type}> <#{@website_label}> <#{@date_building}> is starting")
        begin

          @logger.an_event.debug("count_visit #{count_visit}")
          @logger.an_event.debug("visit_bounce_rate #{visit_bounce_rate}")
          @logger.an_event.debug("page_views_per_visit #{page_views_per_visit}")
          @logger.an_event.debug("avg_time_on_site #{avg_time_on_site}")
          @logger.an_event.debug("min_durations #{min_durations}")
          @logger.an_event.debug("min_pages #{min_pages}")


          reporting = Reporting.new(@website_label, @date_building, @policy_type)
          reporting.visit_obj(count_visit, visit_bounce_rate, page_views_per_visit, avg_time_on_site, min_durations, min_pages)
          reporting.to_file("visit objective")


          chosen_landing_pages_file = Flow.new(TMP, "chosen-landing-pages", @policy_type, @website_label, @date_building) #input
          raise IOError, "tmp flow <#{chosen_landing_pages_file.basename}> is missing" unless chosen_landing_pages_file.exist?
          count_chosen_landing_page = chosen_landing_pages_file.count_lines(EOFLINE)
          raise ArgumentError, "because not enough count landing page <#{count_chosen_landing_page}> for <#{count_visit}> visits" if count_chosen_landing_page < count_visit
          @logger.an_event.warn "too much count landing page <#{count_chosen_landing_page}> for <#{count_visit}> visits" if count_chosen_landing_page > count_visit
          count_pages = (count_visit * page_views_per_visit).to_i
          count_durations = (count_visit * avg_time_on_site).to_i
          @duration_pages = distributing(count_pages, count_durations, min_durations)
          min_duration_idx = @duration_pages.index(@duration_pages.min)
          if min_duration_idx > 0
            min_duration = @duration_pages[min_duration_idx]
            @duration_pages.delete_at(min_duration_idx)
            @duration_pages = [min_duration] + @duration_pages
          end

          @visits = []
          p = ProgressBar.create(:title => title("Loading chosen landing pages"), :length => PROGRESS_BAR_SIZE, :starting_at => 0, :total => count_visit, :format => '%t, %c/%C, %a|%w|')
          chosen_landing_pages_file.foreach(EOFLINE) { |page|
            @logger.an_event.debug("page  #{page}")
            @visits << Visit.new(page, @website_label, @duration_pages.pop)
            p.increment
          }

          building_not_bounce_visit(visit_bounce_rate, count_visit, page_views_per_visit, min_pages)

          @visits_file = Flow.new(TMP, "visits", @policy_type, @website_label, @date_building) #output
          p = ProgressBar.create(:title => title("Saving visits"), :length => PROGRESS_BAR_SIZE, :starting_at => 0, :total => count_visit, :format => '%t, %c/%C, %a|%w|')
          @visits.each { |visit| @visits_file.write("#{visit.to_s}#{EOFLINE}"); p.increment }
          @visits_file.close
          @visits_file.archive_previous

        rescue Exception => e
          @logger.an_event.error ("Building visits for <#{@policy_type}> <#{@website_label}> is over =>  #{e.message}")
          raise e
        else
          @logger.an_event.debug("Building visits for <#{@policy_type}> <#{@website_label}> is over")
        end
      end

#--------------------------------------------------------------------------------------------------------------
# Building_planification
#--------------------------------------------------------------------------------------------------------------
#
# --------------------------------------------------------------------------------------------------------------
      def Building_planification(hourly_distribution, count_visits)
        @logger.an_event.debug("Building planification of visit for <#{@policy_type}> <#{@website_label}>  <#{@date_building}> is starting")
        begin
          reporting = Reporting.new(@website_label, @date_building, @policy_type)
          reporting.planification_obj(hourly_distribution)
          reporting.to_file("planification objective")

          visits_tmp = Flow.new(TMP, "visits", @policy_type, @website_label, @date_building)
          raise IOError, "tmp flow <#{visits_tmp.basename}> is missing" unless visits_tmp.exist?
          count_visits_of_day = 0
          hourly_distribution.split(SEPARATOR2).each { |count_visit_per_hour| count_visits_of_day += count_visit_per_hour.to_i }
          raise ArgumentError, "sum of hourly distribution of visits is different count visits" unless count_visits_of_day == count_visits

          @logger.an_event.debug "param count_visits #{count_visits}"
          @planed_visits_by_hour_file = []
          @count_visits_by_hour =[]
          hour = 0
          hourly_distribution.split(SEPARATOR2).each { |count_visits_per_hour|
            @count_visits_by_hour[hour] = [hour, count_visits_per_hour.to_i]
            hour += 1
          }
          @logger.an_event.debug "@count_visits_by_hour #{@count_visits_by_hour}"
          hour = 0
          count_visits_of_day_origin = 0
          #initialisation des fichier à empty car il se peut que pour une une heure il n y ait pas de visit,
          # il faut qd même crer un fichier vide pour eviter que l'extending échoue et
          # cela eviter de se poser des questions sur l'absence de fichier
          24.times { |anhour| Flow.new(TMP, "planed-visits", @policy_type, @website_label, @date_building, anhour + 1).empty }

          @count_visits_by_hour.each { |count_visit_per_hour| count_visits_of_day_origin += count_visit_per_hour[1].to_i }
          @logger.an_event.debug "@count_visits_by_hour #{@count_visits_by_hour}"
          @logger.an_event.debug "@count_visits_by_hour.size #{@count_visits_by_hour.size}"
          @logger.an_event.debug "total visit of @count_visits_by_hour #{count_visits_of_day_origin}"


          @count_visits_by_hour.size.times { |anhour|
            @planed_visits_by_hour_file[anhour] = Flow.new(TMP, "planed-visits", @policy_type, @website_label, @date_building, anhour + 1)
            @logger.an_event.debug @planed_visits_by_hour_file[anhour].basename
          }


          p = ProgressBar.create(:title => title("Saving planed visits"), :length => PROGRESS_BAR_SIZE, :starting_at => 0, :total => count_visits, :format => '%t, %c/%C, %a|%w|')

          visits_tmp.foreach(EOFLINE) { |visit|

            @logger.an_event.debug "@count_visits_by_hour #{@count_visits_by_hour}"
            hour = chose_an_hour()
            v = Planed_visit.new(visit, @date_building, hour)
            @logger.an_event.debug hour
            @logger.an_event.debug @planed_visits_by_hour_file[hour].basename
            @planed_visits_by_hour_file[hour].write("#{v.to_s}#{EOFLINE}")
            p.increment
          }

          24.times { |anhour| @planed_visits_by_hour_file[anhour].close }


        rescue Exception => e
          @logger.an_event.error ("Building planification of visit for  <#{@policy_type}> <#{@website_label}> <#{@date_building}> is over =>  #{e.message}")
          raise e
        else
          @logger.an_event.debug("Building planification of visit for  <#{@policy_type}> <#{@website_label}> <#{@date_building}> is over")
        end
      end

#--------------------------------------------------------------------------------------------------------------
# Extending_visits
#--------------------------------------------------------------------------------------------------------------
#
# --------------------------------------------------------------------------------------------------------------
      def Extending_visits(count_visit,
                           advertising_percent,
                           advertisers)
        @logger.an_event.debug("Extending visits for <#{@policy_type}> <#{@website_label}> <#{@date_building}> is starting")
        @logger.an_event.debug("advertising_percent #{advertising_percent}")
        @logger.an_event.debug("advertisers #{advertisers}")
        begin
          reporting = Reporting.new(@website_label, @date_building, @policy_type)
          reporting.advertising_obj(advertising_percent, advertisers)
          reporting.to_file("advertising objective")

          device_platform_file = Flow.new(TMP, "chosen-device-platform", @policy_type, @website_label, @date_building)
          raise IOError, "tmp flow <#{device_platform_file.basename}>  is missing" unless device_platform_file.exist?
          count_device_platform = device_platform_file.count_lines(EOFLINE)
          raise ArgumentError, "not enough count device platform <#{count_device_platform}> for <#{count_visit}> visits" if count_device_platform < count_visit
          @logger.an_event.warn "too much count device platform <#{count_device_platform}> for <#{count_visit}>  visits" if count_device_platform > count_visit

          #initialisation des fichier à empty car il se peut que pour une une heure il n y ait pas de visit,
          # et que le fichier soit vide.
          # il faut qd même crer un fichier final- vide pour eviter que le publishing échoue et
          # cela eviter de se poser des questions sur l'absence de fichier
          24.times { |anhour| Flow.new(TMP, "final-visits", @policy_type, @website_label, @date_building, anhour + 1).empty }

          device_platforms = device_platform_file.readlines(EOFLINE).shuffle
          @logger.an_event.debug device_platforms

          adverts = Array.new(count_visit, "none")
          adverts.fill(advertisers.shuffle![0], 0..(count_visit * advertising_percent / 100).to_i).shuffle!

          p = ProgressBar.create(:title => title("Saving Final visits"), :length => PROGRESS_BAR_SIZE, :starting_at => 0, :total => count_visit, :format => '%t, %c/%C, %a|%w|')

          24.times { |hour|
            final_visits_by_hour_file = Flow.new(TMP, "final-visits", @policy_type, @website_label, @date_building, hour + 1) #output
            planed_visits_file = Flow.new(TMP, "planed-visits", @policy_type, @website_label, @date_building, hour + 1) #input
            raise IOError, "tmp flow <#{planed_visits_file.basename}> is missing" unless planed_visits_file.exist?
            planed_visits_file.foreach(EOFLINE) { |visit|

              advert = adverts.shift
              begin
                v = Final_visit.new(visit, @policy_type, advert, device_platforms.shift)
                final_visits_by_hour_file.write("#{v.to_s}#{EOFLINE}")
              rescue Exception => e
                @logger.an_event.debug visit
                @logger.an_event.debug e
                raise StandardError, "cannot create or save final visit"
              end
              p.increment
            } unless planed_visits_file.zero?
            planed_visits_file.close
            final_visits_by_hour_file.close
            planed_visits_file.archive_previous # conserve le dernier fichier pour reconstuire le JDD qd il y a un pb
          }
          device_platform_file.close


        rescue Exception => e
          @logger.an_event.error("Extending visits for <#{@policy_type}> #{@website_label} <#{@date_building}>is over =>  #{e.message}")
          raise e
        else
          @logger.an_event.debug("Extending visits for <#{@policy_type}> #{@website_label} <#{@date_building}> is over")
        end
      end

#--------------------------------------------------------------------------------------------------------------
# Reporting_visits
#--------------------------------------------------------------------------------------------------------------
#
# --------------------------------------------------------------------------------------------------------------
      def Reporting_visits
        @logger.an_event.debug("Reporting visits for <#{@policy_type}> #{@website_label} #{@date_building} is starting")
        start_time = Time.now
        begin
          reporting = Reporting.new(@website_label, @date_building, @policy_type)
          p = ProgressBar.create(:title => title("Reporting visits"), :length => PROGRESS_BAR_SIZE, :starting_at => 0, :total => 24, :format => '%t, %c/%C, %a|%w|')

          24.times { |hour|
            final_visits_by_hour_file = Flow.new(TMP, "final-visits", @policy_type, @website_label, @date_building, hour + 1) #input

            raise IOError, "tmp flow <#{final_visits_by_hour_file.basename}> is missing" unless final_visits_by_hour_file.exist?

            final_visits_by_hour_file.foreach(EOFLINE) { |visit|
              begin
                reporting.visit(Published_visit.new(visit))
              rescue Exception => e
                @logger.an_event.debug visit.to_s
                @logger.an_event.error "cannot report visit : #{e.message}"
              end

            } unless final_visits_by_hour_file.zero?
            final_visits_by_hour_file.close
            p.increment
          }

          reporting.to_file("statistics")
          reporting.to_mail
          reporting.archive
        rescue Exception => e
          @logger.an_event.error("Reporting visits for <#{@policy_type}> #{@website_label} #{@date_building} over => #{e.message}")
          raise e
        else
          @logger.an_event.debug("Reporting visits for <#{@policy_type}> #{@website_label} is over (#{Time.now - start_time})")
        end

      end

#--------------------------------------------------------------------------------------------------------------
# Publishing_visits
#--------------------------------------------------------------------------------------------------------------
#
# --------------------------------------------------------------------------------------------------------------
      def Publishing_visits_by_hour(min_count_page_advertiser,
                                    max_count_page_advertiser,
                                    min_duration_page_advertiser,
                                    max_duration_page_advertiser,
                                    percent_local_page_advertiser,
                                    duration_referral,
                                    min_count_page_organic,
                                    max_count_page_organic,
                                    min_duration_page_organic,
                                    max_duration_page_organic,
                                    min_duration,
                                    max_duration,
                                    fqdn_advertisings=nil)
        # le déclenchement de la publication est réalisée 2 heures avant l'heure d'exécution proprement dite des visits
        # de 22:00 à j-1 pour j à 00:00
        # à
        # de 21:00 à j pour j à 23:00
        # ce parametrage est réalisé lors de la transformation des objectives en events dans le fichier model/planning/object2event/objective.rb
        # cela entraine qu'il faut ajouter 2 heures pour le nom du output flow
        #
        # autre point :
        # les flow final_visit sont suffixés par l'heure déclenchement des visits de 1 à 24 hour.
        # cela entraine qu'il faut ajouter 1 heure à l'heure courante pour récupérer le bon volume du flow final_visit.
        # de 22:00 à j-1 pour j à 00:00 => final_visits_J_1.txt & publishing_visits_J_1.json
        # de 23:00 à j-1 pour j à 01:00 => final_visits_J_2.txt & publishing_visits_J_2.json
        # de 0:00 à j pour j à 02:00 => final_visits_J_3.txt & publishing_visits_J_3.json
        # de 1:00 à j pour j à 03:00 => final_visits_J_4.txt & publishing_visits_J_4.json
        # à
        # de 21:00 à j pour j à 23:00   => final_visits_J_24.txt & publishing_visits_J_24.json
        #---------------------------
        # -----------------------------
        # si execution_mode = auto alors le scheduler prend en charge l'envoie du flow visit vers le bon statupbot (comportement nominal)
        # si execution_mode = manual alors le flow visit est déposé directement dans le repertoire OUTPUT comme si il avait été
        # publié par le scheduler. l'envoie du flow vers statupbot sera déclenché par statupweb par le serveur http scheduling/connection.rb
        # ------------------------------
        current_time = Time.now
        an_hour = 60 * 60
        selected_time = current_time + (2 * an_hour)
        hour = selected_time.hour + 1 #hour est seulement utilisé pour construire le nom du flow.
        @logger.an_event.debug "current time <#{current_time}>, selected day <#{@date_building}>, selected hour <#{hour}>"
        @logger.an_event.debug("Publishing at #{current_time} visits for <#{@policy_type}> #{@website_label} #{@date_building}:#{hour}:00 is starting")
        begin
          final_visits_file = Flow.new(TMP, "final-visits", @policy_type, @website_label, @date_building, hour) #input
          raise IOError, "tmp flow <#{final_visits_file.basename}> is missing" unless final_visits_file.exist?

          p = ProgressBar.create(:title => "Publishing #{final_visits_file.basename}", :length => PROGRESS_BAR_SIZE, :starting_at => 0, :total => final_visits_file.count_lines(EOFLINE), :format => '%t, %c/%C, %a|%w|')
          final_visits_file.foreach(EOFLINE) { |visit|
            begin
              v = Published_visit.new(visit,
                                      min_count_page_advertiser,
                                      max_count_page_advertiser,
                                      min_duration_page_advertiser,
                                      max_duration_page_advertiser,
                                      percent_local_page_advertiser,
                                      duration_referral,
                                      min_count_page_organic,
                                      max_count_page_organic,
                                      min_duration_page_organic,
                                      max_duration_page_organic,
                                      min_duration,
                                      max_duration,
                                      fqdn_advertisings)
              start_date_time = v.start_date_time.strftime("%Y-%m-%d-%H-%M-%S")

              dir, ext = @execution_mode == "auto" ? [TMP, ".yml"] : [OUTPUT, ".man"]

              published_visits_to_yaml_file = Flow.new(dir, "#{v.operating_system}-#{v.operating_system_version}", @policy_type, @website_label, start_date_time, v.id_visit, ext)
              published_visits_to_yaml_file.write(v.to_yaml(@policy_type))
              published_visits_to_yaml_file.close

            rescue Exception => e
              @logger.an_event.debug visit
              @logger.an_event.error "cannot generate yaml published visit file for visit #{v.id_visit} : #{e.message}"
            else
              @logger.an_event.debug "generate yaml published visit file for visit #{v.id_visit}"
              begin
                send_to_statupweb(published_visits_to_yaml_file)

              rescue Exception => e
                @logger.an_event.error "cannot push to statupweb visit file #{v.id_visit} : #{e}"
              else

              end
            ensure
              p.increment
            end
          } unless final_visits_file.zero?
          final_visits_file.archive_previous # conserve le dernier fichier pour reconstuire le JDD qd il y a un pb
        rescue Exception => e

          @logger.an_event.error ("Publishing  at #{current_time} visits for <#{@policy_type}> #{@website_label} #{@date_building}:#{hour}:00 is over => #{e.message}")
          raise e
        else

          @logger.an_event.debug("Publishing  at #{current_time} visits for <#{@policy_type}> #{@website_label} #{@date_building}:#{hour}:00 is over")
        end
      end

#--------------------------------------------------------------------------------------------------------------
# private
#--------------------------------------------------------------------------------------------------------------
      def building_not_bounce_visit(visit_bounce_rate, count_visit, page_views_per_visit, min_pages)
        @logger.an_event.debug("Building not bounce visit for <#{@policy_type}> #{@website_label} #{@date_building} is starting")
        begin
          count_bounce_visit = (visit_bounce_rate * count_visit/100).to_i
          count_not_bounce_visit = count_visit - count_bounce_visit
          count_pages_bounce_visit = count_bounce_visit
          count_pages_not_bounce_visit = (count_visit * page_views_per_visit).to_i - count_pages_bounce_visit
          count_pages_per_visits = distributing(count_not_bounce_visit, count_pages_not_bounce_visit, min_pages)
          @logger.an_event.debug("count_bounce_visit #{count_bounce_visit}")
          @logger.an_event.debug("count_not_bounce_visit #{count_not_bounce_visit}")
          @logger.an_event.debug("count_pages_not_bounce_visit #{count_pages_not_bounce_visit}")
          @logger.an_event.debug("count_pages_per_visits #{count_pages_per_visits}")

          p = ProgressBar.create(:title => title("Building not bounce visits"), :length => PROGRESS_BAR_SIZE, :starting_at => 0, :total => count_not_bounce_visit, :format => '%t, %c/%C, %a|%w|')
          count_not_bounce_visit.times { |visit|
            # recherche une visite qui n'est pas bounce cad > 1 page

            begin
              v = @visits.shuffle![0]
              @logger.an_event.debug("prospect #{v} for #{@website_label}")
            end while !v.bounce?

            @logger.an_event.debug("Add #{count_pages_per_visits[visit]} page to visit #{v} for #{@website_label}")

            (count_pages_per_visits[visit] - 1).times { |i|
              d = @duration_pages.pop
              @logger.an_event.debug("#{i} -> delay #{d} ")
              v.add_page(d) }

            p.increment
          }

        rescue Exception => e
          @logger.an_event.error("Building not bounce visit for <#{@policy_type}> #{@website_label} is over =>  #{e.message}")
          raise StandardError, "cannot build not bounce visit"
        end
        @logger.an_event.debug("Building not bounce visit for <#{@policy_type}> #{@website_label} is over")
      end


      private
      def title(action, policy = @policy_type, label = @website_label, date = @date_building)
        [action, policy, label, date].join(" | ")
      end


      def unite(i, count=0)
        if i < 10
          count
        else
          unite(i.divmod(10)[0], count+1)
        end
      end

      def distributing(into, values, min_values_per_into)
        #p into
        #p values
        @logger.an_event.debug("Distributing for <#{@policy_type}> #{@website_label} #{@date_building} is starting")
        begin
          values_per_into = (values/into).to_i
          max_values_per_into = 2 * values_per_into - min_values_per_into
          res = Array.new(into, values_per_into)

          values.modulo(into).times { |i| res[i]+=1 } #au cas ou la div est un reste > 0 alors on perd des pages donc on les repartit n'importe ou.

          # si le value par into est egal à 2 ou
          # si le nombre de into <= à 2 alors il est impossible de calculer une distribution
          # alors on retourne un ensemble de into ayant un nombre de value egal à 2
          if values_per_into > min_values_per_into and
              into > 2
            plus = 0
            moins = 0

            (10 ** (unite(into) + 4)).times {
              ok = false
              while !ok
                plus = rand(res.size-1)
                moins = rand(res.size-1)
                if plus != moins and res[plus] < max_values_per_into and res[moins] > min_values_per_into
                  ok = true
                end
              end
              res[plus] += 1
              res[moins] -= 1

            }
          end
        rescue Exception => e
          @logger.an_event.error("Distributing for <#{@policy_type}> #{@website_label} #{@date_building} is over => #{e.message}")
        else
          @logger.an_event.debug("Distributing for <#{@policy_type}> #{@website_label} #{@date_building} is over")
        end
        res
      end

      def chose_an_hour
        @count_visits_by_hour.delete_if { |value| value[1] == 0 }
        @logger.an_event.debug "@count_visits_by_hour: #{@count_visits_by_hour}"
        @logger.an_event.debug "@count_visits_by_hour.size: #{@count_visits_by_hour.size}"
        hour = rand(@count_visits_by_hour.size - 1).to_i
        @logger.an_event.debug "hour selected: #{hour}/#{@count_visits_by_hour[hour][0]}"
        @count_visits_by_hour[hour][1] -= 1
        @logger.an_event.debug "@count_visits_by_hour[#{@count_visits_by_hour[hour][0]}]: #{@count_visits_by_hour[hour][1]}"
        @count_visits_by_hour[hour][0]
      end


      def min(a, b)
        a < b ? a : b
      end

      def send_to_statupweb(visit_flow)
        #informe statupweb de la creation d'une nouvelle visite
        # en cas d'erreur on ne leve as de'exception car c'est de la communication
        begin
          visit_tmp = YAML::load(visit_flow.read)

          visit = {:policy_id => @policy_id,
                   :policy_type => visit_tmp[:visit][:type].to_s,
                   :id_visit => visit_tmp[:visit][:id],
                   :execution_mode => @execution_mode,
                   :plan_time => visit_tmp[:visit][:start_date_time],
                   :referrer => visit_tmp[:visit][:referrer][:medium],
                   :browser_name => visit_tmp[:visitor][:browser][:name],
                   :browser_version => visit_tmp[:visitor][:browser][:version],
                   :operating_system_name => visit_tmp[:visitor][:browser][:operating_system],
                   :operating_system_version => visit_tmp[:visitor][:browser][:operating_system_version],
                   :keywords => visit_tmp[:visit][:referrer][:keyword] || "none",
                   :advert => visit_tmp[:visit][:advert][:advertising] || "none",
                   :landing_url => !visit_tmp[:visit][:landing].nil? ? "#{visit_tmp[:visit][:landing][:scheme]}://#{visit_tmp[:visit][:landing][:fqdn]}#{visit_tmp[:visit][:landing][:path]}" : "none"
          }


          # Parameters: {"policy_id"=>2, "policy_type"=>"traffic", "id_visit"=>"e7509f90-bfd3-0133-e402-000854505ddf", "plan_time"=>"2016-02-29 12:53:00 +0100",
          #               "execution_mode => "auto","
          #              "landing_url"=>"http://meshumeursinformatiques.blogspot.fr/2014/07/construction-dun-environnement-de.html",

          #              "referrer"=>{"medium"=>"none"},
          #              "advert"=>{"advertising"=>"none"}, "visit"=>{"policy_id"=>2, "policy_type"=>"traffic", "id_visit"=>"e7509f90-bfd3-0133-e402-000854505ddf", "start_time"=>"2016-02-29 12:53:00 +0100", "landing_url"=>"http://meshumeursinformatiques.blogspot.fr/2014/07/construction-dun-environnement-de.html", "durations"=>[164, 196, 152, 85, 107, 142, 132, 142], "referrer"=>{"medium"=>"none"}, "advert"=>{"advertising"=>"none"}}}
          wait(60, true, 2) {
            RestClient.post "http://#{$statupweb_server_ip}:#{$statupweb_server_port}/visits/",
                            JSON.generate(visit),
                            :content_type => :json,
                            :accept => :json

          }
        rescue Exception => e
          @logger.an_event.error "push visit flow #{visit_flow.basename} to statupweb #{$statupweb_server_ip}/#{$statupweb_server_port} : #{e.message}"

        else
          @logger.an_event.debug "push visit flow #{visit_flow.basename} to statupweb #{$statupweb_server_ip}/#{$statupweb_server_port}"

        ensure
          visit_flow.close
        end
      end

# si pas de bloc passé => wait pour une duree passé en paramètre
# si un bloc est passé => evalue le bloc tant que le bloc return false, leve une exception, ou que le timeout n'est pas atteind
# qd le timeout est atteint, si exception == true alors propage l'exception hors du wait

      def wait(timeout, exception = false, interval=0.2)

        if !block_given?
          sleep(timeout)
          return
        end

        timeout = interval if $staging == "development" # on execute une fois

        while (timeout > 0)
          sleep(interval)
          timeout -= interval
          begin
            return if yield
          rescue Exception => e
            p "try again : #{e.message}"
          else
            p "try again."
          end
        end

        raise e if !e.nil? and exception == true

      end
    end
  end
end