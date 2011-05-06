class SubscriptionsController < ApplicationController
  
  before_filter :login_required, :only => :update
  before_filter :admin_only, :except => :update

  skip_before_filter :verify_authenticity_token

  # PUT /subscriptions/1
  # PUT /subscriptions/1.xml
  def update
    
    if current_user

      # Sanitize the form
      form = (params[:subscription] || {}).reverse_merge!(:sr_severity => 1, :note_added => true)

      form[:user_id] = current_user.id
      # form[:url_token] = params[:id] || ""
      form[:token] = (params[:id] || "").gsub('-', ' ')      
      form[:badge] = 0 # initially, there is no notification
      
      env = params[:env]
      logger.info "env=#{env}"
      if env == ENV["RAILS_ENV"]
        @subscription = Subscription.find(:first, :conditions => ["token = ?", form[:token]])      
        if @subscription
          @subscription.update_attributes(form)
        else
          @subscription = Subscription.new(form)
        end
      else
        errors = "Invalid environment"
      end if

      # logger.info "Gone fishing..."
      # sleep 5
      # logger.info "I'm back!"

      logger.info "Subscription before save = #{@subscription.inspect}"
    end
  
    respond_to do |format|
      if @subscription && @subscription.save
        flash[:notice] = 'Subscription was successfully created.'
        format.xml  { head :ok }
        format.json  { 
          # logger.info "format = #{request.inspect}"
          render :json => {:last_subscribed_at => Time.now.strftime("%m/%d/%Y %H:%M:%S %Z")}
        }
      else
        errors ||= "unprocessable entity"
        errors ||= @subscription.errors if @subscription
        format.xml  { render :xml => errors, :status => :unprocessable_entity }
        format.json  { render :json => errors, :status => :unprocessable_entity }
      end
    end


  end

  # DELETE /subscriptions/1
  # DELETE /subscriptions/1.xml
  def destroy
    @subscription = Subscription.find(params[:id])
    @subscription.destroy

    respond_to do |format|
      format.html { redirect_to(console_url) }
      format.xml  { head :ok }
    end
  end
end
