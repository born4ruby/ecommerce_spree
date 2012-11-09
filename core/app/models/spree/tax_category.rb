module Spree
  class TaxCategory < ActiveRecord::Base
    validates :name, :presence => true, :uniqueness => { :scope => :deleted_at }

    has_many :tax_rates, :dependent => :destroy

    before_save :set_default_category

    default_scope where(:deleted_at => nil)

    def set_default_category
      #set existing default tax category to false if this one has been marked as default

      if is_default && tax_category = self.class.where(:is_default => true).first
        tax_category.update_attribute(:is_default, false)
      end
    end

    def mark_deleted!
      self.deleted_at = Time.now
      self.save
    end
  end
end
