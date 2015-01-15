require 'json'

module Hacienda
  class Metadata

    def initialize(metadata_hash)
      @metadata_hash = metadata_hash
    end

    def has_languages?
      !draft_languages.empty? or !public_languages.empty?
    end

    def remove_for_locale(locale)
      remove_draft_language(locale)
      remove_public_language(locale)
      remove_last_modified(locale)
      remove_last_modified_by(locale)
    end

    def add_draft_language(locale)
      draft_languages << locale
      self
    end

    def add_public_language(locale)
      public_languages << locale
      self
    end

    def draft_languages
      available_languages[:draft]
    end

    def public_languages
      available_languages[:public]
    end

    def to_json
      @metadata_hash.to_json
    end

    def id
      @metadata_hash[:id]
    end

    def canonical_language
      @metadata_hash[:canonical_language]
    end

    def has_draft_language?(locale)
      draft_languages.include?(locale)
    end

    def has_public_language?(locale)
      public_languages.include?(locale)
    end

    def any_translation_in?(state)
      not available_languages[state.to_sym].empty?
    end

    def last_modified(locale)
      if @metadata_hash[:last_modified] and @metadata_hash[:last_modified][locale.to_sym]
        @metadata_hash[:last_modified][locale.to_sym]
      else
        DateTime.new(1970, 1, 1).to_s
      end
    end

    def last_modified_by(locale)
      if @metadata_hash[:last_modified_by] and @metadata_hash[:last_modified_by][locale.to_sym]
        @metadata_hash[:last_modified_by][locale.to_sym]
      else
        'Unknown'
      end
    end

    def update_last_modified(locale, datetime)
      @metadata_hash[:last_modified] ||= {}
      @metadata_hash[:last_modified][locale.to_sym] = datetime.to_s
    end

    def update_last_modified_by(locale, author)
      @metadata_hash[:last_modified_by] ||= {}
      @metadata_hash[:last_modified_by][locale.to_sym] = author
    end

    private

    def available_languages
      @metadata_hash[:available_languages]
    end

    def remove_draft_language(locale)
      draft_languages.reject! { |draft_locale| draft_locale == locale }
    end

    def remove_public_language(locale)
      public_languages.reject! { |public_locale| public_locale == locale }
    end

    def remove_last_modified(locale)
      @metadata_hash[:last_modified].reject! { |last_mod_locale| last_mod_locale.to_s == locale }
    end

    def remove_last_modified_by(locale)
      @metadata_hash[:last_modified_by].reject! { |last_mod_locale| last_mod_locale.to_s == locale }
    end
  end
end