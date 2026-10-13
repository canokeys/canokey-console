use der::asn1::UintRef;
use der::{Decode, Sequence};
use ed25519_dalek::{Signature as Ed25519Signature, VerifyingKey as Ed25519VerifyingKey};
use hex_literal::hex;
use p256::ecdsa::signature::Verifier as EcdsaVerifier;
use pbkdf2::pbkdf2_hmac;
use rsa::pkcs1v15::{Signature as RsaSignature, VerifyingKey as RsaVerifyingKey};
use rsa::pkcs8::DecodePublicKey;
use rsa::signature::Verifier as LegacyVerifier;
use rsa::RsaPublicKey;
use sha1::Sha1;
use sha2::{Digest, Sha256};
use sha2_legacy::Sha256 as RsaSha256;
use sm2::dsa::{Signature as Sm2Signature, VerifyingKey as Sm2VerifyingKey};
use sm3::Sm3;
use x509_info::CertificateInfo;

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
    pub public_key_algorithm_name: String,
    pub signature_algorithm_name: String,
    pub subject_public_key_info: Vec<u8>,
    pub raw_public_key: Vec<u8>,
}

pub fn sha256_digest(data: Vec<u8>) -> Vec<u8> {
    Sha256::digest(data).to_vec()
}

pub(crate) fn sm2_message_digest(data: Vec<u8>, public_key: Vec<u8>) -> Result<Vec<u8>, String> {
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

fn certificate_data(cert: CertificateInfo) -> X509CertData {
    let date = |seconds| {
        time::OffsetDateTime::from_unix_timestamp(seconds)
            .expect("parsed certificate timestamp")
            .format(time::macros::format_description!("[month repr:short] [day padding:space] [hour]:[minute]:[second] [year padding:none] [offset_hour sign:mandatory]:[offset_minute]"))
            .expect("valid date format")
    };
    X509CertData {
        bytes: cert.der,
        subject: cert.subject.display,
        issuer: cert.issuer.display,
        not_before: date(cert.validity.not_before_unix),
        not_after: date(cert.validity.not_after_unix),
        serial_number: cert
            .serial_number
            .iter()
            .map(|byte| format!("{byte:02X}"))
            .collect(),
        signature_algorithm_name: cert
            .signature_algorithm
            .name
            .unwrap_or_else(|| cert.signature_algorithm.oid.clone()),
        signature_algorithm: cert.signature_algorithm.oid,
        signature_value: cert.signature_value,
        public_key_algorithm_name: cert
            .public_key
            .algorithm
            .name
            .unwrap_or_else(|| cert.public_key.algorithm.oid.clone()),
        public_key_algorithm: cert.public_key.algorithm.oid,
        public_key_size: cert.public_key.key_size_bits.unwrap_or(0),
        subject_public_key_info: cert.public_key.spki_der,
        raw_public_key: cert.public_key.key_bytes,
    }
}

pub(crate) fn parse_x509_cert_from_pem(pem: String) -> Result<X509CertData, String> {
    x509_info::parse_pem(pem.as_bytes(), Default::default())
        .map(certificate_data)
        .map_err(|error| error.to_string())
}

pub fn parse_x509_cert_from_der(der: Vec<u8>) -> Result<X509CertData, String> {
    x509_info::parse_der(&der, Default::default())
        .map(certificate_data)
        .map_err(|error| error.to_string())
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
    fn parses_reported_piv_certificate_and_rejects_object_metadata() {
        let der = include_bytes!("../../../test/fixtures/piv/certificate.der").to_vec();
        let certificate = parse_x509_cert_from_der(der.clone()).unwrap();
        assert!(certificate
            .subject
            .contains("CanoKey F5 full enrollment RSA"));
        let mut with_metadata = der;
        with_metadata.extend_from_slice(&[0x71, 0x01, 0x00, 0xfe, 0x00]);
        assert_eq!(
            parse_x509_cert_from_der(with_metadata).err().unwrap(),
            "trailing data after certificate"
        );
    }

    #[test]
    fn certificate_inspection_uses_library_names_and_strict_single_pem() {
        use der::EncodePem;
        let original = include_bytes!("../../../test/fixtures/piv/certificate.der");
        let cert = x509_cert::Certificate::from_der(original).unwrap();
        let data = parse_x509_cert_from_der(original.to_vec()).unwrap();
        assert_eq!(data.public_key_algorithm_name, "RSA");
        assert_eq!(data.public_key_size, 2048);
        assert_eq!(data.signature_algorithm_name, "RSA-SHA256");
        assert_eq!(data.bytes, original);
        let pem = cert.to_pem(der::pem::LineEnding::LF).unwrap();
        assert_eq!(
            parse_x509_cert_from_pem(pem.clone()).unwrap().subject,
            data.subject
        );
        assert!(parse_x509_cert_from_pem(format!("{pem}{pem}")).is_err());
        assert!(parse_x509_cert_from_pem(pem.replace("CERTIFICATE", "PUBLIC KEY")).is_err());

        // Encoded key size is not a curve size or security-strength estimate.
        let mut unknown = original.to_vec();
        let rsa_oid = hex!("06092A864886F70D010101");
        let offset = unknown
            .windows(rsa_oid.len())
            .position(|bytes| bytes == rsa_oid)
            .unwrap();
        unknown[offset + rsa_oid.len() - 1] = 99;
        let unknown = parse_x509_cert_from_der(unknown).unwrap();
        assert_eq!(unknown.public_key_algorithm_name, "1.2.840.113549.1.1.99");
        assert_eq!(unknown.public_key_size, 0);
        assert_eq!(unknown.raw_public_key, data.raw_public_key);
    }

    #[test]
    fn hashes_match_known_vectors() {
        assert_eq!(
            sha256_digest(b"abc".to_vec()),
            hex!("BA7816BF8F01CFEA414140DE5DAE2223B00361A396177A9CB410FF61F20015AD")
        );
        assert_eq!(
            sha2::Sha384::digest(b"abc").as_slice(),
            hex!("CB00753F45A35E8BB5A03D699AC65007272C32AB0EDED1631A8B605A43FF5BED8086072BA1E7CC2358BAECA134C825A7")
        );
        assert_eq!(
            sha2::Sha512::digest(b"abc").as_slice(),
            hex!("DDAF35A193617ABACC417349AE20413112E6FA4E89A97EA20A9EEEE64B55D39A2192992A274FC1A836BA3C23A3FEEBBD454D4423643CE80E2A9AC94FA54CA49F")
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
}
