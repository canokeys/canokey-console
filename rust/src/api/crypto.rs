use aes::cipher::{Block as AesBlock, BlockCipherEncrypt, KeyInit as AesKeyInit};
use aes::Aes192;
use der::asn1::UintRef;
use der::{Decode, Sequence};
use des::cipher::Block;
use ed25519_dalek::{Signature as Ed25519Signature, VerifyingKey as Ed25519VerifyingKey};
use hex_literal::hex;
use p256::ecdsa::signature::Verifier as EcdsaVerifier;
use pbkdf2::hmac::{Hmac, KeyInit as HmacKeyInit, Mac};
use pbkdf2::pbkdf2_hmac;
use rsa::pkcs1v15::{Signature as RsaSignature, VerifyingKey as RsaVerifyingKey};
use rsa::pkcs8::DecodePublicKey;
use rsa::signature::Verifier as LegacyVerifier;
use rsa::RsaPublicKey;
use sha1::Sha1;
use sha2::{Digest, Sha256, Sha384, Sha512};
use sha2_legacy::Sha256 as RsaSha256;
use sm2::dsa::{Signature as Sm2Signature, VerifyingKey as Sm2VerifyingKey};
use sm3::Sm3;
use x509_parser::pem::parse_x509_pem;
use x509_parser::prelude::X509Certificate;

const PIV_TDES: u8 = 0x03;
const PIV_AES192: u8 = 0x0A;
const PIV_RSA1024: u8 = 0x06;
const PIV_RSA2048: u8 = 0x07;
const PIV_RSA3072: u8 = 0x05;
const PIV_RSA4096: u8 = 0x16;
const PIV_ECC_P256: u8 = 0x11;
const PIV_ECC_P384: u8 = 0x14;
const PIV_ECC_P521: u8 = 0x15;
const PIV_SECP256K1: u8 = 0x53;
const PIV_SM2: u8 = 0x54;
const PIV_ED25519: u8 = 0xE0;
const SM2_DISTINGUISHING_ID: &str = "1234567812345678";

#[derive(Sequence)]
struct DerSignature<'a> {
    r: UintRef<'a>,
    s: UintRef<'a>,
}

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
    assert_eq!(data.len(), 8, "des-ede3 encrypts exactly one 8-byte block");
    let mut enc_data = vec![0u8; data.len()];
    let tdes = des::TdesEde3::new_from_slice(key.as_slice()).unwrap();
    let input = <&Block<des::TdesEde3>>::try_from(data.as_slice()).unwrap();
    let output = <&mut Block<des::TdesEde3>>::try_from(enc_data.as_mut_slice()).unwrap();
    tdes.encrypt_block_b2b(input, output);
    enc_data
}

pub fn encrypt_piv_management_key_challenge(
    algorithm: u8,
    key: Vec<u8>,
    challenge: Vec<u8>,
) -> Result<Vec<u8>, String> {
    if key.len() != 24 {
        return Err("management key must be 24 bytes".into());
    }

    match algorithm {
        PIV_TDES if challenge.len() == 8 => Ok(tdes_ede3_enc(key, challenge)),
        PIV_AES192 if challenge.len() == 16 => {
            let cipher = Aes192::new_from_slice(&key).map_err(|_| "invalid AES-192 key")?;
            let input = AesBlock::<Aes192>::from(
                <[u8; 16]>::try_from(challenge.as_slice()).expect("validated challenge length"),
            );
            let mut encrypted = AesBlock::<Aes192>::default();
            cipher.encrypt_block_b2b(&input, &mut encrypted);
            Ok(encrypted.to_vec())
        }
        PIV_TDES => Err("3DES challenge must be 8 bytes".into()),
        PIV_AES192 => Err("AES-192 challenge must be 16 bytes".into()),
        _ => Err("unsupported PIV management key algorithm".into()),
    }
}

pub fn sha256_digest(data: Vec<u8>) -> Vec<u8> {
    Sha256::digest(data).to_vec()
}

