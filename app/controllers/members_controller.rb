# frozen_string_literal: true

class MembersController < ApplicationController
  before_action :find_member_and_redirect_to_canonical, only: %i[show policy friends]

  def index
    @sort = params[:sort]
    @house = params[:house]

    members = Member.current
    if @house
      raise ActiveRecord::RecordNotFound unless House.australian.include?(@house)

      members = members.in_house(@house)
    end
    members = members.includes(:member_info, person: [members: :member_info]).to_a

    members = case @sort
              when "constituency"
                members.sort_by { |m| [m.constituency, m.last_name, m.first_name, m.party, -m.entered_house.to_time.to_i] }
              when "party"
                members.sort_by { |m| [m.party, m.last_name, m.first_name, m.constituency, -m.entered_house.to_time.to_i] }
              when "rebellions"
                members.sort_by { |m| [-(m.person.rebellions_fraction || -1), m.last_name, m.first_name, m.constituency, m.party, -m.entered_house.to_time.to_i] }
              when "attendance"
                members.sort_by { |m| [-(m.person.attendance_fraction || -1), m.last_name, m.first_name, m.constituency, m.party, -m.entered_house.to_time.to_i] }
              else
                members.sort_by { |m| [m.last_name, m.first_name, m.constituency, m.party, -m.entered_house.to_time.to_i] }
              end
    @people = members.map(&:person)
  end

  def show_redirect
    member = if params[:mpid]
               Member.find(params[:mpid])
             elsif params[:id]
               begin
                 Member.find_by!(gid: params[:id])
               rescue ActiveRecord::RecordNotFound
                 Member.find_by!(gid: params[:id].gsub(/member/, "lord"))
               end
             else
               raise ActiveRecord::RecordNotFound
             end
    if params[:dmp]
      redirect_to member_policy_url(member.url_params.merge(id: params[:dmp]))
    else
      redirect_to member_url(member.url_params)
    end
  end

  def friends; end

  def show
    @cardtype = params[:type] # needs to be placed here otherwise it will not work (when placed within the else block)
    # If this isn't a social sharing card then just use the default view
    return if params[:card].nil?

    if params[:category]
      @card_title, @policies, @number_left = helpers.member_policy_category(@member, params[:category], max_policies: 4)
      render "card/member_category_card", layout: "card_layout"
    else
      render "card/member_card", layout: "card_layout"
    end
  end

  def policy
    @policy = Policy.find(params[:id])

    # Pick the member where the votes took place
    @member = @member.person.member_for_policy(@policy)
    # TODO: Ideally the view template below should only need @policy_person_distance not @policy and @member
    # If policy_person_distance doesn't exist then return a 404
    @policy_person_distance = @member.person.policy_person_distances.find_by!(policy: @policy)

    return render "policies/show_with_member" if params[:card].nil?

    render "card/policy_with_member_card", layout: "card_layout"
  end

  def compare
    @member1 = Member.find_with_url_params(house: params[:house], mpc: params[:mpc], mpn: params[:mpn])
    @member2 = Member.find_with_url_params(house: params[:house2], mpc: params[:mpc2], mpn: params[:mpn2])
    return render "member_not_found", status: :not_found if @member1.nil? || @member2.nil?

    canonical_member1 = @member1.person.latest_member
    canonical_member2 = @member2.person.latest_member
    if canonical_member1 != @member1 || canonical_member2 != @member2
      redirect_to canonical_member1.url_params.merge(
        mpc2: canonical_member2.url_electorate.downcase,
        mpn2: canonical_member2.url_name.downcase
      )
      return
    end

    @person_distance = PeopleDistance.find_by(person1: @member1.person, person2: @member2.person)

    policy_ids_at_least_once_differently = PolicyDivision.where(division: @person_distance.divisions_different).published.group(:policy_id).pluck(:policy_id).to_set
    policy_ids_at_least_once_same = PolicyDivision.where(division: @person_distance.divisions_same).published.group(:policy_id).pluck(:policy_id).to_set
    policy_ids_different_and_same = policy_ids_at_least_once_differently & policy_ids_at_least_once_same
    policy_ids_all_different = policy_ids_at_least_once_differently - policy_ids_different_and_same
    policy_ids_all_same = policy_ids_at_least_once_same - policy_ids_different_and_same
    @policies_all_same = Policy.find(policy_ids_all_same.to_a)
    @policies_all_different = Policy.find(policy_ids_all_different.to_a)
    @policies_different_and_same = Policy.find(policy_ids_different_and_same.to_a)
  end

  private

  def find_member_and_redirect_to_canonical
    @member = Member.find_with_url_params(house: params[:house], mpc: params[:mpc], mpn: params[:mpn])
    return render "member_not_found", status: :not_found if @member.nil?

    canonical_member = @member.person.latest_member
    return if canonical_member == @member

    redirect_to canonical_member.url_params
  end
end
