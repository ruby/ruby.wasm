##
# A set of feature flags that can be used to enable or disable experimental features.
class RubyWasm::FeatureSet
  def initialize(features)
    @features = features
  end

  # Maps the feature to the environment variable.
  FEATURES = {
    dynamic_linking: "RUBY_WASM_EXPERIMENTAL_DYNAMIC_LINKING",
    component_model: "RUBY_WASM_EXPERIMENTAL_COMPONENT_MODEL",
  }.freeze
  private_constant :FEATURES

  # Derives the feature set from the environment variables. A feature
  # is enabled if the corresponding environment variable is set to "1",
  # otherwise it is disabled.
  def self.derive_from_env
    values = FEATURES.transform_values { |key| ENV[key] == "1" }
    new(values)
  end

  def support_dynamic_linking?
    @features[:dynamic_linking]
  end

  def support_component_model?
    @features[:component_model] || @features[:dynamic_linking]
  end
end