pub fn sha384_digest(data: Vec<u8>) -> Vec<u8> {
    Sha384::digest(data).to_vec()
}

pub fn sha512_digest(data: Vec<u8>) -> Vec<u8> {
    Sha512::digest(data).to_vec()
}

pub fn sm2_message_digest(data: Vec<u8>, public_key: Vec<u8>) -> Result<Vec<u8>, String> {
    if public_key.len() != 65 || public_key[0] != 0x04 {
        return Err("SM2 public key must be an uncompressed 65-byte point".into());
    }
    Sm2VerifyingKey::from_sec1_bytes(SM2_DISTINGUISHING_ID, &public_key)
        .map_err(|_| "invalid SM2 public key")?;

    const A: [u8; 32] = hex!("FFFFFFFEFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00000000FFFFFFFFFFFFFFFC");
    const B: [u8; 32] = hex!("28E9FA9E9D9F5E344D5A9E4BCF6509A7F39789F515AB8F92DDBCBD414D940E93");
    const GX: [u8; 32] = hex!("32C4AE2C1F1981195F9904466A39C9948FE30BBFF2660BE1715A4589334C74C7");
    const GY: [u8; 32] = hex!("BC3736A2F4F6779C59BDCEE36B692153D0A9877CC62A474002DF32E52139F0A0");

    let identity_bits = (SM2_DISTINGUISHING_ID.len() * 8) as u16;
    let mut identity = Sm3::new();
    identity.update(identity_bits.to_be_bytes());
    identity.update(SM2_DISTINGUISHING_ID.as_bytes());
    identity.update(A);
    identity.update(B);
    identity.update(GX);
    identity.update(GY);
    identity.update(&public_key[1..33]);
    identity.update(&public_key[33..65]);

    let mut message = Sm3::new();
    message.update(identity.finalize());
    message.update(data);
    Ok(message.finalize().to_vec())
}

pub fn verify_piv_signature(
    algorithm: u8,
    public_key: Vec<u8>,
    data: Vec<u8>,
    signature: Vec<u8>,
) -> bool {
    match algorithm {
        PIV_RSA1024 | PIV_RSA2048 | PIV_RSA3072 | PIV_RSA4096 => {
            verify_rsa_signature(&public_key, &data, &signature)
        }
        PIV_ECC_P256 => verify_p256_signature(&public_key, &data, &signature),
        PIV_ECC_P384 => verify_p384_signature(&public_key, &data, &signature),
        PIV_ECC_P521 => verify_p521_signature(&public_key, &data, &signature),
        PIV_SECP256K1 => verify_k256_signature(&public_key, &data, &signature),
        PIV_SM2 => verify_sm2_signature(&public_key, &data, &signature),
        PIV_ED25519 => verify_ed25519_signature(&public_key, &data, &signature),
        _ => false,
    }
}

fn verify_rsa_signature(public_key: &[u8], data: &[u8], signature: &[u8]) -> bool {
    let Ok(public_key) = RsaPublicKey::from_public_key_der(public_key) else {
        return false;
    };
    let Ok(signature) = RsaSignature::try_from(signature) else {
        return false;
    };
    RsaVerifyingKey::<RsaSha256>::new(public_key)
        .verify(data, &signature)
        .is_ok()
}

fn verify_p256_signature(public_key: &[u8], data: &[u8], signature: &[u8]) -> bool {
    let Ok(public_key) = p256::ecdsa::VerifyingKey::from_sec1_bytes(public_key) else {
        return false;
    };
    let signature = p256::ecdsa::Signature::from_der(signature)
        .or_else(|_| p256::ecdsa::Signature::from_slice(signature));
    signature.is_ok_and(|signature| public_key.verify(data, &signature).is_ok())
}

fn verify_p384_signature(public_key: &[u8], data: &[u8], signature: &[u8]) -> bool {
    let Ok(public_key) = p384::ecdsa::VerifyingKey::from_sec1_bytes(public_key) else {
        return false;
    };
    let signature = p384::ecdsa::Signature::from_der(signature)
        .or_else(|_| p384::ecdsa::Signature::from_slice(signature));
    signature.is_ok_and(|signature| public_key.verify(data, &signature).is_ok())
}

