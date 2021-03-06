
class AjaxController < ApplicationController

  include ApplicationHelper

  def post_task_from_sample
    
    job_cnt = params[:jobCnt].to_i
    machine_cnt = params[:machineCnt].to_i
    
    f = get_sample_file(job_cnt, machine_cnt)
    
    offset = params[:offset].to_i
    skip_test_cases(f, offset - 1, machine_cnt)
    
    parse_and_post_file(f)
                    
    render 'post_task'
  end
  
  def post_task_from_pasted
    
    require 'stringio'    
    
    data = params[:raw]
    f = StringIO.new(data)    
    parse_and_post_file(f)
        
    render 'post_task'
  end
  
  def post_task_from_url
    
    url = params[:srcUrl]    
    f = get_url_as_file(url)
    parse_and_post_file(f)
               
    render 'post_task'        
  end
  
  
  def get_all_progresses
    @all_progresses = execute_soap_request(:getAllProgresses, { 
      taskIds: { item: params[:taskIds] } 
    }, :get_all_progresses_response)
  end

  def get_result
    @result = execute_soap_request(:getResult, { 
      taskId: params[:taskId] 
    }, :get_result_response)        
  end

  
  def load_animation
    result_and_input = execute_soap_request(:getResultAndInput, { 
      taskId: params[:taskId] 
    }, :get_result_and_input_response)   
    
    @result = result_and_input[:result]   
    @input = result_and_input[:task]
    
  end


  private

    def build_verbose_config
      c = params[:config]
      @verbose_config =
        "#{c[:maxIterations]} iterations, "\
        "#{c[:nestNumber]} total nests, "\
        "#{c[:nestsToAbandonNumber]} nests to abandon, "\
        "discovery probability = #{c[:discoveryProbability]}"     
    end
    
    def parse_and_post_file(f)
     
      build_verbose_config

      f.readline
      @job_cnt, @machine_cnt, _, @upper_bound, @lower_bound = f.readline.split.map { |x| x.to_i }
      f.readline
      
      durations = Array.new(@machine_cnt) { |y| f.readline.split.map { |x| x.to_i } }.transpose
      durations_hashified = { item: durations.map { |x| { item: x } } }
      
      @task_id = execute_soap_request(:postTask, {      
        jobCount: @job_cnt, 
        machineCount: @machine_cnt,
        opDurationsForJobs: durations_hashified,
        config: params[:config]
      }, :post_task_response)
      
    end
    
    def execute_soap_request(method, args, retval)
      if Rails.env.production?
        ep = "http://posh-wolf-ws.herokuapp.com" 
      else
        ep = "http://0.0.0.0:8080"
      end
      
      respond_to do |format|
        format.js do 
          client = Savon.client do       
            endpoint ep
            namespace "com.poshwolf.ws"
            strip_namespaces true
          end
          client.call(method, message: args).body[retval][:return]
        end
	
      end
    end

end
