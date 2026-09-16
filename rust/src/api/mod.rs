pub mod crypto;
pub mod decode;
pub mod piv_crypto;
pub mod protocol;

#[flutter_rust_bridge::frb(init)]
pub fn init_app() {
    flutter_rust_bridge::setup_default_user_utils();
}
