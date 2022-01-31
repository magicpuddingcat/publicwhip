# frozen_string_literal: true

module PolicyPersonDistancesHelper
  # Returns things like "voted strongly against", "has never voted on", etc..
  def policy_agreement_summary(policy_person_distance, with_person: false, link_person: false, with_policy: false, link_policy: false)
    member = policy_person_distance.person.latest_member
    policy = policy_person_distance.policy
    category = policy_person_distance.category(current_user)

    category_words_sentence(category: category, member: member, policy: policy,
                            with_person: with_person, with_policy: with_policy,
                            link_person: link_person, link_policy: link_policy)
  end

  def category_words_sentence(category:, member:, policy:,
                              with_person: false, with_policy: false,
                              link_person: false, link_policy: false)
    person_content = (link_to_if(link_person, member.name, member_path_simple(member)) if with_person)
    policy_content = (link_to_if(link_policy, policy.name, policy) if with_policy)
    category_words_sentence2(category: category, person_content: person_content, policy_content: policy_content)
  end

  # This helper has to just concern itself with getting the correct word order for a particular category
  # So it's simpler to understand and test than category_words_sentence above
  def category_words_sentence2(category:, person_content:, policy_content:)
    out = []
    if category == :not_enough
      # For this category we have to order the sentence differently because it doesn't have the
      # same structure as the other sentences
      # Note that we're capitalising the first letter
      out << "We can't say anything concrete about how ".html_safe
      out << (person_content || "they")
      out << " voted on"
    else
      if person_content
        out << person_content
        out << " "
      end
      out << category_words(category)
    end

    if policy_content
      out << " "
      out << policy_content
    end
    safe_join(out)
  end

  def category_words(category)
    case category
    when :for3 then "voted consistently for"
    when :for2 then "voted almost always for"
    when :for1 then "voted generally for"
    when :mixture then "voted a mixture of for and against"
    when :against1 then "voted generally against"
    when :against2 then "voted almost always against"
    when :against3 then "voted consistently against"
    when :never then "has never voted on"
    when :not_enough then "we can't say anything concrete about how they voted on".html_safe
    else
      raise "Unsupported category #{category}"
    end
  end
end
