class TableObjectUpdateChannel < ApplicationCable::Channel
   def subscribed
      stream_from "table_object_update:#{current_user.id},#{current_app.id}"
   end
end