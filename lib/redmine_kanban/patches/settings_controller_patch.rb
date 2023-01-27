module RedmineKanban
  module Patches
    module SettingsControllerPatch
      def self.included(base)
        base.class_eval do
          helper :translation
        end
      end

    end
  end
end

unless SettingsController.included_modules.include?(RedmineKanban::Patches::SettingsControllerPatch)
  SettingsController.send(:include, RedmineKanban::Patches::SettingsControllerPatch)
end

