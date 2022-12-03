# frozen_string_literal: true
class Tasks

    TASK_DESCRIPTION_BLOCK_ID = 'task_description'
    TASK_DESCRIPTION_ACTION_ID = 'task_action'
    ASSIGNED_USER_BLOCK_ID = 'user_block'
    ASSIGNED_USER_ACTION_ID = 'user_action'
    PATH_TO_TASK_DESCRIPTION = %W(view state values #{TASK_DESCRIPTION_BLOCK_ID} #{TASK_DESCRIPTION_ACTION_ID} value)
    PATH_TO_ASSIGNED_USER = %W(view state values #{ASSIGNED_USER_BLOCK_ID} #{ASSIGNED_USER_ACTION_ID} value)

    def initialize(slack_client)
        @slack_client = slack_client
    end

    def handle_request(payload)
        case payload[:type]
        when 'interaction'
            task_requested(payload)
        when 'view_submission'
            task_assigned(payload)
        when 'block_actions'
            task_completed(payload)
        end
    end

    private

    attr_accessor :slack_client

    def task_requested(payload)
        trigger_id = payload['trigger_id']
        modal = erb :task_request
        slack_client.views_open(trigger_id: trigger_id, view: modal)
        200
    end

    def task_assigned(payload)
        user_id = payload.dig('user', 'id')
        task_description = payload.dig(*PATH_TO_TASK_DESCRIPTION)
        assigned_user_id = payload.dig(*PATH_TO_ASSIGNED_USER)
        #if self, do different
    end

    def task_completed(payload)
    end

    def handle_error
        #ephimeral response?
    end
end
