class TableObjectUpdateChannel < ApplicationCable::Channel
   def subscribed
      stream_from "table_object_update"
   end
end