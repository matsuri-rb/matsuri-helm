
require 'active_support/core_ext/hash/compact'

# rubocop:disable Lint/MissingCopEnableDirective
# rubocop:disable Style/Alias
module Matsuri
  module Helm
    module K8S
      class Release < Matsuri::Kubernetes::Base
        include Let
        include RLet::LazyOptions
        include Matsuri::ShellOut


        let(:release_name)     { name }

        let(:helm_repo)        { Matsuri.fail 'Must define let(:helm_repo)' }
        let(:helm_chart)       { Matsuri.fail 'Must define let(:helm_chart)' }
        let(:chart_version)    { nil } # Override to pin version

        let(:namespace)        { nil } # Override to specify a namespace
        let(:repo_config_path) { ::Matsuri::Config.helm.repo_config_path }
        let(:kube_context)     { ::Matsuri.environment }

        let(:override_values)  { {} }
        let(:value_files)      { [] }

        ### Upgrade flags
        let(:dry_run?)                        { options[:dry_run?] }
        let(:install_if_not_exists?)          { true }
        let(:dependency_update?)              { true }
        let(:create_namespace_if_not_exists?) { true }
        let(:atonic?)                         { true }
        let(:wait_for_readiness?)             { nil }
        let(:wait_for_jobs?)                  { nil }
        let(:cleanup_on_fail?)                { true }
        let(:force_replace?)                  { false }
        let(:skip_crds?)                      { false }
        let(:reset_values?)                   { nil }
        let(:reuse_values?)                   { false }

        ### Args
        let(:upgrade_args) do
          [
            release_name,
            helm_chart,
            helm_flags_to_args(chart_args_map),
            helm_flags_to_args(upgrade_args_map),
            helm_flags_to_args(context_args_map),
            values_args,
            helm_set_values_to_args(override_values)
          ].flatten.compact
        end

        let(:chart_args_map) do
          {
            "--version"           => chart_version
          }
        end

        let(:context_args_map) do
          {
            "--kube-context"      => kube_context,
            "--namespace"         => namespace,
            "--repository-config" => repo_config_path
          }.compact
        end

        let(:upgrade_args_map) do
          {
            "--dry_run"           => dry_run?,
            "--install"           => install_if_not_exists?,
            "--dependency_update" => dependency_update?,
            "--create-namespace"  => create_namespace_if_not_exists?,
            "--atomic"            => atomic_upgrade?,
            "--wait"              => wait_for_readiness?,
            "--wait-for_jobs"     => wait_for_jobs?,
            "--cleanup_on_fail"   => cleanup_on_fail?,
            "--force"             => force_replace?,
            "--skip_crds"         => skip_crds?,
            "--reset_values"      => reset_values?,
            "--resue_values"      => reuse_values?,
          }
        end

        let(:values_args)   { normalized_values_paths.map { |p| "-f #{p}" } }

        # If a flag value is true, then just use that flag as the arg
        # Otherwise, set it as "--flag arg"
        # This will not work for helm "--set" flags
        def helm_flags_to_args(flags)
          flags.
            map do |(k,v)|
              case v
              when true       then k
              when false, nil then nil
              else
                "#{k} #{v}"
              end
            end.
            compact
        end

        def helm_set_values_to_args(values)
          values.
            compact.
            map { |(k,v)| "--set #{k}=#{v}" }
        end

        def helm_upgrade_cmd(args)
          final_args = args.join("\\\n")
          "helm upgrade \\\n#{final_args}"
        end

        def helm_upgrade(args, options = {})
          shell_out(helm_upgrade_cmd(args), options)
        end

        def helm_upgrade!(args, options = {})
          shell_out!(helm_upgrade_cmd(args), options)
        end

        class << self
          def load_path
            Matsuri::Config.helm.releases_path
          end

          def definition_module_name
            'HelmReleases'
          end
        end
      end
    end
  end
end
