use des::cipher::{BlockEncrypt, KeyInit};
use pbkdf2::hmac::{Hmac, Mac};
use pbkdf2::pbkdf2_hmac;
use sha1::Sha1;
use x509_parser::pem::parse_x509_pem;
use x509_parser::prelude::X509Certificate;

pub struct X509CertData {
    pub bytes: Vec<u8>,
    pub subject: String,
    pub issuer: String,
    pub not_before: String,
    pub not_after: String,
    pub serial_number: String,
    pub signature_algorithm: String,
    pub signature_value: Vec<u8>,
    pub public_key_algorithm: String,
    pub public_key_size: usize,
}

pub fn tdes_ede3_enc(key: Vec<u8>, data: Vec<u8>) -> Vec<u8> {
    assert_eq!(key.len(), 24, "des-ede3 key length must be 24 bytes");
    let mut enc_data = vec![0u8; data.len()];
    let tdes = des::TdesEde3::new(key.as_slice().into());
    tdes.encrypt_block_b2b(data.as_slice().into(), enc_data.as_mut_slice().into());
    enc_data
}

fn gen_x590_meta(cert: X509Certificate<'_>) -> X509CertData {
    let pk = cert
        .tbs_certificate
        .subject_pki
        .parsed()
        .expect("cannot parse public key from X.509");
    X509CertData {
        bytes: cert.as_ref().to_vec(),
        subject: cert.subject().to_string(),
        issuer: cert.issuer().to_string(),
        not_before: cert.validity().not_before.to_string(),
        not_after: cert.validity().not_after.to_string(),
        serial_number: format!("{:X}", cert.tbs_certificate.serial),
        signature_algorithm: cert.tbs_certificate.signature.algorithm.to_string(),
        signature_value: cert.signature_value.data.to_vec(),
        public_key_algorithm: cert
            .tbs_certificate
            .subject_pki
            .algorithm
            .oid()
            .to_id_string(),
        public_key_size: pk.key_size(),
    }
}

pub fn parse_x509_cert_from_pem(pem: String) -> X509CertData {
    let pem = parse_x509_pem(pem.as_bytes())
        .expect("Parsing PEM failed")
        .1;
    let cert = pem.parse_x509().expect("X.509: decoding DER failed");
    gen_x590_meta(cert)
}

pub fn parse_x509_cert_from_der(der: Vec<u8>) -> X509CertData {
    let cert = x509_parser::parse_x509_certificate(der.as_slice())
        .expect("X.509: decoding DER failed")
        .1;
    gen_x590_meta(cert)
}

pub fn pbkdf2_hmac_sha1(password: String, salt: Vec<u8>, iterations: u32, key_len: u32) -> Vec<u8> {
    let mut key = vec![0u8; key_len as usize];
    pbkdf2_hmac::<Sha1>(
        password.as_bytes(),
        salt.as_slice(),
        iterations,
        key.as_mut_slice(),
    );
    key
}

pub fn hmac_sha1(key: Vec<u8>, data: Vec<u8>) -> Vec<u8> {
    type HmacSha1 = Hmac<Sha1>;
    let mut mac =
        <HmacSha1 as Mac>::new_from_slice(key.as_slice()).expect("HMAC can take key of any size");
    mac.update(data.as_slice());
    mac.finalize().into_bytes().to_vec()
}
