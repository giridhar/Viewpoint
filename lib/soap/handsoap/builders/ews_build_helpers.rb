#############################################################################
# Copyright © 2010 Dan Wanek <dan.wanek@gmail.com>
#
#
# This file is part of Viewpoint.
# 
# Viewpoint is free software: you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation, either version 3 of the License, or (at
# your option) any later version.
# 
# Viewpoint is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
# 
# You should have received a copy of the GNU General Public License along
# with Viewpoint.  If not, see <http://www.gnu.org/licenses/>.
#############################################################################
# This is a module that is included in the main Builder that has sub builders
# that are used from multiple root nodes.  It is basically just a way to do
# code reuse in a more natural way.  The one difference between these functions
# and the builder functions in the EwsBuilder class is that the first parameter
# is of node type.  We use that parameter to build subnodes in this module.

module Viewpoint
  module EWS
    module SOAP
      module EwsBuildHelpers

        def folder_ids!(node, folder_ids, element_name="#{NS_EWS_MESSAGES}:FolderIds")
          node.add(element_name) do |p|
            folder_ids.each do |id|
              folder_id!(p,id)
            end
          end
        end

        def folder_id!(node, folder_id)
          if( folder_id.is_a?(Symbol) )
            # @todo add change_key support to DistinguishedFolderId
            node.add("#{NS_EWS_TYPES}:DistinguishedFolderId") do |df|
              df.set_attr('Id', folder_id.to_s)
            end
          else
            # @todo add change_key support to FolderId
            node.add("#{NS_EWS_TYPES}:FolderId") do |fi|
              fi.set_attr('Id', folder_id)
            end
          end
        end


        # For now this is the same as folder_ids! so just use that method
        def parent_folder_ids!(node, folder_ids)
          folder_ids!(node, folder_ids, "#{NS_EWS_MESSAGES}:ParentFolderIds")
        end


        def item_ids!(node, item_ids)
          node.add("#{NS_EWS_MESSAGES}:ItemIds") do |ids|
            item_ids.each do |id|
              ids.add("#{NS_EWS_TYPES}:ItemId") do |iid|
                iid.set_attr('Id',id)
              end
            end
          end
        end


        def saved_item_folder_id!(node, folder_id)
          node.add("#{NS_EWS_MESSAGES}:SavedItemFolderId") do |sfid|
            if( folder_id.is_a?(Symbol) )
              # @todo add change_key support to DistinguishedFolderId
              sfid.add("#{NS_EWS_TYPES}:DistinguishedFolderId") do |df|
                df.set_attr('Id', folder_id.to_s)
              end
            else
              # @todo add change_key support to FolderId
              sfid.add("#{NS_EWS_TYPES}:FolderId",folder_id)
            end
          end
        end


        # @todo This only supports the FieldURI extended property right now
        def folder_shape!(node, folder_shape)
          node.add("#{NS_EWS_MESSAGES}:FolderShape") do |fshape|
            fshape.add("#{NS_EWS_TYPES}:BaseShape", folder_shape[:base_shape])

            unless( folder_shape[:additional_props].nil? )
              unless( folder_shape[:additional_props][:FieldURI].nil? )
                fshape.add("#{NS_EWS_TYPES}:AdditionalProperties") do |addprops|
                  folder_shape[:additional_props][:FieldURI].each do |uri|
                    addprops.add("#{NS_EWS_TYPES}:FieldURI") { |furi| furi.set_attr('FieldURI', uri) }
                  end
                end
              end
            end
          end
        end

        # @todo Finish AdditionalProperties implementation
        def item_shape!(node, item_shape)
          node.add("#{NS_EWS_MESSAGES}:ItemShape") do |is|
            is.add("#{NS_EWS_TYPES}:BaseShape", item_shape[:base_shape])
          end
          
          unless( item_shape[:additional_props].nil? )
          end
        end

        def items!(node, items, type)
          node.add("#{NS_EWS_MESSAGES}:Items") do |i|
            if items.is_a? Hash
              method("#{type}_item!").call(i, items)
            else
              items.each do |item|
                method("#{type}_item!").call(i, item)
              end
            end
          end
        end

        def message_item!(node, item)
          node.add("#{NS_EWS_TYPES}:Message") do |msg|
            add_hierarchy!(msg, item)
          end
        end

        # Creates a CalendarItem Element structure.  It matters to Exchange which order Items are added in
        # so it loops through an order Array to make sure things are added appropriately.
        # @param [Element] node The <Items> element that is the parent to all of the elements that will
        #   be created from the items param
        # @param [Hash] item The item or items that will be added to the element in the parameter node
        # @todo Make sure and watch this method for new Item elements when EWS versions change.
        def calendar_item!(node, item)
          # For some reason MS thought it was a good idea to make order matter for Item creation.  This list is the current order
          # for Exchange 2003 and 2010
          order=[:mime_content,:item_id,:parent_folder_id,:item_class,:subject,:sensitivity,:body,:attachments,:date_time_received,:size,
            :categories,:in_reply_to,:is_submitted,:is_draft,:is_from_me,:is_resend,:is_unmodified,:internet_message_headers,
            :date_time_sent,:date_time_created,:response_objects,:reminder_due_by,:reminder_is_set,:reminder_minutes_before_start,
            :display_cc,:display_to,:has_attachments,:extended_property,:culture,:start,:end,:original_start,:is_all_day_event,
            :legacy_free_busy_status,:location,:when,:is_meeting,:is_cancelled,:is_recurring,:meeting_request_was_sent,
            :is_response_requested,:calendar_item_type,:my_response_type,:organizer,:required_attendees,:optional_attendees,
            :resources,:conflicting_meeting_count,:adjacent_meeting_count,:conflicting_meetings,:adjacent_meetings,:duration,:time_zone,
            :appointment_reply_time,:appointment_sequence_number,:appointment_state,:recurrence,:first_occurrence,:last_occurrence,
            :modified_occurrences,:deleted_occurrences,:meeting_time_zone,:start_time_zone,:end_time_zone,:conference_type,
            :allow_new_time_proposal,:is_online_meeting,:meeting_workspace_url,:net_show_url,:effective_rights,:last_modified_name,
            :last_modified_time,:is_associated,:web_client_read_form_query_string,:web_client_edit_form_query_string,:conversation_id,:unique_body]

          node.add("#{NS_EWS_TYPES}:CalendarItem") do |msg|
            order.each do |id|
              if(item[id])
                if(item[id].is_a?(Hash))
                  msg.add("#{NS_EWS_TYPES}:#{id.to_s.camel_case}", item[id][:text]) do |it|
                    add_hierarchy!(it, item[id]) if item[id]
                  end
                elsif(item[id].is_a?(Array))
                  msg.add("#{NS_EWS_TYPES}:#{id.to_s.camel_case}") do |it|
                    item[id].each do |ai|
                      add_hierarchy!(it, ai)
                    end
                  end
                end
              end
            end
          end
        end

        def event_types!(node, event_types)
          node.add("#{NS_EWS_TYPES}:EventTypes") do |ets|
            event_types.each do |event_type|
              ets.add("#{NS_EWS_TYPES}:EventType", event_type)
            end
          end
        end

        def subscription_id!(node, subscription_id)
          node.add("#{NS_EWS_MESSAGES}:SubscriptionId", subscription_id)
        end

        def watermark!(node, watermark)
          node.add("#{NS_EWS_MESSAGES}:Watermark", watermark)
        end

        def sync_state!(node, sync_state)
          node.add("#{NS_EWS_MESSAGES}:SyncState", sync_state)
        end

        # Add a hierarchy of elements from hash data
        # @example Hash to XML
        #   {:this => {:text =>'that'},'top' => {:id => '32fss', :text => 'TestText', {'middle' => 'bottom'}}}
        #   becomes...
        #   <this>that</this>
        #   <top Id='32fss'>
        #     TestText
        #     <middle>bottom</middle>
        #   </top>
        def add_hierarchy!(node, e_hash, prefix = NS_EWS_TYPES)
          e_hash.each_pair do |k,v|
            if v.is_a? Hash
              node.add("#{prefix}:#{k.to_s.camel_case}", v[:text]) do |n|
                add_hierarchy!(n, v)
              end
            elsif v.is_a? Array
              v.each do |i|
                add_hierarchy!(n, i)
              end
            else
              node.set_attr(k.to_s.camel_case, v) unless k == :text
            end
          end
        end

      end # EwsBuildHelpers
    end # SOAP
  end # EWS
end # Viewpoint