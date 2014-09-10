class MembersController < ApplicationController
  def index_redirect
    redirect_to members_path(
      house: (params[:house] && params[:house] != "all" ? params[:house] : "representatives"),
      sort: (params[:sort] if params[:sort] != "lastname"))
  end

  def index
    @sort = params[:sort]
    @house = params[:house]

    members = Member.in_australian_house(@house).current.includes(:member_info)

    @members = case @sort
    when "constituency"
      members.order ["constituency", "last_name", "first_name", "party", "entered_house DESC"]
    when "party"
      members.order ["party", "last_name", "first_name", "constituency", "entered_house DESC"]
    when "date"
      members.order ["left_house", "last_name", "first_name", "constituency", "party", "entered_house DESC"]
    when "rebellions"
      members.to_a.sort_by { |m| m.person.rebellions_fraction || -1 }.reverse
    when "attendance"
      members.to_a.sort_by { |m| m.person.attendance_fraction || -1 }.reverse
    else
      members.order ["last_name", "first_name", "constituency", "party", "entered_house DESC"]
    end
  end

  def show_redirect
    if params[:mpid] || params[:id]
      if params[:mpid]
        member = Member.find_by!(id: params[:mpid])
      elsif params[:id]
        member = Member.find_by!(gid: params[:id])
      end
      redirect_to view_context.member_path2(member, dmp: params[:dmp], display: params[:display])
      return
    end
    if params[:dmp] && params[:display] == "allvotes"
      redirect_to params.merge(display: nil)
      return
    end
    if params[:display] == "summary" || params[:display] == "alldreams"
      redirect_to params.merge(display: nil)
      return
    end
    if params[:mpc] == "Senate" || params[:mpc].nil? || params[:house].nil?
      member = Member.with_name(params[:mpn].gsub("_", " "))
      member = member.in_australian_house(params[:house]) if params[:house]
      member = member.order(entered_house: :desc).first
      if member.nil?
        render 'member_not_found', status: 404
        return
      end
      redirect_to view_context.member_path2(member, dmp: params[:dmp], display: params[:display])
      return
    end
    if params[:display] == "allvotes" || params[:showall] == "yes"
      redirect_to params.merge(showall: nil, display: "everyvote")
    end
  end

  def show
    electorate = params[:mpc].gsub("_", " ")
    name = params[:mpn].gsub("_", " ")
    @display = params[:display]

    @member = Member.with_name(name)
    @member = @member.in_australian_house(params[:house])
    @member = @member.where(constituency: electorate)
    @member = @member.order(entered_house: :desc).first

    if @member.nil?
      render 'member_not_found', status: 404
      return
    end

    if params[:dmp]
      @policy = Policy.find(params[:dmp])
      # Pick the member where the votes took place
      @member = @member.person.member_for_policy(@policy)
      render "show_policy"
    else
      @members = Member.where(person_id: @member.person_id).order(entered_house: :desc)
      # Trying this hack. Seems mighty weird
      # TODO Get rid of this
      @member = @members.first if @member.senator?
      render "show"
    end
  end
end
