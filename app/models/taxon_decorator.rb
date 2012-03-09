module Spree
  Taxon.class_eval do
    translates :name, :description, :permalink
    globalize_accessors locales: SpreeMultiLingual.languages, attribtues: [:name, :description, :permalink]

    def translations_for(attribute_name)
      {}.tap do |attrs|
        translations.select([attribute_name, :locale]).each do |attribute|
          attr_name = "#{attribute_name}_#{attribute[:locale]}".to_sym
          attrs[attr_name] = attribute[attribute_name]
        end
      end
    end

    # Public : Permalink setter with multi language support
    #
    # string - The permalink part of the taxon
    #
    # Set the full permalink accordingly from the argument permalink
    #
    # Returns nothing
    (SpreeMultiLingual.languages + [""]).each do |locale|
      locale_suffix = locale.empty? ? "" : "_#{locale}"
      define_method("permalink#{locale_suffix}=") do |permalink_part|
        opts = locale.empty? ? {} : { :locale => locale.to_sym }
        unless new_record?
          _permalink = (read_attribute(:permalink, opts) || []).split("/")[0...-1]
          permalink_part = (_permalink << permalink_part).join("/")
        end
        write_attribute(:permalink, permalink_part, opts)
      end
    end


    # Creates permalink based on Stringex's .to_url method
    def set_permalink
      if parent_id.nil?
        self.permalink = name.to_url if self.permalink.blank?
      else
        parent_taxon = Taxon.find(parent_id)
        parent_taxon.translations_for(:permalink).each do |attribute_name, value|
          send("#{attribute_name}=", [value, (self.permalink.blank? ? name.to_url : self.permalink.split('/').last)].join('/'))
        end
        self.permalink = [parent_taxon.permalink, (self.permalink.blank? ? name.to_url : self.permalink.split('/').last)].join('/')
      end
    end
  end
end