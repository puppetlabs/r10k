require 'r10k/task'
require 'r10k/logging'

module R10K
class TaskRunner

  include R10K::Logging

  attr_writer :succeeded

  def initialize(opts)
    @tasks     = []
    @succeeded = true
    @errors    = {}

    @trace = opts.delete(:trace)

    raise "Unrecognized options: #{opts.keys.join(', ')}" unless opts.empty?
  end

  def run
    catch :abort do
      until @tasks.empty?
        current = @tasks.first
        current.task_runner = self
        begin
          current.call
        rescue Interrupt => e
          logger.error "Aborted!"
          $stderr.puts e.backtrace.join("\n").red if @trace
          @succeeded = false
          throw :abort
        rescue => e
          logger.error "Task #{current} failed while running: #{e.message}"
          $stderr.puts e.backtrace.join("\n").red if @trace

          @errors[current] = e
          @succeeded = false
        end
        @tasks.shift
      end
    end
  end

  def prepend_task(task)
    @tasks.unshift task
  end

  def append_task(task)
    @tasks << task
  end

  # @param [R10K::Task] task_index The task to insert the task after
  # @param [R10K::Task] new_task The task to insert
  def insert_task_after(task_index, new_task)
    if (index = @tasks.index(task_index))
      index += 1
      @tasks.insert(index, new_task)
    else
      @tasks.insert(0, new_task)
    end
  end

  def succeeded?
    @succeeded
  end

  def exit_value
    @succeeded ? 0 : 1
  end
end
end
