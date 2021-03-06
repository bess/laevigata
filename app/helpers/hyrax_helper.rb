module HyraxHelper
  include ::BlacklightHelper
  include Hyrax::BlacklightOverride
  include Hyrax::HyraxHelperBehavior

  ##
  # override behavior from `Hyrax::EmbargoHelper`
  def assets_under_embargo
    @assets_under_embargo ||= EtdEmbargoService.assets_under_embargo
  end

  ##
  # override behavior from `Hyrax::AbilityHelper`
  def visibility_options(variant, opts = {})
    options = [
      Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC,
      VisibilityTranslator::FILES_EMBARGOED,
      VisibilityTranslator::TOC_EMBARGOED,
      VisibilityTranslator::ALL_EMBARGOED,
      Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE
    ]

    case variant
    when :restrict
      options.delete_at(4) # Private is not a valid embargo option
      options.delete_at(0) # Public is not a valid embargo option
      # If there is a current_visibility passed, ensure it is
      # the first option in the list
      if opts[:current_visibility]
        options.delete(opts[:current_visibility])
        options << opts[:current_visibility]
      end
      options.reverse!

    when :loosen
      options = [Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC]
    end

    options.map { |value| [visibility_text(value), value] }
  end

  def visibility_badge(value)
    EtdPermissionBadge.new(value).render
  end
end
