# name: discourse-jerome
# about: Secondary Groups
# version: 0.0.1
# authors: Test
after_initialize do
UsersController.class_eval do
 def is_local_username
    plugin_source_user_J =   @guardian.user
    plugin_source_groups_J = GroupUser.select("*").where(user_id: plugin_source_user_J.id).where("groups.automatic = 'f'").joins(:group)
    plugin_source_groups_array_J = Array.new
    plugin_source_groups_J.each do |object|
        plugin_source_groups_array_J << object.name
    end
    if(plugin_source_user_J.custom_fields["secondary_group"].nil?)
      plugin_secondary_group_J =  Array.new
    else
       plugin_secondary_group_J =  JSON.parse(plugin_source_user_J.custom_fields["secondary_group"])
    end
    plugin_having_query_array_J = Array.new
    plugin_secondary_group_J.each do |plugin_temp_secondary_group_J|
      plugin_having_query_array_J <<  " '"+plugin_temp_secondary_group_J+"' = (groups.name) "
    end
    plugin_source_groups_J.each do |plugin_temp_group_J|
      plugin_having_query_array_J <<  " '"+plugin_temp_group_J.name+"' = (groups.name) "
    end
    plugin_having_query_J =plugin_having_query_array_J.join("OR")
    if(plugin_having_query_J == "")
      plugin_having_query_J = '1=2'
    end    
    usernames = params[:usernames]
    usernames = [params[:username]] if usernames.blank?
    if(plugin_source_user_J.admin?)
       groups = Group.where(name: usernames).pluck(:name)
    else
       groups = Group.where(name: usernames).where(plugin_having_query_J).pluck(:name)
    end   
    if(plugin_source_user_J.admin?)
      mentionable_groups =
        if current_user
          Group.mentionable(current_user)
            .where(name: usernames)           
            .pluck(:name, :user_count)
            .map do |name, user_count|
            {
              name: name,
              user_count: user_count
            }
          end
        end
    else
      mentionable_groups =
        if current_user
          Group.mentionable(current_user)
            .where(name: usernames)
            .where(plugin_having_query_J)
            .pluck(:name, :user_count)
            .map do |name, user_count|
            {
              name: name,
              user_count: user_count
            }
          end
        end   
    end
    usernames -= groups
    usernames.each(&:downcase!)       
    cannot_see = []
    topic_id = params[:topic_id]
    unless topic_id.blank?
      topic = Topic.find_by(id: topic_id)
      usernames.each { |username| cannot_see.push(username) unless Guardian.new(User.find_by_username(username)).can_see?(topic) }
    end
    plugin_user_J = @guardian.user
    plugin_user_groups_J = GroupUser.select("*").where(user_id: plugin_user_J.id).where("groups.automatic = 'f'").joins(:group)
    if(plugin_user_J.custom_fields["secondary_group"].nil?)
      plugin_secondary_group_J =  Array.new
    else
       plugin_secondary_group_J =  JSON.parse(plugin_user_J.custom_fields["secondary_group"])
    end
    plugin_where_query_array_J=Array.new;
    plugin_having_query_array_J = Array.new
    plugin_secondary_group_J.each do |plugin_temp_secondary_group_J|
      plugin_having_query_array_J <<  " '"+plugin_temp_secondary_group_J+"' = ANY (array_agg(groups.name)) "
    end
    plugin_user_groups_J.each do |plugin_temp_group_J|
      plugin_having_query_array_J <<  " '"+plugin_temp_group_J.name+"' = ANY (array_agg(groups.name)) "
    end
    unless plugin_user_J['primary_group_id'].nil?
       plugin_having_query_array_J << ' "users"."primary_group_id" = '+plugin_user_J['primary_group_id'].to_s
    end
    plugin_where_query_J =plugin_where_query_array_J.join("OR")
    plugin_having_query_J =plugin_having_query_array_J.join("OR")
    if(plugin_having_query_J == "")
      plugin_having_query_J = '1=2'
    end          
    plugin_user_J = @guardian.user
    plugin_user_groups_J = GroupUser.select("*").where(user_id: plugin_user_J.id).where("groups.automatic = 'f'").joins(:group)
    if(plugin_user_J.custom_fields["secondary_group"].nil?)
      plugin_secondary_group_J =  Array.new
    else
       plugin_secondary_group_J =  JSON.parse(plugin_user_J.custom_fields["secondary_group"])
    end
    plugin_where_query_array_J=Array.new;
    plugin_having_query_array_J = Array.new
    plugin_secondary_group_J.each do |plugin_temp_secondary_group_J|
      plugin_having_query_array_J <<  " '"+plugin_temp_secondary_group_J+"' = ANY (array_agg(groups.name)) "
    end
    plugin_user_groups_J.each do |plugin_temp_group_J|
      plugin_having_query_array_J <<  " '"+plugin_temp_group_J.name+"' = ANY (array_agg(groups.name)) "
    end
    unless plugin_user_J['primary_group_id'].nil?
       plugin_having_query_array_J << ' "users"."primary_group_id" = '+plugin_user_J['primary_group_id'].to_s
    end
    plugin_where_query_J =plugin_where_query_array_J.join("OR")
    plugin_having_query_J =plugin_having_query_array_J.join("OR")
    if(plugin_having_query_J == "")
      plugin_having_query_J = '1=2'
    end          
    if(plugin_user_J.admin?)    
      result = User.where(staged: false)
        .where(username_lower: usernames)
        .pluck(:username_lower)
    else
       result = User
        .joins(' FULL JOIN user_custom_fields ON "user_custom_fields"."user_id"="users"."id"')
        .joins(' INNER JOIN group_users ON "group_users"."user_id"="users"."id"')
        .joins(' INNER JOIN groups ON "group_users"."group_id"="groups"."id"')
        .group('"users"."id"')
        .having(plugin_having_query_J)
        .where(staged: false)       
        .where(username_lower: usernames)
        .pluck(:username_lower)
    end
    render json: {
      valid: result,
      valid_groups: groups,
      mentionable_groups: mentionable_groups,
      cannot_see: cannot_see,
      max_users_notified_per_group_mention: SiteSetting.max_users_notified_per_group_mention
    }
  end
  def invited
    plugin_target_user_J = fetch_user_from_params(include_inactive: current_user.try(:staff?) || (current_user && SiteSetting.show_inactive_accounts))
    plugin_source_user_J = @guardian.user
    plugin_can_send_PM_J = false
    plugin_target_groups_J = GroupUser.select("*").where(user_id: plugin_target_user_J.id).where("groups.automatic = 'f'").joins(:group)
    plugin_target_groups_array_J = Array.new
    plugin_target_groups_J.each do |object|
        plugin_target_groups_array_J << object.name
     end
    if(plugin_source_user_J.custom_fields["secondary_group"].nil?)
      plugin_source_secondary_group_J =  Array.new
    else
       plugin_source_secondary_group_J =  JSON.parse(plugin_source_user_J.custom_fields["secondary_group"])
    end              
    if(!((plugin_source_secondary_group_J & plugin_target_groups_array_J).empty? ))
         plugin_can_send_PM_J = true
    else
       unless plugin_source_user_J['primary_group_id'].nil?
            if(plugin_target_user_J['primary_group_id'] == plugin_source_user_J['primary_group_id'])
                plugin_can_send_PM_J = true
            else
                plugin_can_send_PM_J = false
            end
         end   
    end
    plugin_source_groups_J = GroupUser.select("*").where(user_id: plugin_source_user_J.id).where("groups.automatic = 'f'").joins(:group)
    plugin_source_groups_array_J = Array.new
    plugin_source_groups_J.each do |object|
        plugin_source_groups_array_J << object.name
    end    
    if(plugin_source_user_J == plugin_target_user_J)
      plugin_can_send_PM_J = true
    end
    if(plugin_source_user_J.admin?)
      plugin_can_send_PM_J = true
    end
    if(plugin_can_send_PM_J == false)
       raise Discourse::InvalidAccess
    else
      inviter = fetch_user_from_params(include_inactive: current_user.try(:staff?) || (current_user && SiteSetting.show_inactive_accounts))
      offset = params[:offset].to_i || 0
      filter_by = params[:filter]
      invites = if guardian.can_see_invite_details?(inviter) && filter_by == "pending"
        Invite.find_pending_invites_from(inviter, offset)
      else
        Invite.find_redeemed_invites_from(inviter, offset)
      end
      invites = invites.filter_by(params[:search])
      render_json_dump invites: serialize_data(invites.to_a, InviteSerializer),
                       can_see_invite_details: guardian.can_see_invite_details?(inviter)
    end     
  end
  def invited_count
    plugin_target_user_J = fetch_user_from_params(include_inactive: current_user.try(:staff?) || (current_user && SiteSetting.show_inactive_accounts))
    plugin_source_user_J = @guardian.user
    plugin_can_send_PM_J = false
    plugin_target_groups_J = GroupUser.select("*").where(user_id: plugin_target_user_J.id).where("groups.automatic = 'f'").joins(:group)
    plugin_target_groups_array_J = Array.new
    plugin_target_groups_J.each do |object|
        plugin_target_groups_array_J << object.name
     end
    if(plugin_source_user_J.custom_fields["secondary_group"].nil?)
      plugin_source_secondary_group_J =  Array.new
    else
       plugin_source_secondary_group_J =  JSON.parse(plugin_source_user_J.custom_fields["secondary_group"])
    end              
    if(!((plugin_source_secondary_group_J & plugin_target_groups_array_J).empty? ))
         plugin_can_send_PM_J = true
    else
       unless plugin_source_user_J['primary_group_id'].nil?
            if(plugin_target_user_J['primary_group_id'] == plugin_source_user_J['primary_group_id'])
                plugin_can_send_PM_J = true
            else
                plugin_can_send_PM_J = false
            end
         end   
    end
    plugin_source_groups_J = GroupUser.select("*").where(user_id: plugin_source_user_J.id).where("groups.automatic = 'f'").joins(:group)
    plugin_source_groups_array_J = Array.new
    plugin_source_groups_J.each do |object|
        plugin_source_groups_array_J << object.name
    end    
    if(plugin_source_user_J == plugin_target_user_J)
      plugin_can_send_PM_J = true
    end
    if(plugin_source_user_J.admin?)
      plugin_can_send_PM_J = true
    end
    if(plugin_can_send_PM_J == false)
       raise Discourse::InvalidAccess
    else
      inviter = fetch_user_from_params(include_inactive: current_user.try(:staff?) || (current_user && SiteSetting.show_inactive_accounts))
      pending_count = Invite.find_pending_invites_count(inviter)
      redeemed_count = Invite.find_redeemed_invites_count(inviter)
      render json: { counts: { pending: pending_count, redeemed: redeemed_count,
                               total: (pending_count.to_i + redeemed_count.to_i) } }
    end      
  end    
  def search_users
      term = params[:term].to_s.strip
      topic_id = params[:topic_id]
      topic_id = topic_id.to_i if topic_id
      topic_allowed_users = params[:topic_allowed_users] || false
      if params[:group].present?
        @group = Group.find_by(name: params[:group])
      end
      results = UserSearch.new(term,
                               topic_id: topic_id,
                               topic_allowed_users: topic_allowed_users,
                               searching_user: current_user,
                               group: @group
                              ).search
      user_fields = [:username, :upload_avatar_template]
      user_fields << :name if SiteSetting.enable_names?
      to_render = { users: results.as_json(only: user_fields, methods: [:avatar_template]) }
      groups =
        if current_user
          if params[:include_mentionable_groups] == 'true'
            Group.mentionable(current_user)
          elsif params[:include_messageable_groups] == 'true'
            Group.messageable(current_user)
          end
        end
      include_groups = params[:include_groups] == "true"
      if include_groups || groups
        plugin_source_user_J =   @guardian.user
        plugin_source_groups_J = GroupUser.select("*").where(user_id: plugin_source_user_J.id).where("groups.automatic = 'f'").joins(:group)
        plugin_source_groups_array_J = Array.new
        plugin_source_groups_J.each do |object|
            plugin_source_groups_array_J << object.name
        end
        if(plugin_source_user_J.custom_fields["secondary_group"].nil?)
          plugin_secondary_group_J =  Array.new
        else
           plugin_secondary_group_J =  JSON.parse(plugin_source_user_J.custom_fields["secondary_group"])
        end
        plugin_having_query_array_J = Array.new
        plugin_secondary_group_J.each do |plugin_temp_secondary_group_J|
          plugin_having_query_array_J <<  " '"+plugin_temp_secondary_group_J+"' = (groups.name) "
        end
        plugin_source_groups_J.each do |plugin_temp_group_J|
          plugin_having_query_array_J <<  " '"+plugin_temp_group_J.name+"' = (groups.name) "
        end
        plugin_having_query_J =plugin_having_query_array_J.join("OR")
        if(plugin_having_query_J == "")
          plugin_having_query_J = '1=2'
        end    
        groups = Group.search_groups(term, groups: groups)
        groups = groups.where(visibility_level: Group.visibility_levels[:public]) if include_groups
        if(!(plugin_source_user_J.admin?))
          groups = groups.where(plugin_having_query_J)
        end
        groups = groups.order('groups.name asc')
        to_render[:groups] = groups.map do |m|
          { name: m.name, full_name: m.full_name }
        end
      end
      render json: to_render
    end      
    def summary
      plugin_target_user_J = fetch_user_from_params(include_inactive: current_user.try(:staff?) || (current_user && SiteSetting.show_inactive_accounts))
      plugin_source_user_J = @guardian.user
      plugin_can_send_PM_J = false
      plugin_target_groups_J = GroupUser.select("*").where(user_id: plugin_target_user_J.id).where("groups.automatic = 'f'").joins(:group)
      plugin_target_groups_array_J = Array.new
      plugin_target_groups_J.each do |object|
          plugin_target_groups_array_J << object.name
       end
      if(plugin_source_user_J.custom_fields["secondary_group"].nil?)
        plugin_source_secondary_group_J =  Array.new
      else
         plugin_source_secondary_group_J =  JSON.parse(plugin_source_user_J.custom_fields["secondary_group"])
      end              
      if(!((plugin_source_secondary_group_J & plugin_target_groups_array_J).empty? ))
           plugin_can_send_PM_J = true
      else
         unless plugin_source_user_J['primary_group_id'].nil?
              if(plugin_target_user_J['primary_group_id'] == plugin_source_user_J['primary_group_id'])
                  plugin_can_send_PM_J = true
              else
                  plugin_can_send_PM_J = false
              end
           end   
      end
      plugin_source_groups_J = GroupUser.select("*").where(user_id: plugin_source_user_J.id).where("groups.automatic = 'f'").joins(:group)
      plugin_source_groups_array_J = Array.new
      plugin_source_groups_J.each do |object|
          plugin_source_groups_array_J << object.name
      end      
      if(plugin_source_user_J == plugin_target_user_J)
        plugin_can_send_PM_J = true
      end
      if(plugin_source_user_J.admin?)
        plugin_can_send_PM_J = true
      end
      if(plugin_can_send_PM_J == false)
         raise Discourse::InvalidAccess
      else
         user = fetch_user_from_params(include_inactive: current_user.try(:staff?) || (current_user && SiteSetting.show_inactive_accounts))
         summary = UserSummary.new(user, guardian)
         serializer = UserSummarySerializer.new(summary, scope: guardian)
         render_json_dump(serializer)
      end     
    end 
    def show(for_card: false)
      return redirect_to path('/login') if SiteSetting.hide_user_profiles_from_public && !current_user           
      plugin_target_user_J = fetch_user_from_params(
      include_inactive: current_user.try(:staff?) || (current_user && SiteSetting.show_inactive_accounts)
      ) 
        
      plugin_source_user_J = @guardian.user
      plugin_can_send_PM_J = false
      plugin_target_groups_J = GroupUser.select("*").where(user_id: plugin_target_user_J.id).where("groups.automatic = 'f'").joins(:group)
      plugin_target_groups_array_J = Array.new
      plugin_target_groups_J.each do |object|
          plugin_target_groups_array_J << object.name
       end
      if(plugin_source_user_J.custom_fields["secondary_group"].nil?)
        plugin_source_secondary_group_J =  Array.new
      else
         plugin_source_secondary_group_J =  JSON.parse(plugin_source_user_J.custom_fields["secondary_group"])
      end              
      if(!((plugin_source_secondary_group_J & plugin_target_groups_array_J).empty? ))
           plugin_can_send_PM_J = true
      else
         unless plugin_source_user_J['primary_group_id'].nil?
              if(plugin_target_user_J['primary_group_id'] == plugin_source_user_J['primary_group_id'])
                  plugin_can_send_PM_J = true
              else
                  plugin_can_send_PM_J = false
              end
           end   
      end
      plugin_source_groups_J = GroupUser.select("*").where(user_id: plugin_source_user_J.id).where("groups.automatic = 'f'").joins(:group)
      plugin_source_groups_array_J = Array.new
      plugin_source_groups_J.each do |object|
          plugin_source_groups_array_J << object.name
      end     
      if(plugin_source_user_J == plugin_target_user_J)
        plugin_can_send_PM_J = true
      end
      if(plugin_source_user_J.admin?)
        plugin_can_send_PM_J = true
      end
      if(plugin_can_send_PM_J == false)
         raise Discourse::InvalidAccess
      else
          @user = fetch_user_from_params(
          include_inactive: current_user.try(:staff?) || (current_user && SiteSetting.show_inactive_accounts)
          )
          user_serializer = nil
          if guardian.can_see_profile?(@user)
            serializer_class = for_card ? UserCardSerializer : UserSerializer
            user_serializer = serializer_class.new(@user, scope: guardian, root: 'user')
            topic_id = params[:include_post_count_for].to_i
            if topic_id != 0
              user_serializer.topic_post_count = { topic_id => Post.secured(guardian).where(topic_id: topic_id, user_id: @user.id).count }
            end
          else
            user_serializer = HiddenProfileSerializer.new(@user, scope: guardian, root: 'user')
          end
          if !params[:skip_track_visit] && (@user != current_user)
            track_visit_to_user_profile
          end
          if params[:external_id] && params[:external_id].ends_with?('.json')
            return render_json_dump(user_serializer)
          end
          respond_to do |format|
            format.html do
              @restrict_fields = guardian.restrict_user_fields?(@user)
              store_preloaded("user_#{@user.username}", MultiJson.dump(user_serializer))
              render :show
            end
            format.json do
              render_json_dump(user_serializer)
            end
          end
      end
    end
   end
   UserActionsController.class_eval do
    def index
        plugin_target_user_J = fetch_user_from_params(include_inactive: current_user.try(:staff?) || (current_user && SiteSetting.show_inactive_accounts))
        plugin_source_user_J = @guardian.user
        plugin_can_send_PM_J = false
        plugin_target_groups_J = GroupUser.select("*").where(user_id: plugin_target_user_J.id).where("groups.automatic = 'f'").joins(:group)
        plugin_target_groups_array_J = Array.new
        plugin_target_groups_J.each do |object|
            plugin_target_groups_array_J << object.name
         end
        if(plugin_source_user_J.custom_fields["secondary_group"].nil?)
          plugin_source_secondary_group_J =  Array.new
        else
           plugin_source_secondary_group_J =  JSON.parse(plugin_source_user_J.custom_fields["secondary_group"])
        end              
        if(!((plugin_source_secondary_group_J & plugin_target_groups_array_J).empty? ))
             plugin_can_send_PM_J = true
        else
           unless plugin_source_user_J['primary_group_id'].nil?
                if(plugin_target_user_J['primary_group_id'] == plugin_source_user_J['primary_group_id'])
                    plugin_can_send_PM_J = true
                else
                    plugin_can_send_PM_J = false
                end
             end   
        end
        plugin_source_groups_J = GroupUser.select("*").where(user_id: plugin_source_user_J.id).where("groups.automatic = 'f'").joins(:group)
        plugin_source_groups_array_J = Array.new
        plugin_source_groups_J.each do |object|
            plugin_source_groups_array_J << object.name
        end        
        if(plugin_source_user_J == plugin_target_user_J)
          plugin_can_send_PM_J = true
        end
        if(plugin_source_user_J.admin?)
          plugin_can_send_PM_J = true
        end
         if(plugin_can_send_PM_J == false)
           raise Discourse::InvalidAccess
         else
            params.require(:username)
            params.permit(:filter, :offset, :acting_username)        
            per_chunk = 30        
            user = fetch_user_from_params(include_inactive: current_user.try(:staff?) || (current_user && SiteSetting.show_inactive_accounts))
            raise Discourse::NotFound unless guardian.can_see_profile?(user)        
            action_types = (params[:filter] || "").split(",").map(&:to_i)        
            opts = {
              user_id: user.id,
              user: user,
              offset: params[:offset].to_i,
              limit: per_chunk,
              action_types: action_types,
              guardian: guardian,
              ignore_private_messages: params[:filter] ? false : true,
              acting_username: params[:acting_username]
            }        
            stream = UserAction.stream(opts).to_a
            if stream.length == 0 && (help_key = params['no_results_help_key'])
              if user.id == guardian.user.try(:id)
                help_key += ".self"
              else
                help_key += ".others"
              end
              render json: {
                user_action: [],
                no_results_help: I18n.t(help_key)
              }
            else
              render_serialized(stream, UserActionSerializer, root: 'user_actions')
            end                    
         end       
    end           
   end
   UserSearch.class_eval do
       def search_ids
          plugin_user_J = @guardian.user
          plugin_user_groups_J = GroupUser.select("*").where(user_id: plugin_user_J.id).where("groups.automatic = 'f'").joins(:group)
          if(plugin_user_J.custom_fields["secondary_group"].nil?)
            plugin_secondary_group_J =  Array.new
          else
             plugin_secondary_group_J =  JSON.parse(plugin_user_J.custom_fields["secondary_group"])
          end
          plugin_where_query_array_J=Array.new;
          plugin_having_query_array_J = Array.new
          plugin_secondary_group_J.each do |plugin_temp_secondary_group_J|
            plugin_having_query_array_J <<  " '"+plugin_temp_secondary_group_J+"' = ANY (array_agg(groups.name)) "
          end          
          unless plugin_user_J['primary_group_id'].nil?
             plugin_having_query_array_J << ' "users"."primary_group_id" = '+plugin_user_J['primary_group_id'].to_s
          end
          plugin_where_query_J =plugin_where_query_array_J.join("OR")
          plugin_having_query_J =plugin_having_query_array_J.join("OR")
          if(plugin_having_query_J == "")
            plugin_having_query_J = '1=2'
          end          
          users = Set.new         
          if @term.present?
            if(plugin_user_J.admin?)
               scoped_users.where(username_lower: @term.downcase)
              .joins(' FULL JOIN user_custom_fields ON "user_custom_fields"."user_id"="users"."id"')
              .joins(' INNER JOIN group_users ON "group_users"."user_id"="users"."id"')
              .joins(' INNER JOIN groups ON "group_users"."group_id"="groups"."id"')
              .group('"users"."id"')
              .limit(@limit)
              .pluck(:id)
              .each { |id| users << id }
            else                               
               scoped_users.where(username_lower: @term.downcase)
              .joins(' FULL JOIN user_custom_fields ON "user_custom_fields"."user_id"="users"."id"')
              .joins(' INNER JOIN group_users ON "group_users"."user_id"="users"."id"')
              .joins(' INNER JOIN groups ON "group_users"."group_id"="groups"."id"')
              .group('"users"."id"')
              .having(plugin_having_query_J)
              .limit(@limit)
              .pluck(:id)
              .each { |id| users << id }
            end
          end
          return users.to_a if users.length >= @limit         
          if @topic_id
            if(plugin_user_J.admin?)
              filtered_by_term_users.where('users.id IN (SELECT p.user_id FROM posts p WHERE topic_id = ?)', @topic_id)
              .order('last_seen_at DESC')
              .joins(' FULL JOIN user_custom_fields ON "user_custom_fields"."user_id"="users"."id"')
              .joins(' INNER JOIN group_users ON "group_users"."user_id"="users"."id"')
              .joins(' INNER JOIN groups ON "group_users"."group_id"="groups"."id"')
              .group('"users"."id"')
              .limit(@limit - users.length)
              .pluck(:id)
              .each { |id| users << id }
            else                                                       
              filtered_by_term_users.where('users.id IN (SELECT p.user_id FROM posts p WHERE topic_id = ?)', @topic_id)
              .order('last_seen_at DESC')
              .joins(' FULL JOIN user_custom_fields ON "user_custom_fields"."user_id"="users"."id"')
              .joins(' INNER JOIN group_users ON "group_users"."user_id"="users"."id"')
              .joins(' INNER JOIN groups ON "group_users"."group_id"="groups"."id"')
              .group('"users"."id"')
              .having(plugin_having_query_J)
              .limit(@limit - users.length)
              .pluck(:id)
              .each { |id| users << id }
            end
          end
          return users.to_a if users.length >= @limit
          if(plugin_user_J.admin?)         
             filtered_by_term_users.order('last_seen_at DESC')
            .joins(' FULL JOIN user_custom_fields ON "user_custom_fields"."user_id"="users"."id"')
            .joins(' INNER JOIN group_users ON "group_users"."user_id"="users"."id"')
            .joins(' INNER JOIN groups ON "group_users"."group_id"="groups"."id"')
            .group('"users"."id"')
            .limit(@limit - users.length)
            .pluck(:id)
            .each { |id| users << id }
          else
             filtered_by_term_users.order('last_seen_at DESC')
            .joins(' FULL JOIN user_custom_fields ON "user_custom_fields"."user_id"="users"."id"')
            .joins(' INNER JOIN group_users ON "group_users"."user_id"="users"."id"')
            .joins(' INNER JOIN groups ON "group_users"."group_id"="groups"."id"')
            .group('"users"."id"')
            .having(plugin_having_query_J)
            .limit(@limit - users.length)
            .pluck(:id)
            .each { |id| users << id }
          end
          users.to_a
      end
     end
    PostAnalyzer.class_eval do
     def plugin_custom_raw_mentions_users_J
        raw_mentions = cooked_stripped.css('.mention').map do |e|
          if name = e.inner_text
            name = name[1..-1]
            name.downcase! if name
            name
          end
        end
        raw_mentions.compact!
        raw_mentions.uniq!
        raw_mentions
      end  
      def plugin_custom_raw_mentions_groups_J
        raw_mentions = cooked_stripped.css('.mention-group').map do |e|
          if name = e.inner_text
            name = name[1..-1]
            name.downcase! if name
            name
          end
        end
        raw_mentions.compact!
        raw_mentions.uniq!
        raw_mentions
      end                   
    end
    NewPostManager.class_eval do
      def perform_create_post
        result = NewPostResult.new(:create_post)
        plugin_can_send_PM_J = false
        if @args[:archetype] == Archetype.private_message
           plugin_target_users_array_J =  @args[:target_usernames].split(",")
           plugin_target_users_array_J.each do |plugin_target_user_str_J|
            plugin_target_user_J = User.find_by(username: plugin_target_user_str_J)            
            plugin_target_groups_J = GroupUser.select("*").where(user_id: plugin_target_user_J.id).where("groups.automatic = 'f'").joins(:group)
            plugin_target_groups_array_J = Array.new
            plugin_target_groups_J.each do |object|
                plugin_target_groups_array_J << object.name
             end
             if(self.user.custom_fields["secondary_group"].nil?)
                plugin_source_secondary_group_J =  Array.new
             else
                 plugin_source_secondary_group_J =  JSON.parse(self.user.custom_fields["secondary_group"])
             end 
             if(!((plugin_source_secondary_group_J & plugin_target_groups_array_J).empty? ))
                   plugin_can_send_PM_J = true
              else
                 unless self.user['primary_group_id'].nil?
                      if(plugin_target_user_J['primary_group_id'] == self.user['primary_group_id'])
                          plugin_can_send_PM_J = true
                      else
                          plugin_can_send_PM_J = false
                      end
                 end   
              end
              plugin_source_user_J = self.user
              plugin_source_groups_J = GroupUser.select("*").where(user_id: plugin_source_user_J.id).where("groups.automatic = 'f'").joins(:group)
              plugin_source_groups_array_J = Array.new
              plugin_source_groups_J.each do |object|
                  plugin_source_groups_array_J << object.name
              end              
              if(plugin_can_send_PM_J == false)
                break  
              end 
           end
           plugin_target_groups_array_J =  @args[:target_group_names].split(",")
           plugin_target_groups_array_J.each do |plugin_target_group_str_J|
              plugin_can_send_PM_J = false
              plugin_source_user_J =  self.user
              plugin_source_groups_J = GroupUser.select("*").where(user_id: plugin_source_user_J.id).where("groups.automatic = 'f'").joins(:group)
              plugin_source_groups_array_J = Array.new
              plugin_source_groups_J.each do |object|
                  plugin_source_groups_array_J << object.name
              end
              plugin_source_groups_array_J.each do |plugin_source_group_str_J| 
                if(plugin_target_group_str_J == plugin_source_group_str_J)
                  plugin_can_send_PM_J = true
                end
              end
              if(plugin_source_user_J.custom_fields["secondary_group"].nil?)
                plugin_secondary_group_J =  Array.new
              else
                 plugin_secondary_group_J =  JSON.parse(plugin_source_user_J.custom_fields["secondary_group"])
              end                
              plugin_secondary_group_J.each do |plugin_secondary_group_str_J| 
                if(plugin_target_group_str_J == plugin_secondary_group_str_J)
                  plugin_can_send_PM_J = true
                end
              end
              if(plugin_can_send_PM_J == false)
                break  
              end 
           end
          post_analyzers= PostAnalyzer.new(@args[:raw], nil)
          plugin_post_users_mentions = post_analyzers.plugin_custom_raw_mentions_users_J
          plugin_post_groups_mentions = post_analyzers.plugin_custom_raw_mentions_groups_J
          plugin_target_users_array_J = plugin_post_users_mentions
           plugin_target_users_array_J.each do |plugin_target_user_str_J|
            plugin_target_user_J = User.find_by(username: plugin_target_user_str_J)
            next if plugin_target_user_J.nil?
            plugin_can_send_PM_J = false            
            plugin_target_groups_J = GroupUser.select("*").where(user_id: plugin_target_user_J.id).where("groups.automatic = 'f'").joins(:group)
            plugin_target_groups_array_J = Array.new
            plugin_target_groups_J.each do |object|
                plugin_target_groups_array_J << object.name
             end
             if(self.user.custom_fields["secondary_group"].nil?)
                plugin_source_secondary_group_J =  Array.new
             else
                 plugin_source_secondary_group_J =  JSON.parse(self.user.custom_fields["secondary_group"])
             end 
             if(!((plugin_source_secondary_group_J & plugin_target_groups_array_J).empty? ))
                   plugin_can_send_PM_J = true
              else
                 unless self.user['primary_group_id'].nil?
                      if(plugin_target_user_J['primary_group_id'] == self.user['primary_group_id'])
                          plugin_can_send_PM_J = true
                      else
                          plugin_can_send_PM_J = false
                      end
                 end   
              end
              plugin_source_user_J = self.user
              plugin_source_groups_J = GroupUser.select("*").where(user_id: plugin_source_user_J.id).where("groups.automatic = 'f'").joins(:group)
              plugin_source_groups_array_J = Array.new
              plugin_source_groups_J.each do |object|
                  plugin_source_groups_array_J << object.name
              end             
              if(plugin_can_send_PM_J == false)
                break  
              end 
           end
           plugin_target_groups_array_J = plugin_post_groups_mentions
           plugin_target_groups_array_J.each do |plugin_target_group_str_J|
              plugin_can_send_PM_J = false
              plugin_source_user_J =  self.user
              plugin_source_groups_J = GroupUser.select("*").where(user_id: plugin_source_user_J.id).where("groups.automatic = 'f'").joins(:group)
              plugin_source_groups_array_J = Array.new
              plugin_source_groups_J.each do |object|
                  plugin_source_groups_array_J << object.name
              end
              plugin_source_groups_array_J.each do |plugin_source_group_str_J| 
                if(plugin_target_group_str_J == plugin_source_group_str_J)
                  plugin_can_send_PM_J = true
                end
              end
              if(plugin_source_user_J.custom_fields["secondary_group"].nil?)
                plugin_secondary_group_J =  Array.new
              else
                 plugin_secondary_group_J =  JSON.parse(plugin_source_user_J.custom_fields["secondary_group"])
              end                
              plugin_secondary_group_J.each do |plugin_secondary_group_str_J| 
                if(plugin_target_group_str_J == plugin_secondary_group_str_J)
                  plugin_can_send_PM_J = true
                end
              end
              if(plugin_can_send_PM_J == false)
                break  
              end 
           end
           plugin_source_user_J =  self.user
           if(plugin_source_user_J.admin?)
             plugin_can_send_PM_J = true
           end
           if plugin_can_send_PM_J
              creator = PostCreator.new(@user, @args)
              post = creator.create
              result.check_errors_from(creator)
              if result.success?
                result.post = post
              else
                @user.flag_linked_posts_as_spam if creator.spam?
              end  
           else
            result.errors[:base] <<'Unauthorized'
          end  
        else
            creator = PostCreator.new(@user, @args)
            post = creator.create
            result.check_errors_from(creator)
            if result.success?
              result.post = post
            else
              @user.flag_linked_posts_as_spam if creator.spam?
            end  
        end 
        result
      end            
    end
    UserSerializer.class_eval do
      def can_send_private_message_to_user
        plugin_can_send_PM_J = false
        if(scope.can_send_private_message?(object) && scope.current_user != object )
            plugin_target_groups_J = GroupUser.select("*").where(user_id: object.id).where("groups.automatic = 'f'").joins(:group)
            plugin_target_groups_array_J = Array.new
            plugin_target_groups_J.each do |object|
                plugin_target_groups_array_J << object.name
             end
            if(scope.current_user.custom_fields["secondary_group"].nil?)
              plugin_source_secondary_group_J =  Array.new
            else
               plugin_source_secondary_group_J =  JSON.parse(scope.current_user.custom_fields["secondary_group"])
            end              
            if(!((plugin_source_secondary_group_J & plugin_target_groups_array_J).empty? ))
                 plugin_can_send_PM_J = true
            else
               unless scope.current_user['primary_group_id'].nil?
                    if(object['primary_group_id'] == scope.current_user['primary_group_id'])
                        plugin_can_send_PM_J = true
                    else
                        plugin_can_send_PM_J = false
                    end
                 end   
            end
            plugin_source_user_J = scope.current_user
            plugin_source_groups_J = GroupUser.select("*").where(user_id: plugin_source_user_J.id).where("groups.automatic = 'f'").joins(:group)
            plugin_source_groups_array_J = Array.new
            plugin_source_groups_J.each do |object|
                plugin_source_groups_array_J << object.name
            end            
           if(plugin_source_user_J.admin?)
               plugin_can_send_PM_J = true
           end
        end
        plugin_can_send_PM_J
      end   
   end
   ComposerMessagesFinder.class_eval do
      def check_education_message
        return if @topic&.private_message?
        if creating_topic?
          count = @user.created_topic_count
          education_key = 'education.new-topic'
        else
          count = @user.post_count
          education_key = 'education.new-reply'
        end
        if( @details[:composer_action] == "privateMessage")
          count = Post
          .joins(:topic)
          .where(user_id: @user.id) 
          .where("topics.archetype = 'private_message'")
          .count
        end
        if count < SiteSetting.educate_until_posts
          return {
            id: 'education',
            templateName: 'education',
            wait_for_typing: true,
            body: PrettyText.cook(
              I18n.t(
                education_key,
                education_posts_text: I18n.t('education.until_posts', count: SiteSetting.educate_until_posts),
                site_name: SiteSetting.title,
                base_path: Discourse.base_path
              )
            )
          }
        end
        nil
      end
   end
   Search.class_eval do
     def user_search
      return if SiteSetting.hide_user_profiles_from_public && !@guardian.user
      plugin_user_J = User.find(@opts[:user_id])
      if(plugin_user_J.custom_fields["secondary_group"].nil?)
        plugin_secondary_group_J =  Array.new
      else
         plugin_secondary_group_J =  JSON.parse(plugin_user_J.custom_fields["secondary_group"])
      end
      plugin_where_query_array_J=Array.new;
      plugin_having_query_array_J = Array.new
      plugin_secondary_group_J.each do |plugin_temp_secondary_group_J|
        plugin_having_query_array_J <<  " '"+plugin_temp_secondary_group_J+"' = ANY (array_agg(groups.name)) "
      end
      unless plugin_user_J['primary_group_id'].nil?
         plugin_having_query_array_J << ' "users"."primary_group_id" = '+plugin_user_J['primary_group_id'].to_s
      end
      plugin_where_query_J =plugin_where_query_array_J.join("OR")
      plugin_having_query_J =plugin_having_query_array_J.join("OR")
      if(plugin_having_query_J == "")
        plugin_having_query_J = '1=2'
      end
      if(plugin_user_J.admin?)
        users = User.includes(:user_search_data)
        .references(:user_search_data)
        .joins(' FULL JOIN user_custom_fields ON "user_custom_fields"."user_id"="users"."id"')
        .joins(' INNER JOIN group_users ON "group_users"."user_id"="users"."id"')
        .joins(' INNER JOIN groups ON "group_users"."group_id"="groups"."id"')
        .where(active: true)
        .where(staged: false)
        .where("user_search_data.search_data @@ #{ts_query("simple")}")
        .order("CASE WHEN username_lower = '#{@original_term.downcase}' THEN 0 ELSE 1 END")
        .order("last_posted_at DESC")
        .group('"users"."id"')
        .group('"user_search_data"."user_id"')
        .limit(limit)  
      else
        users = User.includes(:user_search_data)
        .references(:user_search_data)
        .joins(' FULL JOIN user_custom_fields ON "user_custom_fields"."user_id"="users"."id"')
        .joins(' INNER JOIN group_users ON "group_users"."user_id"="users"."id"')
        .joins(' INNER JOIN groups ON "group_users"."group_id"="groups"."id"')
        .where(active: true)
        .where(staged: false)
        .where("user_search_data.search_data @@ #{ts_query("simple")}")
        .order("CASE WHEN username_lower = '#{@original_term.downcase}' THEN 0 ELSE 1 END")
        .order("last_posted_at DESC")
        .group('"users"."id"')
        .group('"user_search_data"."user_id"')
        .having(plugin_having_query_J)
        .limit(limit)
      end
      users.each do |user|
        @results.add(user)
      end
    end
  end   
    module ::CustomSecondarGroups
        class Engine < ::Rails::Engine
            engine_name "custom_secondary_groups"
            isolate_namespace CustomSecondarGroups
        end
    end
    class CustomSecondarGroups::SecondarygroupController < Admin::AdminController
        def clear_secondary_group
          me = User.find_by(username: params[:username]);
          objArray = Array.new
          me.custom_fields["secondary_group"] = objArray.to_json;
          me.save;
          render :json =>me.custom_fields["secondary_group"], :status => 200
        end
        def set_secondary_group
        	 me = User.find_by(username: params[:username])
        	 secondary_group =  params[:secondary_group].split(',')
        	 objArray = Array.new
             secondary_group.each do |object|
                objArray << object
             end
        	 me = User.find_by(username: params[:username])
        	 me.custom_fields["secondary_group"] = objArray.to_json
        	 me.save
        	 render :json =>me.custom_fields["secondary_group"], :status => 200
       end
       def view_secondary_group
           me = User.find_by(username: params[:username])
           render :json =>me.custom_fields["secondary_group"], :status => 200
       end
   end
   CustomSecondarGroups::Engine.routes.draw do
        get '/secondary_group_api/setgroup/:username/:secondary_group' => 'secondarygroup#set_secondary_group' , :constraints => {:username => /([^\/]+?)(?=\.json|\.html|$|\/)/} 
        get '/secondary_group_api/viewgroup/:username/' => 'secondarygroup#view_secondary_group'  , :constraints => {:username => /([^\/]+?)(?=\.json|\.html|$|\/)/ }
        get '/secondary_group_api/cleargroup/:username/' => 'secondarygroup#clear_secondary_group'  , :constraints => {:username => /([^\/]+?)(?=\.json|\.html|$|\/)/ }
    end
    DiscoursePluginRegistry.serialized_current_user_fields << 'encryptStatus'
    module ::EncryptStatus
        class Engine < ::Rails::Engine
            engine_name "encryptApi"
            isolate_namespace EncryptStatus
        end
    end
    class EncryptStatus::EncryptstatusController < Admin::AdminController
        def set_encrypt_status
           me = User.find_by(username: params[:username])
           me = User.find_by(username: params[:username])
           me.custom_fields["encryptStatus"] = params[:value]
           me.save
           render :json =>me.custom_fields["encryptStatus"], :status => 200
       end
   end
    EncryptStatus::Engine.routes.draw do
        get '/encryptstatus/setstatus/:username/:value' => 'encryptstatus#set_encrypt_status' , :constraints => {:username => /([^\/]+?)(?=\.json|\.html|$|\/)/} 
    end
    Discourse::Application.routes.append do
        mount ::CustomSecondarGroups::Engine, at: "/"
        mount ::EncryptStatus::Engine, at: "/"
    end
end
