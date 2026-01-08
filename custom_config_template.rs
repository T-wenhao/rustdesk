//! Custom Server Configuration Template
//!
//! This file provides a template for custom server configuration.
//! It will be processed during build time to inject CI/CD values.

use hbb_common::config::Config;

/// Configuration values that can be injected at build time
pub struct BuildConfig {
    pub key: &'static str,
    pub api_server: &'static str,
    pub relay_server: &'static str,
    pub custom_rendezvous_server: &'static str,
}

/// Default configuration (used when no CI injection is provided)
const DEFAULT_CONFIG: BuildConfig = BuildConfig {
    key: "",
    api_server: "",
    relay_server: "",
    custom_rendezvous_server: "",
};

/// Apply the build-time configuration
pub fn apply_build_config() {
    let config = get_build_config();

    if !config.key.is_empty() {
        Config::set_option("key".to_string(), config.key.to_string());
    }
    if !config.api_server.is_empty() {
        Config::set_option("api-server".to_string(), config.api_server.to_string());
    }
    if !config.relay_server.is_empty() {
        Config::set_option("relay-server".to_string(), config.relay_server.to_string());
    }
    if !config.custom_rendezvous_server.is_empty() {
        Config::set_option("custom-rendezvous-server".to_string(), config.custom_rendezvous_server.to_string());
    }
}

/// Get the build configuration
/// This function will be overridden by build-time injection
fn get_build_config() -> &'static BuildConfig {
    &DEFAULT_CONFIG
}

/// Helper function to check if custom configuration is available
pub fn has_custom_config() -> bool {
    let config = get_build_config();
    !config.key.is_empty() && !config.custom_rendezvous_server.is_empty()
}

/// Get current effective configuration
pub fn get_effective_config() -> (String, String, String, String) {
    let build_config = get_build_config();

    // Use build config if available, otherwise fall back to runtime config
    let key = if !build_config.key.is_empty() {
        build_config.key.to_string()
    } else {
        Config::get_option("key")
    };

    let api_server = if !build_config.api_server.is_empty() {
        build_config.api_server.to_string()
    } else {
        Config::get_option("api-server")
    };

    let relay_server = if !build_config.relay_server.is_empty() {
        build_config.relay_server.to_string()
    } else {
        Config::get_option("relay-server")
    };

    let custom_rendezvous_server = if !build_config.custom_rendezvous_server.is_empty() {
        build_config.custom_rendezvous_server.to_string()
    } else {
        Config::get_option("custom-rendezvous-server")
    };

    (key, api_server, relay_server, custom_rendezvous_server)
}