fn verify_p521_signature(public_key: &[u8], data: &[u8], signature: &[u8]) -> bool {
    let Ok(public_key) = p521::ecdsa::VerifyingKey::from_sec1_bytes(public_key) else {
        return false;
    };
    let signature = p521::ecdsa::Signature::from_der(signature)
        .or_else(|_| p521::ecdsa::Signature::from_slice(signature));
    signature.is_ok_and(|signature| public_key.verify(data, &signature).is_ok())
}

fn verify_k256_signature(public_key: &[u8], data: &[u8], signature: &[u8]) -> bool {
    let Ok(public_key) = k256::ecdsa::VerifyingKey::from_sec1_bytes(public_key) else {
        return false;
    };
    let signature = k256::ecdsa::Signature::from_der(signature)
        .or_else(|_| k256::ecdsa::Signature::from_slice(signature));
    signature.is_ok_and(|signature| public_key.verify(data, &signature).is_ok())
}

fn verify_sm2_signature(public_key: &[u8], data: &[u8], signature: &[u8]) -> bool {
    let Ok(public_key) = Sm2VerifyingKey::from_sec1_bytes(SM2_DISTINGUISHING_ID, public_key) else {
        return false;
    };
    let Some(signature) = fixed_width_signature(signature, 32) else {
        return false;
    };
    let Ok(signature) = Sm2Signature::from_slice(&signature) else {
        return false;
    };
    public_key.verify(data, &signature).is_ok()
}

fn verify_ed25519_signature(public_key: &[u8], data: &[u8], signature: &[u8]) -> bool {
    let Ok(public_key) = <&[u8; 32]>::try_from(public_key) else {
        return false;
    };
    let Ok(public_key) = Ed25519VerifyingKey::from_bytes(public_key) else {
        return false;
    };
    let Ok(signature) = Ed25519Signature::from_slice(signature) else {
        return false;
    };
    public_key.verify_strict(data, &signature).is_ok()
}

fn fixed_width_signature(signature: &[u8], scalar_size: usize) -> Option<Vec<u8>> {
    if signature.len() == scalar_size * 2 {
        return Some(signature.to_vec());
    }

    let signature = DerSignature::from_der(signature).ok()?;
    let mut output = vec![0u8; scalar_size * 2];
    copy_unsigned_integer(signature.r.as_bytes(), &mut output[..scalar_size])?;
    copy_unsigned_integer(signature.s.as_bytes(), &mut output[scalar_size..])?;
    Some(output)
}

fn copy_unsigned_integer(integer: &[u8], output: &mut [u8]) -> Option<()> {
    let integer = integer.strip_prefix(&[0]).unwrap_or(integer);
    if integer.len() > output.len() {
        return None;
    }
    let offset = output.len() - integer.len();
    output[offset..].copy_from_slice(integer);
    Some(())
}

fn x509_public_key_size(parsed_key_size: usize, encoded_key_length: usize) -> usize {
    if parsed_key_size == 0 {
        encoded_key_length * 8
    } else {
        parsed_key_size
    }
}

