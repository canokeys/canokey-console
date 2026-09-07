pub mod api;
mod frb_generated;

// Retain fido2's upstream C ABI in the existing native library/framework.
#[cfg(not(target_arch = "wasm32"))]
#[used]
static FIDO2_ALLOC: extern "C" fn(usize) -> *mut u8 = fido2_crypto::fido2_alloc;
#[cfg(not(target_arch = "wasm32"))]
#[used]
static FIDO2_FREE: unsafe extern "C" fn(*mut u8, usize) = fido2_crypto::fido2_free;
#[cfg(not(target_arch = "wasm32"))]
#[used]
static FIDO2_CALL: unsafe extern "C" fn(*const u8, usize, *mut u8, usize) -> i32 =
    fido2_crypto::fido2_call;
