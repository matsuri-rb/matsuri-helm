
require 'matsuri'

module Matsuri
  module Helm
    module K8S
      autoload :Release, 'matsuri/helm/k8s/release'
    end
  end
end

# Register paths
Matsuri::Config.config_context(:helm) do
  default(:helm_base_path)   { File.join Matsuri::Config.platform_path, 'helm' }
  default(:releases_path)    { File.join helm_base_path, 'releases' }
  default(:helm_config_path) { File.join Matsuri::Config.config_path, 'helm' }
  default(:repo_config_path) { File.join helm_config_path, 'repositories.yaml' }
end

# Add CRD support to tooling
require 'matsuri/helm/cmd'

Matsuri::Registry.register_class 'helm_release', class: Matsuri::Helm::K8S::Release
