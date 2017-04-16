require 'prawn/table'

class LogsController < ApplicationController

  before_filter :authenticate_volunteer!, :except => :stats_service
  before_filter :admin_only, :only => [:today, :tomorrow, :yesterday, :being_covered, :tardy, :receipt, :new, :create, :stats, :export]

  def mine_past
    index(Log.past_for(current_volunteer.id), 'My Past Shifts')
  end

  def mine_upcoming
    index(Log.upcoming_for(current_volunteer.id), 'My Upcoming Shifts')
  end

  def open
    index(Log.needing_coverage(current_volunteer.region_ids), 'Open Shifts')
  end

  def by_day
    if params[:date].present?
      date = Date.civil(*params[:date].sort.map(&:last).map(&:to_i))
    else
      n = params[:n].present? ? params[:n].to_i : 0
      date = Time.zone.today+n
    end
    index(Log.where("region_id IN (#{current_volunteer.region_ids.join(',')}) AND \"when\" = '#{date}'"), "Shifts on #{date.strftime('%A, %B %-d')}")
  end

  def last_ten
    index(Log.where("region_id IN (#{current_volunteer.region_ids.join(',')}) AND \"when\" >= '#{(Time.zone.today-10)}'"), 'Last 10 Days of Shifts')
  end

  def being_covered
    index(Log.being_covered(current_volunteer.region_ids), 'Being Covered')
  end

  def todo
    index(Log.past_for(current_volunteer.id).where('"when" < current_date AND NOT complete'), 'My To Do Shift Reports')
  end

  def tardy
    index(Log.where("region_id IN (#{current_volunteer.region_ids.join(',')}) AND \"when\" < current_date AND NOT complete and num_reminders >= 3", 'Missing Data (>= 3 Reminders)'), 'Missing Data (>= 3 Reminders)')
  end

  def index(logs=nil, header='Entire Log')
    @shifts = []
    if current_volunteer.region_ids.length > 0
      @shifts = Shift.build_shifts(logs.nil? ? Log.where("region_id IN (#{current_volunteer.region_ids.join(',')})"): logs)
    end
    @header = header
    @regions = Region.all
    @my_admin_regions = if current_volunteer.super_admin?
                          @regions
                        else
                          current_volunteer.assignments.collect{ |a| a.admin ? a.region : nil }.compact
                        end
    respond_to do |format|
      format.json { render json: @shifts }
      format.html { render :index }
    end
  end

  def stats
    @regions = current_volunteer.admin_regions(true)
    @regions = Region.all if current_volunteer.admin? and @regions.empty?
    @first_recorded_pickup = Log.where("complete AND region_id in (#{@regions.collect{ |r| r.id }.join(',')})").
      order('logs.when ASC').limit(1)
    @pounds_per_year = Log.joins(:log_parts).select('extract(YEAR from logs.when) as year, sum(weight)').
      where("complete AND region_id in (#{@regions.collect{ |r| r.id }.join(',')})").
      group('year').order('year ASC').collect{ |l| [l.year, l.sum] }
    @pounds_per_month = Log.joins(:log_parts).select("date_trunc('month',logs.when) as month, sum(weight)").
      where("complete AND region_id in (#{@regions.collect{ |r| r.id }.join(',')})").
      group('month').order('month ASC').collect{ |l| [Date.parse(l.month).strftime('%Y-%m'), l.sum] }
    @transport_per_year = {}
    @transport_years = []
    @transport_data = Log.joins(:transport_type).select('extract(YEAR from logs.when) as year, transport_types.name, count(*)').
      where("complete AND region_id in (#{@regions.collect{ |r| r.id }.join(',')})").
      group('name,year').order('name,year ASC')
    @transport_years.sort!
    @transport_data.each{ |l|
      @transport_years << l.year unless @transport_years.include? l.year
      @transport_per_year[l.name] = [] if @transport_per_year[l.name].nil?
    }
    @transport_per_year.keys.each{ |k|
      @transport_per_year[k] = @transport_years.collect{ |_y| 0 }
    }
    @transport_data.each{ |l|
      @transport_per_year[l.name][@transport_years.index(l.year)] = l.count.to_i
    }
  end

  def stats_service
    case params[:what]
    when 'poundage'
      if params[:region_id].nil?
        total = LogPart.sum(:weight) + Region.where('prior_lbs_rescued IS NOT NULL').sum('prior_lbs_rescued')
      else
        region_id = params[:region_id]
        @region = Region.find(region_id)
        total = Log.joins(:log_parts).where('region_id = ? AND complete', region_id).sum('weight').to_f
        total += @region.prior_lbs_rescued.to_f unless @region.nil? or @region.prior_lbs_rescued.nil?
      end
      render :text => total.to_s
    when 'wordcloud'
      words = {}
      LogPart.select('description').where('description IS NOT NULL').each{ |log_part|
        log_part.description.strip.split(/\s*\,\s*/).each{ |word|
          word = word.strip.downcase.tr(',', '')
          next if word =~ /(nothing|no |none)/ or word =~ /etc/ or word =~ /n\/a/ or word =~ /misc/
          # people cannot seem to spell the most delicious fruit correctly
          word = 'avocados' if %w(avacados avocadoes avocado).include?(word)
          words[word] = 0 if words[word].nil?
          words[word] += 1
        }
      }
      render :text => words.collect{ |k, v| (v >= 10) ? "#{k}:#{v}" : nil }.compact.join(',')
    when 'transport'
      rq = ''
      wq = ''
      unless params[:region_id].nil?
        rq = "AND region_id=#{params[:region_id].to_i}"
      end
      unless params[:timespan].nil?
        if params[:timespan] == 'month'
          wq = "AND \"when\" > NOW() - interval '1 month'"
        end
      end
      noncar = Log.where("complete AND transport_type_id IN (SELECT id FROM transport_types WHERE name != 'Car') #{rq} #{wq}").count.to_f
      car = Log.where("complete AND transport_type_id IN (SELECT id FROM transport_types WHERE name = 'Car') #{rq} #{wq}").count.to_f
      render :text => "#{100.0*noncar/(noncar+car)} #{100.0*car/(noncar+car)}"
    else
      render :text => 'NO'
    end
  end

  def destroy
    @log = Log.find(params[:id])
    authorize! :destroy, @log
    @log.destroy
    redirect_to(request.referrer)
  end

  def new
    @region = Region.find(params[:region_id])
    @log = Log.new
    @log.region = @region
    @action = 'create'
    authorize! :create, @log
    session[:my_return_to] = request.referer
    set_vars_for_form @region
    render :new
  end

  def create
    @log = Log.new(params[:log])
    @region = @log.region
    @food_types = @region.food_types.collect{ |e| [e.name, e.id] }
    @scale_types = @region.scale_types.collect{ |e| [e.name, e.id] }
    @transport_types = TransportType.all.collect{ |e| [e.name, e.id] }
    if @scale_types.length<2 and @log.scale_type_id.nil?
      @log.scale_type_id = @region.scale_types.first.id
    end
    authorize! :create, @log
    parse_and_create_log_parts(params, @log)
    finalize_log(@log)
    if @log.save
      flash[:notice] = 'Created successfully.'
      unless session[:my_return_to].nil?
        redirect_to(session[:my_return_to])
      else
        index
      end
    else
      flash[:notice] = "Didn't save successfully :("
      render :new
    end
  end

  def show
    @log = Log.find(params[:id])
    authorize! :read, @log
    respond_to do |format|
      format.html
      format.json {
        attrs = {}
        attrs[:log] = @log.attributes
        attrs[:log][:recipient_ids] = @log.recipient_ids
        attrs[:log][:volunteer_ids] = @log.volunteer_ids
        attrs[:log][:volunteer_names] = @log.volunteers.collect{ |v| v.name }
        attrs[:schedule] = @log.schedule_chain.attributes unless @log.schedule_chain.nil?
        attrs[:log_parts] = {}
        @log.log_parts.each{ |lp| attrs[:log_parts][lp.id] = lp.attributes }
        render json: attrs
      }
    end
  end

  def edit
    @log = Log.find(params[:id])
    authorize! :update, @log
    @region = @log.region
    @action = 'update'
    session[:my_return_to] = request.referer
    set_vars_for_form @region
    render :edit
  end

  def update
    @log = Log.find(params[:id])
    @region = @log.region
    @action = 'update'
    set_vars_for_form @region

    unless can?(:update, @log)
      flash[:notice] = 'Not authorized to edit that log item.'
      respond_to do |format|
        format.json { render json: {:error => 1, :message => flash[:notice] } }
        format.html { redirect_to(root_path) }
      end
      return
    end

    parse_and_create_log_parts(params, @log)

    if @log.update_attributes(params[:log])
      finalize_log(@log)

      if @log.save
        if @log.complete
          flash[:notice] = 'Updated Successfully. All done!'
        else
          flash[:warning] = "Saved, but some weights/counts still needed to complete this log. Finish it here: <a href=\"/logs/#{@log.id}/edit\">(Fill In)</a>".html_safe
        end
        respond_to do |format|
          format.json { render json: {error: 0, message: flash[:notice] } }
          format.html { render :edit }
        end
      else
        flash[:error] = 'Failed to mark as complete.'
        respond_to do |format|
          format.json { render json: {error: 2, message: flash[:notice] } }
          format.html { render :edit }
        end
      end
    else
      flash[:error] = 'Update failed :('
      respond_to do |format|
        format.json { render json: {error: 1, message: flash[:notice] } }
        format.html { render :edit }
      end
    end
  end

  # can be given a single id or a list of ids
  def take
    logs = unless params[:ids].present?
             [Log.find(params[:id])]
           else
             Log.find(params[:ids])
           end

    if logs.all? { |log| can?(:take, log) }
      logs.each do |log|
        LogVolunteer.create(volunteer: current_volunteer, covering: true, log: log)
      end
      flash[:notice] = "Successfully took a shift with #{logs.length} donor(s)."
    else
      flash[:notice] = "Cannot take shifts for regions that you aren't assigned to!"
    end

    respond_to do |format|
      format.json {
        render json: {error: 0, message: flash[:notice]}
      }
      format.html {
        redirect_to :back
      }
    end

  end

  # can be given a single id or a list of ids
  def leave
    logs =
      unless params[:ids].present?
        [Log.find(params[:id])]
      else
        params[:ids].collect{ |id| Log.find(id) }
      end

    logs.each { |log| authorize! :leave, log }

    logs.each do |log|
      if log.has_volunteer? current_volunteer
        LogVolunteer.where(volunteer_id: current_volunteer.id, log_id: log.id).each{ |log_volunteer|
          log_volunteer.active = false
          log_volunteer.save
        }
      end
    end
    flash[:notice] = "You left a pickup with #{l.length} donor(s)."
    redirect_to :back
  end

  def receipt
    if Date.valid_date?(params[:start_date][:year].to_i, params[:start_date][:month].to_i, params[:start_date][:day].to_i)
      @start_date = Date.new(params[:start_date][:year].to_i, params[:start_date][:month].to_i, params[:start_date][:day].to_i)
    else
      flash[:notice] = 'Invalid Date Set for Start Date. Please try again!'
      return redirect_to(request.referer || root_path)
    end

    if Date.valid_date?(params[:stop_date][:year].to_i, params[:stop_date][:month].to_i, params[:stop_date][:day].to_i)
      @stop_date = Date.new(params[:stop_date][:year].to_i, params[:stop_date][:month].to_i, params[:stop_date][:day].to_i)
    else
      flash[:notice] = 'Invalid Date Set for End Date. Please try again!'
      return redirect_to(request.referer || root_path)
    end

    @location = Location.find(params[:location_id])

    authorize! :receipt, @location

    @logs = Log.where('logs.when >= ? AND logs.when <= ? AND donor_id = ? AND complete', @start_date, @stop_date, @location.id)

    respond_to do |format|
      format.html
      format.pdf do
        pdf = Prawn::Document.new
        pdf.font_size 20
        pdf.text @location.region.title, :align => :center

        unless @location.region.tagline.nil?
          pdf.move_down 10
          pdf.font_size 12
          pdf.text @location.region.tagline, :align => :center
        end

        unless @location.region.address.nil?
          pdf.font_size 10
          pdf.font 'Times-Roman'
          pdf.move_down 10
          pdf.text "#{@location.region.address.tr("\n", ', ')}", :align => :center
        end

        unless @location.region.website.nil?
          pdf.move_down 5
          pdf.text "#{@location.region.website}", :align => :center
        end
        unless @location.region.phone.nil?
          pdf.move_down 5
          pdf.text "#{@location.region.phone}", :align => :center
        end
        pdf.move_down 10
        pdf.text "Federal Tax-ID: #{@location.region.tax_id}", :align => :right
        pdf.text "Receipt period: #{@start_date} to #{@stop_date}", :align => :left
        pdf.move_down 5
        pdf.text "Receipt for: #{@location.name}", :align => :center
        pdf.move_down 10
        pdf.font 'Helvetica'
        sum = 0.0
        pdf.table([['Date', 'Description', 'Log #', 'Weight (lbs)']] + @logs.collect{ |l|
          sum += l.summed_weight
          l.summed_weight == 0 ? nil : [l.when, l.log_parts.collect{ |lp| lp.food_type.nil? ? nil : lp.food_type.name }.compact.join(','), l.id, l.summed_weight]
        }.compact + [['Total:', '', '', sum]])
        pdf.move_down 20
        pdf.font_size 10
        pdf.font 'Courier', :style => :italic
        pdf.text "This receipt was generated by The Food Rescue Robot at #{Time.zone.now}. Beep beep mrrrp!", :align => :center
        send_data pdf.render
      end
    end
  end

  def export
    start_date = Date.new(params[:start_date][:year].to_i, params[:start_date][:month].to_i, params[:start_date][:day].to_i)
    stop_date = Date.new(params[:stop_date][:year].to_i, params[:stop_date][:month].to_i, params[:stop_date][:day].to_i)
    regions = current_volunteer.admin_regions

    logs = Log.where('logs.when >= ? AND logs.when <= ?', start_date, stop_date).where(
      complete: true,
      region_id: regions.map(&:id)
    )

    respond_to do |format|
      format.html
      format.csv do
        send_data logs.to_csv
      end
    end
  end

  private

  def parse_and_create_log_parts(params, log)
    ret = []
    params['log_parts'].each{ |_dc, lpdata|
      lpdata['weight'] = nil if lpdata['weight'].strip == ''
      lpdata['count'] = nil if lpdata['count'].strip == ''
      next if lpdata['id'].nil? and lpdata['weight'].nil? and lpdata['count'].nil?
      log_part = lpdata['id'].nil? ? LogPart.new : LogPart.find(lpdata['id'].to_i)
      log_part.count = lpdata['count']
      log_part.description = lpdata['description']
      log_part.food_type_id = lpdata['food_type_id'].to_i
      log_part.log_id = log.id
      log_part.weight = lpdata['weight'].to_f
      ret.push log_part
      log_part.save
    } unless params['log_parts'].nil?
    ret
  end

  def finalize_log(log)
    # mark as complete if deserving
    filled_count = 0
    required_unfilled = 0

    log.log_parts.each{ |log_part|
      required_unfilled += 1 if log_part.required && log_part.weight.nil? && log_part.count.nil?
      filled_count += 1 unless log_part.weight.nil? && log_part.count.nil?
    }
    log.complete = filled_count > 0 && required_unfilled == 0
  end

  def admin_only
    redirect_to(root_path) unless current_volunteer.any_admin?
  end

end
