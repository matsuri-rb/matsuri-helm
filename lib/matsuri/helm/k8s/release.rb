
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

        let(:helm_repo_url)    { fail NotImplementedError, 'Must define let(:helm_repo_url)' }
        let(:helm_repo_name)   { fail NotImplementedError, 'Must define let(:helm_repo_name)' }
        let(:helm_chart)       { "#{helm_repo_name}/#{chart_name}" }
        let(:chart_name)       { fail NotImplementedError, 'Must define let(:chart_name)' }
        let(:chart_version)    { nil } # Override to pin version

        let(:namespace)        { nil } # Override to specify a namespace
        let(:repo_config_path) { ::Matsuri::Config.helm.repo_config_path }
        let(:kube_context)     { ::Matsuri.environment }

        let(:override_values)  { {} }
        let(:value_files)      { fail NotImplementedError, 'Must define let(:value_files), set to [] if you do not want to value files' }

        ### Upgrade flags
        let(:dry_run?)                        { !!options[:dry_run] }
        let(:install_if_not_exists?)          { true }
        let(:dependency_update?)              { true }
        let(:create_namespace_if_not_exists?) { true }
        let(:atomic_upgrade?)                 { true }
        let(:wait_for_readiness?)             { nil }
        let(:wait_for_jobs?)                  { nil }
        let(:cleanup_on_fail?)                { true }
        let(:force_replace?)                  { false }
        let(:skip_crds?)                      { false }
        let(:reset_values?)                   { nil }
        let(:reuse_values?)                   { false }
        let(:verify_package?)                 { nil }

        ### Args
        let(:upgrade_args) do
          [
            release_name,
            helm_chart,
            helm_flags_to_args(chart_args_map),
            helm_flags_to_args(upgrade_args_map),
            context_args,
            values_args,
            helm_set_values_to_args(override_values)
          ].flatten.compact
        end

        let(:template_args) do
          [
            release_name,
            helm_chart,
            helm_flags_to_args(chart_args_map),
            helm_flags_to_args(template_args_map),
            context_args,
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
        let(:context_args)           { helm_flags_to_args(context_args_map) }
        let(:formatted_context_args) { context_args.join(" \\\n  ") }

        let(:template_args_map) do
          {
            "--dry-run"           => dry_run?,
            "--dependency-update" => dependency_update?,
            "--create-namespace"  => create_namespace_if_not_exists?,
            "--atomic"            => atomic_upgrade?,
            "--wait"              => wait_for_readiness?,
            "--wait-for-jobs"     => wait_for_jobs?,
            "--cleanup-on-fail"   => cleanup_on_fail?,
            "--skip-crds"         => skip_crds?,
            "--verify"            => verify_package?
          }
        end

        let(:upgrade_args_map) do
          {
            "--dry-run"           => dry_run?,
            "--install"           => install_if_not_exists?,
            "--dependency-update" => dependency_update?,
            "--create-namespace"  => create_namespace_if_not_exists?,
            "--atomic"            => atomic_upgrade?,
            "--wait"              => wait_for_readiness?,
            "--wait-for-jobs"     => wait_for_jobs?,
            "--cleanup-on-fail"   => cleanup_on_fail?,
            "--force"             => force_replace?,
            "--skip-crds"         => skip_crds?,
            "--reset-values"      => reset_values?,
            "--resue-values"      => reuse_values?,
            "--verify"            => verify_package?
          }
        end

        let(:values_args)             { normalized_values_paths.map { |p| "-f #{p}" } }
        let(:normalized_values_paths) { value_files.map(&method(:normalize_value_path)) }
        let(:values_search_path) do
          [
            File.join(::Matsuri::Config.helm.releases_path, release_name),
            ::Matsuri::Config.helm.releases_path, release_name
          ]
        end

        def normalize_value_path(candidate_path)
          raise_if_not_found = proc do
            fail "Unable to find #{candidate_path} in search paths:\n  #{values_search_path.join("\n  ")}"
          end

          values_search_path.
            map { |p| File.join(p, candidate_path) }.
            find(raise_if_not_found) { |f| File.exists?(f) }
        end

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

        def helm_template_cmd(args)
          final_args = args.join(" \\\n  ")
          "helm template \\\n  #{final_args}"
        end

        def helm_template(args, options = {})
          shell_out(helm_template_cmd(args), options)
        end

        def helm_template!(args, options = {})
          helm_add_repo!
          helm_update!
          shell_out!(helm_upgrade_cmd(args), options)
        end

        def helm_upgrade_cmd(args)
          final_args = args.join(" \\\n  ")
          "helm upgrade \\\n  #{final_args}"
        end

        def helm_upgrade(args, options = {})
          shell_out(helm_upgrade_cmd(args), options)
        end

        def helm_upgrade!(args, options = {})
          helm_add_repo!
          helm_update!
          shell_out!(helm_upgrade_cmd(args), options)
        end

        def show!
          puts "Generate manifests for helm release #{name}".color(:yellow).bright if config.verbose
          helm_template!(template_args)
        end

        def apply!
          puts "Applying (create or update) helm release #{name}".color(:yellow).bright if config.verbose
          helm_upgrade!(upgrade_args)
        end

        def helm_add_repo!()
          shell_out!("helm repo add #{helm_repo_name} #{helm_repo_url} \\\n  #{formatted_context_args}")
        end

        def helm_update!()
          shell_out!("helm repo update \\\n  #{formatted_context_args}")
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