fn gen_x590_meta(cert: X509Certificate<'_>) -> X509CertData {
    let subject_pki = &cert.tbs_certificate.subject_pki;
    let public_key_algorithm = cert
        .tbs_certificate
        .subject_pki
        .algorithm
        .oid()
        .to_id_string();
    let parsed_key_size = subject_pki.parsed().map_or(0, |key| key.key_size());
    let public_key_size =
        x509_public_key_size(parsed_key_size, subject_pki.subject_public_key.data.len());
    X509CertData {
        bytes: cert.as_ref().to_vec(),
        subject: cert.subject().to_string(),
        issuer: cert.issuer().to_string(),
        not_before: cert.validity().not_before.to_string(),
        not_after: cert.validity().not_after.to_string(),
        serial_number: format!("{:X}", cert.tbs_certificate.serial),
        signature_algorithm: cert.tbs_certificate.signature.algorithm.to_string(),
        signature_value: cert.signature_value.data.to_vec(),
        public_key_algorithm,
        public_key_size,
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
    let mut mac = <HmacSha1 as HmacKeyInit>::new_from_slice(key.as_slice()).unwrap();
    mac.update(data.as_slice());
    mac.finalize().into_bytes().to_vec()
}

#[cfg(test)]
mod tests {
    use super::*;
    use p256::ecdsa::signature::{
        RandomizedSigner as EcdsaRandomizedSigner, Signer as EcdsaSigner,
    };
    use rand::{rngs::StdRng, SeedableRng};
    use rsa::pkcs1v15::SigningKey as RsaSigningKey;
    use rsa::pkcs8::EncodePublicKey;
    use rsa::signature::{SignatureEncoding, Signer as RsaSigner};

    const MESSAGE: &[u8] = b"CanoKey PIV signature test";

    #[test]
    fn hashes_match_known_vectors() {
        assert_eq!(
            sha256_digest(b"abc".to_vec()),
            hex!("BA7816BF8F01CFEA414140DE5DAE2223B00361A396177A9CB410FF61F20015AD")
        );
        assert_eq!(
            sha384_digest(b"abc".to_vec()),
            hex!("CB00753F45A35E8BB5A03D699AC65007272C32AB0EDED1631A8B605A43FF5BED8086072BA1E7CC2358BAECA134C825A7")
        );
        assert_eq!(
            sha512_digest(b"abc".to_vec()),
            hex!("DDAF35A193617ABACC417349AE20413112E6FA4E89A97EA20A9EEEE64B55D39A2192992A274FC1A836BA3C23A3FEEBBD454D4423643CE80E2A9AC94FA54CA49F")
        );
    }

    #[test]
    fn encrypts_management_key_known_vectors() {
        assert_eq!(
            encrypt_piv_management_key_challenge(
                PIV_AES192,
                hex!("000102030405060708090A0B0C0D0E0F1011121314151617").to_vec(),
                hex!("00112233445566778899AABBCCDDEEFF").to_vec(),
            )
            .unwrap(),
            hex!("DDA97CA4864CDFE06EAF70A0EC0D7191")
        );
        assert_eq!(
            encrypt_piv_management_key_challenge(
                PIV_TDES,
                hex!("0123456789ABCDEF23456789ABCDEF01456789ABCDEF0123").to_vec(),
                hex!("0000000000000000").to_vec(),
            )
            .unwrap(),
            hex!("4EBA739C998BCB60")
        );
    }

    #[test]
    fn sm2_digest_matches_known_vector() {
        let public_key = hex!(
            "0432C4AE2C1F1981195F9904466A39C9948FE30BBFF2660BE1715A4589334C74C7BC3736A2F4F6779C59BDCEE36B692153D0A9877CC62A474002DF32E52139F0A0"
        );
        assert_eq!(
            sm2_message_digest(b"abc".to_vec(), public_key.to_vec()).unwrap(),
            hex!("E2631E76CF38546AA6CF0FBA91A4894FEC7FF65C7CDB9DA0246417FCB1867B95")
        );
    }

    #[test]
    fn verifies_rsa_signature() {
        let private_key = rsa::RsaPrivateKey::new(&mut rsa::rand_core::OsRng, 1024).unwrap();
        let public_key = private_key
            .to_public_key()
            .to_public_key_der()
            .unwrap()
            .as_bytes()
            .to_vec();
        let signature = RsaSigningKey::<RsaSha256>::new(private_key)
            .sign(MESSAGE)
            .to_vec();
        assert!(verify_piv_signature(
            PIV_RSA1024,
            public_key,
            MESSAGE.to_vec(),
            signature,
        ));
    }

    #[test]
    fn verifies_nist_and_secp256k1_signatures() {
        let p256_key = p256::ecdsa::SigningKey::from_slice(&[1; 32]).unwrap();
        let p256_signature: p256::ecdsa::Signature = p256_key.sign(MESSAGE);
        assert!(verify_piv_signature(
            PIV_ECC_P256,
            p256_key
                .verifying_key()
                .to_sec1_point(false)
                .as_bytes()
                .to_vec(),
            MESSAGE.to_vec(),
            p256_signature.to_der().as_bytes().to_vec(),
        ));

        let p384_key = p384::ecdsa::SigningKey::from_slice(&[2; 48]).unwrap();
        let p384_signature: p384::ecdsa::Signature = p384_key.sign(MESSAGE);
        assert!(verify_piv_signature(
            PIV_ECC_P384,
            p384_key
                .verifying_key()
                .to_sec1_point(false)
                .as_bytes()
                .to_vec(),
            MESSAGE.to_vec(),
            p384_signature.to_der().as_bytes().to_vec(),
        ));

        let mut p521_secret = [0u8; 66];
        p521_secret[65] = 3;
        let p521_key = p521::ecdsa::SigningKey::from_slice(&p521_secret).unwrap();
        let mut rng = StdRng::seed_from_u64(2);
        let p521_signature: p521::ecdsa::Signature = p521_key.sign_with_rng(&mut rng, MESSAGE);
        let p521_public_key = p521::ecdsa::VerifyingKey::from(&p521_key);
        assert!(verify_piv_signature(
            PIV_ECC_P521,
            p521_public_key.to_sec1_point(false).as_bytes().to_vec(),
            MESSAGE.to_vec(),
            p521_signature.to_der().as_bytes().to_vec(),
        ));

        let k256_key = k256::ecdsa::SigningKey::from_slice(&[4; 32]).unwrap();
        let k256_signature: k256::ecdsa::Signature = k256_key.sign(MESSAGE);
        assert!(verify_piv_signature(
            PIV_SECP256K1,
            k256_key
                .verifying_key()
                .to_sec1_point(false)
                .as_bytes()
                .to_vec(),
            MESSAGE.to_vec(),
            k256_signature.to_der().as_bytes().to_vec(),
        ));
    }

    #[test]
    fn verifies_sm2_and_ed25519_signatures() {
        let sm2_secret = sm2::SecretKey::from_slice(&[5; 32]).unwrap();
        let sm2_key = sm2::dsa::SigningKey::new(SM2_DISTINGUISHING_ID, &sm2_secret).unwrap();
        let sm2_signature: Sm2Signature = sm2_key.sign(MESSAGE);
        assert!(verify_piv_signature(
            PIV_SM2,
            sm2_key.verifying_key().to_sec1_bytes().to_vec(),
            MESSAGE.to_vec(),
            sm2_signature.to_vec(),
        ));

        let ed25519_key = ed25519_dalek::SigningKey::from_bytes(&[6; 32]);
        let ed25519_signature = ed25519_key.sign(MESSAGE);
        assert!(verify_piv_signature(
            PIV_ED25519,
            ed25519_key.verifying_key().to_bytes().to_vec(),
            MESSAGE.to_vec(),
            ed25519_signature.to_bytes().to_vec(),
        ));
    }

    #[test]
    fn rejects_modified_message() {
        let key = ed25519_dalek::SigningKey::from_bytes(&[7; 32]);
        let signature = key.sign(MESSAGE);
        assert!(!verify_piv_signature(
            PIV_ED25519,
            key.verifying_key().to_bytes().to_vec(),
            b"modified".to_vec(),
            signature.to_bytes().to_vec(),
        ));
    }

    #[test]
    fn reports_unknown_public_key_size_from_spki_bits() {
        let key = x509_parser::public_key::PublicKey::Unknown(&[0; 1952]);

        assert_eq!(key.key_size(), 0);
        assert_eq!(x509_public_key_size(key.key_size(), 1952), 15616);
        assert_eq!(x509_public_key_size(256, 65), 256);
    }
}
