use clap::Parser;
use cosmic_config::{ConfigGet, ConfigSet};
use cosmic_theme::ThemeMode;

/// Simple program to greet a person
#[derive(Parser, Debug)]
#[command(author, version, about, long_about = None)]
struct Args {
    /// enable dark mode
    #[arg(short, long, default_value = "false")]
    dark: bool,
}

fn main() {
    let args = Args::parse();
    if let Some(config) = ThemeMode::config().ok() {
        if let Ok(autoswitch) = config.get::<bool>("auto_switch") {
            if autoswitch {
                let _ = config.set::<bool>("is_dark", args.dark);
            }
        }
    }
}
