
# requiring this file will automaticaly monkeypatch the matsuri command line tooling
# and support the Helm CRD
require 'active_support/concern'
require 'matsuri'

module Matsuri
  module Helm
    module Cmd
      module Apply
        extend ActiveSupport::Concern

        included do
          desc 'helm/release NAME', 'apply a helm release'
          define_method(:helm_release) do |name, dry_run = false|
            apply_resource { Matsuri::Registry.fetch_or_load(:helm_release, name).new(dry_run: dry_run) }
          end
          map 'helm/release': :helm_release
        end

      end

      module Show
        extend ActiveSupport::Concern

        included do
          desc 'helm/release NAME', 'show a helm release'
          show_cmd_for 'helm_release'

        end
      end

      module Delete
        extend ActiveSupport::Concern

        included do
          desc 'helm/release NAME', 'delete a helm release'
          delete_cmd_for 'helm_release'
        end
      end

      module Diff
        extend ActiveSupport::Concern

        included do
          desc 'helm/release NAME', 'diff a helm release'
          diff_cmd_for 'helm_release'
        end
      end

    end
  end
end

# TODO: implement the other commands
Matsuri::Cmds::Apply.send(:include, Matsuri::Helm::Cmd::Apply)
# Matsuri::Cmds::Create.send(:include, Matsuri::Helm::Cmd::Create)
# Matsuri::Cmds::Delete.send(:include, Matsuri::Helm::Cmd::Delete)
# Matsuri::Cmds::Recreate.send(:include, Matsuri::Helm::Cmd::Recreate)
# Matsuri::Cmds::Show.send(:include, Matsuri::Helm::Cmd::Show)
# Matsuri::Cmds::Diff.send(:include, Matsuri::Helm::Cmd::Diff)
