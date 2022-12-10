# frozen_string_literal: true

class TaskAssignment
  TASK_DESCRIPTION_BLOCK_ID = 'task_description_block'
  TASK_DESCRIPTION_ACTION_ID = 'task_description_action'
  PATH_TO_TASK_DESCRIPTION = %W[view state values #{TASK_DESCRIPTION_BLOCK_ID} #{TASK_DESCRIPTION_ACTION_ID} value].freeze
  ASSIGNEE_BLOCK_ID = 'assignee_block'
  ASSIGNEE_ACTION_ID = 'assignee_action'
  PATH_TO_ASSIGNEE = %W[view state values #{ASSIGNEE_BLOCK_ID} #{ASSIGNEE_ACTION_ID} selected_user].freeze
  COMPLETE_TASK_ACTION_ID = 'complete_task_action'

  def initialize(slack_client, logger: nil, &erb_method)
    @slack_client = slack_client
    @logger = logger
    @erb_method = erb_method
  end

  def handle_request(payload)
    case payload['type']
    when 'shortcut'
      show_assign_task_modal(payload)
    when 'view_submission'
      send_task_assigned_message(payload)
    when 'block_actions'
      send_task_completed_messages(payload)
    end
  end

  private

  attr_accessor :slack_client, :logger

  def erb(*args)
    @erb_method.call(*args)
  end

  def show_assign_task_modal(payload)
    trigger_id = payload['trigger_id']
    modal = erb(:'modal_task_request.json')
    slack_client.views_open(trigger_id: trigger_id, view: modal)
  end

  def task_assigned_fallback_text(user_id)
    "<@#{user_id}> has assigned you a task"
  end

  def send_task_assigned_message(payload)
    assigner_user_id = payload.dig('user', 'id')
    task_description = payload.dig(*PATH_TO_TASK_DESCRIPTION)
    assignee_user_id = payload.dig(*PATH_TO_ASSIGNEE)
    message = erb(:'chat_task_assigned.json', locals: {task_description: task_description, assigner_user_id: assigner_user_id})
    slack_client.chat_postMessage(channel: assignee_user_id, blocks: message, text: task_assigned_fallback_text(assigner_user_id))
  end

  def task_assigned_updated_fallback_text(user_id)
    "You've completed a task assigned by <@#{user_id}>"
  end

  def task_completed_fallback_text(user_id)
    "<@#{user_id}> completed a task you assigned"
  end

  def get_task_description_from_blocks(payload)
    payload.dig('message', 'blocks')
      &.detect { |block| block['block_id'] == TASK_DESCRIPTION_BLOCK_ID }
      &.dig('text', 'text')
  end


  def send_task_completed_messages(payload)
    assignee_user_id = payload.dig('user', 'id')
    actions = payload['actions']
    completion = actions.detect { |action| action['action_id'] == COMPLETE_TASK_ACTION_ID }
    return unless completion
    assigner_user_id = completion['value']
    task_description = get_task_description_from_blocks(payload)
    message_ts = payload.dig('message', 'ts')
    assignee_completion_message = erb(:'chat_task_assigned_updated.json', locals: {assigner_user_id: assigner_user_id, task_description: task_description})
    slack_client.chat_update(channel: payload.dig('channel', 'id'), ts: message_ts, blocks: assignee_completion_message, text: task_assigned_fallback_text(assigner_user_id))

    assigner_completion_message = erb(:'chat_task_completed.json', locals: {assignee_user_id: assignee_user_id, task_description: task_description})
    slack_client.chat_postMessage(channel: assigner_user_id, blocks: assigner_completion_message, text: task_completed_fallback_text(assignee_user_id))
  end

end
