use des::cipher::{BlockEncrypt, KeyInit};

pub fn tdes_ede3_enc(key: Vec<u8>, data: Vec<u8>) -> Vec<u8> {
    assert_eq!(key.len(), 24, "des-ede3 key length must be 24 bytes");
    let mut enc_data = vec![0u8; data.len()];
    let tdes = des::TdesEde3::new(key.as_slice().into());
    tdes.encrypt_block_b2b(data.as_slice().into(), enc_data.as_mut_slice().into());
    enc_data
}
