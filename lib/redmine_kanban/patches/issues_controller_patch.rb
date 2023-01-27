module RedmineKanban
  module Patches
    module IssuesControllerPatch
      def self.included(base)
        base.class_eval do
          helper :translation
        end
      end

    end
  end
end

unless IssuesController.included_modules.include?(RedmineKanban::Patches::IssuesControllerPatch)
  IssuesController.send(:include, RedmineKanban::Patches::IssuesControllerPatch)
end

