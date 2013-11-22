include Mongo

class MainController < ApplicationController

  def index

    @solve_result = execute_soap_request(:solve, { 
      task: { 
        jobCount: 20, 
        machineCount: 5,
        opDurationsForJobs: {
          item: [ 
            { item: (1..5).to_a }
          ] * 20                            
            #{ item: [1, 2, 3] }, 
            #{ item: [4, 5, 6] }          
        }
      }
    }, :solve_response)

  end

  def do_sleep
    sleep 10
  end

  def ajax_init_task
    #@task_id = execute_soap_request(:initTask, {}, :init_task_response)
    
    @task_id = execute_soap_request(:postTask, {      
      jobCount: 20, 
      machineCount: 5,
      opDurationsForJobs: {
	item: [ 
	  { item: (1..5).to_a }
	] * 20                            	
      }    
    }, :post_task_response)
  end

  def ajax_get_all_progresses
    @all_progresses = execute_soap_request(:getAllProgresses, { 
      taskIds: { item: params[:taskIds] } 
    }, :get_all_progresses_response)
  end

  def ajax_get_result
    @result = execute_soap_request(:getResult, { 
      taskId: params[:taskId] 
    }, :get_result_response)
  end

  def ajax_load_animation
    result_and_input = execute_soap_request(:getResultAndInput, { 
      taskId: params[:taskId] 
    }, :get_result_and_input_response)   
    puts result_and_input    
    
    @result = result_and_input[:result]   
    @input = result_and_input[:task]
    
    puts "#{@input[:op_durations_for_jobs].map { |x| x[:item] }}"
  end

  def new_test_case
    url = params[:url]
    name = params[:name]
    
    @ids = []

    require 'open-uri'
    f = open(url)
    
    while !f.eof?
      f.readline
      job_cnt, machine_cnt, _, upper_bound, lower_bound = f.readline.split.map { |x| x.to_i }
      f.readline
      durations = Array.new(machine_cnt) { |y| f.readline.split.map { |x| x.to_i } }.transpose
      durations_hashified = durations.map { |x| { item: x } }
      #puts "#{durations}"
      
      @ids.push execute_soap_request(:postTask, {      
	jobCount: job_cnt, 
	machineCount: machine_cnt,
	opDurationsForJobs: durations_hashified
      }, :post_task_response)
            
    end
    
    
        
  end

  private

    def execute_soap_request(method, args, retval)
      ep = "http://0.0.0.0:8080"
      #ep = "http://posh-wolf-ws.herokuapp.com" 
      
      respond_to do |format|
        format.js do 
          client = Savon.client do       
            endpoint ep
            namespace "com.poshwolf.ws"
            strip_namespaces true
          end
          puts args
          client.call(method, message: args).body[retval][:return]
        end
	
        format.html do 
          client = Savon.client do            
            endpoint ep
            namespace "com.poshwolf.ws"
            strip_namespaces true
          end
          puts args
          client.call(method, message: args).body[retval][:return]
        end
      end
    end
end

