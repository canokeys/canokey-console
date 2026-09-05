use std::str::FromStr;

use const_oid::ObjectIdentifier;
use der::asn1::{Any, BitString, Ia5String, Uint};
use der::{Decode, Encode, EncodePem, Sequence, Tagged};
use ed25519_dalek::pkcs8::DecodePrivateKey as Ed25519DecodePrivateKey;
use ed25519_dalek::SigningKey as Ed25519SigningKey;
use p256::elliptic_curve::sec1::ToSec1Point;
use rsa::pkcs1::DecodeRsaPrivateKey;
use rsa::pkcs8::{DecodePrivateKey as RsaDecodePrivateKey, DecodePublicKey, EncodePublicKey};
use rsa::traits::{PrivateKeyParts, PublicKeyParts};
use rsa::RsaPrivateKey;
use sha2::{Digest, Sha256, Sha384, Sha512};
use sm2::elliptic_curve::sec1::ToEncodedPoint as Sm2ToEncodedPoint;
use x509_cert::attr::Attributes;
use x509_cert::certificate::Version as CertificateVersion;
use x509_cert::ext::pkix::name::GeneralName;
use x509_cert::ext::pkix::SubjectAltName;
use x509_cert::ext::{Extension, ToExtension};
use x509_cert::name::Name;
use x509_cert::request::{CertReq, CertReqInfo, ExtensionReq, Version as RequestVersion};
use x509_cert::serial_number::SerialNumber;
use x509_cert::time::{Time, Validity};
use x509_cert::{AlgorithmIdentifier, SubjectPublicKeyInfo};

use super::crypto::X509CertData;
use super::crypto::{parse_x509_cert_from_der, parse_x509_cert_from_pem, sm2_message_digest};

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
const PIV_X25519: u8 = 0xE1;
const PIV_MLDSA65: u8 = 0xE2;
const PIV_MLKEM768: u8 = 0xE3;

const OID_RSA_ENCRYPTION: ObjectIdentifier = ObjectIdentifier::new_unwrap("1.2.840.113549.1.1.1");
const OID_EC_PUBLIC_KEY: ObjectIdentifier = ObjectIdentifier::new_unwrap("1.2.840.10045.2.1");
const OID_P256: ObjectIdentifier = ObjectIdentifier::new_unwrap("1.2.840.10045.3.1.7");
const OID_P384: ObjectIdentifier = ObjectIdentifier::new_unwrap("1.3.132.0.34");
const OID_P521: ObjectIdentifier = ObjectIdentifier::new_unwrap("1.3.132.0.35");
const OID_SECP256K1: ObjectIdentifier = ObjectIdentifier::new_unwrap("1.3.132.0.10");
const OID_SM2: ObjectIdentifier = ObjectIdentifier::new_unwrap("1.2.156.10197.1.301");
const OID_ED25519: ObjectIdentifier = ObjectIdentifier::new_unwrap("1.3.101.112");
const OID_X25519: ObjectIdentifier = ObjectIdentifier::new_unwrap("1.3.101.110");
const OID_MLDSA65: ObjectIdentifier = ObjectIdentifier::new_unwrap("2.16.840.1.101.3.4.3.18");
const OID_MLKEM768: ObjectIdentifier = ObjectIdentifier::new_unwrap("2.16.840.1.101.3.4.4.2");

#[derive(Clone)]
pub struct PivPublicKeyData {
    pub subject_public_key_info: Vec<u8>,
    pub raw_public_key: Vec<u8>,
}

#[derive(Clone)]
pub struct PivPrivateKeyData {
    pub algorithm: u8,
    /// PIV key component TLVs, excluding PIN and touch policy TLVs.
    pub import_data: Vec<u8>,
    pub subject_public_key_info: Vec<u8>,
}

pub struct PivImportFileData {
    pub private_key: Option<PivPrivateKeyData>,
    pub certificate: Option<X509CertData>,
}

pub struct SelfSignedCertificateParams {
    pub common_name: String,
    pub organization: Option<String>,
    pub organizational_unit: Option<String>,
    pub country: Option<String>,
    pub subject_public_key_info: Vec<u8>,
    pub serial_number: Vec<u8>,
    pub not_before: String,
    pub not_after: String,
    pub subject_alternative_names: Vec<String>,
}

#[derive(Sequence)]
struct EcSignature {
    r: Uint,
    s: Uint,
}

#[derive(Sequence)]
struct TbsCertificate {
    #[asn1(context_specific = "0", tag_mode = "EXPLICIT")]
    version: CertificateVersion,
    serial_number: SerialNumber,
    signature: AlgorithmIdentifier,
    issuer: Name,
    validity: Validity,
    subject: Name,
    subject_public_key_info: SubjectPublicKeyInfo,
    #[asn1(context_specific = "3", tag_mode = "EXPLICIT", optional = "true")]
    extensions: Option<Vec<Extension>>,
}

#[derive(Sequence)]
struct SignedDerObject {
    body: Any,
    algorithm: AlgorithmIdentifier,
    signature: BitString,
}

pub fn build_piv_public_key(
    algorithm: u8,
    card_data: Vec<u8>,
    generated_response: bool,
) -> Result<PivPublicKeyData, String> {
    let key_data = if generated_response {
        tlv_value(&card_data, 0x7F49)?
    } else {
        card_data.as_slice()
    };

    match algorithm {
        PIV_RSA1024 | PIV_RSA2048 | PIV_RSA3072 | PIV_RSA4096 => {
            let modulus = tlv_value(key_data, 0x81)?;
            let exponent = tlv_value(key_data, 0x82)?;
            let public_key = rsa::RsaPublicKey::new(
                rsa::BigUint::from_bytes_be(modulus),
                rsa::BigUint::from_bytes_be(exponent),
            )
            .map_err(|_| "invalid RSA public key")?;
            let spki = public_key
                .to_public_key_der()
                .map_err(|_| "failed to encode RSA public key")?
                .as_bytes()
                .to_vec();
            Ok(PivPublicKeyData {
                subject_public_key_info: spki,
                raw_public_key: Vec::new(),
            })
        }
        PIV_ECC_P256 | PIV_ECC_P384 | PIV_ECC_P521 | PIV_SECP256K1 | PIV_SM2 | PIV_ED25519
        | PIV_X25519 | PIV_MLDSA65 | PIV_MLKEM768 => {
            let raw = tlv_value(key_data, 0x86)?.to_vec();
            public_key_data(algorithm, raw)
        }
        _ => Err("unsupported PIV public key algorithm".into()),
    }
}

pub fn parse_piv_public_key_info(
    algorithm: u8,
    subject_public_key_info: Vec<u8>,
) -> Result<PivPublicKeyData, String> {
    let spki = SubjectPublicKeyInfo::from_der(&subject_public_key_info)
        .map_err(|_| "invalid subject public key info")?;
    if algorithm_from_spki(&spki)? != algorithm {
        return Err("subject public key algorithm does not match slot algorithm".into());
    }
    let raw = spki
        .subject_public_key
        .as_bytes()
        .ok_or("subject public key is not byte-aligned")?
        .to_vec();
    if !is_rsa(algorithm) {
        validate_raw_public_key(algorithm, &raw)?;
    }
    Ok(PivPublicKeyData {
        subject_public_key_info,
        raw_public_key: if is_rsa(algorithm) { Vec::new() } else { raw },
    })
}

pub fn parse_piv_import_file(bytes: Vec<u8>) -> Result<PivImportFileData, String> {
    if let Ok(text) = std::str::from_utf8(&bytes) {
        if text.contains("-----BEGIN ") {
            return parse_piv_pem_file(text);
        }
    }

    let certificate = parse_x509_cert_from_der(bytes.clone()).ok();
    if certificate.is_some() {
        return Ok(PivImportFileData {
            private_key: None,
            certificate,
        });
    }
    let private_key = parse_private_key_der(&bytes)
        .ok_or_else(|| "unsupported or invalid private key file".to_string())?;
    Ok(PivImportFileData {
        private_key: Some(private_key),
        certificate: None,
    })
}

pub fn prepare_piv_csr(
    common_name: String,
    organization: Option<String>,
    organizational_unit: Option<String>,
    country: Option<String>,
    subject_public_key_info: Vec<u8>,
    subject_alternative_names: Vec<String>,
) -> Result<Vec<u8>, String> {
    let subject = subject_name(common_name, organization, organizational_unit, country)?;
    let public_key = SubjectPublicKeyInfo::from_der(&subject_public_key_info)
        .map_err(|_| "invalid subject public key info")?;
    let mut attributes = Attributes::new();
    if !subject_alternative_names.is_empty() {
        let extension = subject_alt_name_extension(&subject, subject_alternative_names)?;
        attributes
            .insert(
                ExtensionReq(vec![extension])
                    .try_into()
                    .map_err(der_error)?,
            )
            .map_err(der_error)?;
    }
    CertReqInfo {
        version: RequestVersion::V1,
        subject,
        public_key,
        attributes,
    }
    .to_der()
    .map_err(der_error)
}

pub fn finish_piv_csr(
    certification_request_info: Vec<u8>,
    algorithm: u8,
    signature: Vec<u8>,
) -> Result<String, String> {
    let info = CertReqInfo::from_der(&certification_request_info)
        .map_err(|_| "invalid certification request info")?;
    if algorithm_from_spki(&info.public_key)? != algorithm {
        return Err("CSR signature algorithm does not match public key".into());
    }
    let request = CertReq {
        info,
        algorithm: signature_algorithm(algorithm)?,
        signature: BitString::from_bytes(&normalize_signature(algorithm, &signature)?)
            .map_err(der_error)?,
    };
    request.to_pem(der::pem::LineEnding::LF).map_err(der_error)
}

pub fn prepare_self_signed_certificate(
    params: SelfSignedCertificateParams,
) -> Result<Vec<u8>, String> {
    let subject = subject_name(
        params.common_name,
        params.organization,
        params.organizational_unit,
        params.country,
    )?;
    let public_key = SubjectPublicKeyInfo::from_der(&params.subject_public_key_info)
        .map_err(|_| "invalid subject public key info")?;
    let algorithm = algorithm_from_spki(&public_key)?;
    let signature = signature_algorithm(algorithm)?;
    let extensions = if params.subject_alternative_names.is_empty() {
        None
    } else {
        Some(vec![subject_alt_name_extension(
            &subject,
            params.subject_alternative_names,
        )?])
    };
    TbsCertificate {
        version: CertificateVersion::V3,
        serial_number: SerialNumber::new(&params.serial_number).map_err(der_error)?,
        signature,
        issuer: subject.clone(),
        validity: Validity::new(
            Time::from_str(&params.not_before).map_err(|_| "invalid not-before time")?,
            Time::from_str(&params.not_after).map_err(|_| "invalid not-after time")?,
        ),
        subject,
        subject_public_key_info: public_key,
        extensions,
    }
    .to_der()
    .map_err(der_error)
}

pub fn finish_self_signed_certificate(
    tbs_certificate: Vec<u8>,
    algorithm: u8,
    signature: Vec<u8>,
) -> Result<Vec<u8>, String> {
    let parsed =
        TbsCertificate::from_der(&tbs_certificate).map_err(|_| "invalid TBS certificate")?;
    let algorithm_identifier = signature_algorithm(algorithm)?;
    if parsed.signature != algorithm_identifier {
        return Err("certificate signature algorithm does not match TBS certificate".into());
    }
    let body = Any::from_der(&tbs_certificate).map_err(|_| "invalid TBS certificate")?;
    if body.tag() != der::Tag::Sequence {
        return Err("invalid TBS certificate".into());
    }
    SignedDerObject {
        body,
        algorithm: algorithm_identifier,
        signature: BitString::from_bytes(&normalize_signature(algorithm, &signature)?)
            .map_err(der_error)?,
    }
    .to_der()
    .map_err(der_error)
}

pub fn prepare_piv_signing_input(
    algorithm: u8,
    data: Vec<u8>,
    public_key: Option<Vec<u8>>,
) -> Result<Vec<u8>, String> {
    match algorithm {
        PIV_RSA1024 | PIV_RSA2048 | PIV_RSA3072 | PIV_RSA4096 => {
            rsa_pkcs1_v15_input(algorithm, &data)
        }
        PIV_ECC_P256 | PIV_SECP256K1 => Ok(Sha256::digest(data).to_vec()),
        PIV_ECC_P384 => Ok(Sha384::digest(data).to_vec()),
        PIV_ECC_P521 => Ok(Sha512::digest(data).to_vec()),
        PIV_SM2 => sm2_message_digest(
            data,
            public_key.ok_or_else(|| "SM2 public key is required".to_string())?,
        ),
        PIV_ED25519 | PIV_MLDSA65 => Ok(data),
        _ => Err("unsupported PIV signing algorithm".into()),
    }
}

fn parse_piv_pem_file(text: &str) -> Result<PivImportFileData, String> {
    let mut private_key = None;
    let mut certificate = None;
    let mut has_private_key_block = false;
    for block in pem_blocks(text) {
        if certificate.is_none() && block.starts_with("-----BEGIN CERTIFICATE-----") {
            certificate = parse_x509_cert_from_pem(block.to_string()).ok();
        }
        if block.contains("PRIVATE KEY-----") {
            has_private_key_block = true;
            if private_key.is_none() {
                private_key = parse_private_key_pem(block);
            }
        }
    }
    if has_private_key_block && private_key.is_none() {
        return Err("PEM contains an unsupported or invalid private key".into());
    }
    if private_key.is_none() && certificate.is_none() {
        return Err("unsupported or invalid PEM file".into());
    }
    Ok(PivImportFileData {
        private_key,
        certificate,
    })
}

fn pem_blocks(text: &str) -> Vec<&str> {
    let mut blocks = Vec::new();
    let mut rest = text;
    while let Some(begin_offset) = rest.find("-----BEGIN ") {
        rest = &rest[begin_offset..];
        let label_start = "-----BEGIN ".len();
        let label_and_rest = &rest[label_start..];
        let Some(label_end) = label_and_rest.find("-----") else {
            break;
        };
        let label = &label_and_rest[..label_end];
        let end_marker = format!("-----END {label}-----");
        let Some(end_offset) = rest.find(&end_marker) else {
            break;
        };
        let end = end_offset + end_marker.len();
        blocks.push(&rest[..end]);
        rest = &rest[end..];
    }
    blocks
}

fn parse_private_key_pem(pem: &str) -> Option<PivPrivateKeyData> {
    if let Ok(key) = RsaPrivateKey::from_pkcs8_pem(pem) {
        return rsa_private_key_data(key).ok();
    }
    if let Ok(key) = RsaPrivateKey::from_pkcs1_pem(pem) {
        return rsa_private_key_data(key).ok();
    }
    parse_ec_private_key_pem(pem).or_else(|| {
        Ed25519SigningKey::from_pkcs8_pem(pem)
            .ok()
            .and_then(|key| ed25519_private_key_data(key).ok())
    })
}

fn parse_private_key_der(der: &[u8]) -> Option<PivPrivateKeyData> {
    RsaPrivateKey::from_pkcs8_der(der)
        .or_else(|_| RsaPrivateKey::from_pkcs1_der(der))
        .ok()
        .and_then(|key| rsa_private_key_data(key).ok())
        .or_else(|| parse_ec_private_key_der(der))
        .or_else(|| {
            Ed25519SigningKey::from_pkcs8_der(der)
                .ok()
                .and_then(|key| ed25519_private_key_data(key).ok())
        })
}

macro_rules! try_ec_key {
    ($key:ty, $source:expr, $algorithm:expr, $parser:ident) => {
        if let Ok(key) = <$key>::$parser($source) {
            let scalar = key.to_bytes().to_vec();
            let public = key.public_key().to_sec1_point(false).as_bytes().to_vec();
            return ec_private_key_data($algorithm, scalar, public).ok();
        }
    };
}

fn parse_ec_private_key_der(der: &[u8]) -> Option<PivPrivateKeyData> {
    try_ec_key!(p256::SecretKey, der, PIV_ECC_P256, from_der);
    try_ec_key!(p384::SecretKey, der, PIV_ECC_P384, from_der);
    try_ec_key!(p521::SecretKey, der, PIV_ECC_P521, from_der);
    try_ec_key!(k256::SecretKey, der, PIV_SECP256K1, from_der);
    if let Ok(key) =
        sm2::SecretKey::from_pkcs8_der(der).or_else(|_| sm2::SecretKey::from_sec1_der(der))
    {
        let scalar = key.to_bytes().to_vec();
        let public = key.public_key().to_encoded_point(false).as_bytes().to_vec();
        return ec_private_key_data(PIV_SM2, scalar, public).ok();
    }
    None
}

fn parse_ec_private_key_pem(pem: &str) -> Option<PivPrivateKeyData> {
    try_ec_key!(p256::SecretKey, pem, PIV_ECC_P256, from_pem);
    try_ec_key!(p384::SecretKey, pem, PIV_ECC_P384, from_pem);
    try_ec_key!(p521::SecretKey, pem, PIV_ECC_P521, from_pem);
    try_ec_key!(k256::SecretKey, pem, PIV_SECP256K1, from_pem);
    if let Ok(key) =
        sm2::SecretKey::from_pkcs8_pem(pem).or_else(|_| sm2::SecretKey::from_sec1_pem(pem))
    {
        let scalar = key.to_bytes().to_vec();
        let public = key.public_key().to_encoded_point(false).as_bytes().to_vec();
        return ec_private_key_data(PIV_SM2, scalar, public).ok();
    }
    None
}

fn rsa_private_key_data(mut key: RsaPrivateKey) -> Result<PivPrivateKeyData, String> {
    key.validate().map_err(|_| "invalid RSA private key")?;
    let size = key.size();
    let algorithm = match size {
        128 => PIV_RSA1024,
        256 => PIV_RSA2048,
        384 => PIV_RSA3072,
        512 => PIV_RSA4096,
        _ => return Err(format!("unsupported RSA key size: {} bits", size * 8)),
    };
    if key.primes().len() != 2 {
        return Err("multi-prime RSA keys are not supported".into());
    }
    key.precompute()
        .map_err(|_| "failed to compute RSA CRT parameters")?;
    let component_size = size / 2;
    let qinv = key
        .qinv()
        .and_then(|value| value.to_biguint())
        .ok_or("invalid RSA CRT coefficient")?;
    let components = [
        key.primes()[0].to_bytes_be(),
        key.primes()[1].to_bytes_be(),
        key.dp().ok_or("missing RSA dP")?.to_bytes_be(),
        key.dq().ok_or("missing RSA dQ")?.to_bytes_be(),
        qinv.to_bytes_be(),
    ];
    let mut import_data = Vec::with_capacity(5 * (component_size + 4));
    for (index, component) in components.iter().enumerate() {
        import_data.push(index as u8 + 1);
        import_data.push(0x82);
        import_data.extend_from_slice(&(component_size as u16).to_be_bytes());
        import_data.extend_from_slice(&left_pad(component, component_size)?);
    }
    let subject_public_key_info = key
        .to_public_key()
        .to_public_key_der()
        .map_err(|_| "failed to encode RSA public key")?
        .as_bytes()
        .to_vec();
    Ok(PivPrivateKeyData {
        algorithm,
        import_data,
        subject_public_key_info,
    })
}

fn ec_private_key_data(
    algorithm: u8,
    scalar: Vec<u8>,
    public_key: Vec<u8>,
) -> Result<PivPrivateKeyData, String> {
    let subject_public_key_info = public_key_data(algorithm, public_key)?.subject_public_key_info;
    let mut import_data = vec![0x06];
    encode_tlv_length(scalar.len(), &mut import_data)?;
    import_data.extend_from_slice(&scalar);
    Ok(PivPrivateKeyData {
        algorithm,
        import_data,
        subject_public_key_info,
    })
}

fn ed25519_private_key_data(key: Ed25519SigningKey) -> Result<PivPrivateKeyData, String> {
    let subject_public_key_info =
        public_key_data(PIV_ED25519, key.verifying_key().to_bytes().to_vec())?
            .subject_public_key_info;
    let mut import_data = vec![0x06, 0x20];
    import_data.extend_from_slice(&key.to_bytes());
    Ok(PivPrivateKeyData {
        algorithm: PIV_ED25519,
        import_data,
        subject_public_key_info,
    })
}

fn public_key_data(algorithm: u8, raw: Vec<u8>) -> Result<PivPublicKeyData, String> {
    validate_raw_public_key(algorithm, &raw)?;
    let (oid, parameters) = match algorithm {
        PIV_ECC_P256 => (
            OID_EC_PUBLIC_KEY,
            Some(Any::encode_from(&OID_P256).map_err(der_error)?),
        ),
        PIV_ECC_P384 => (
            OID_EC_PUBLIC_KEY,
            Some(Any::encode_from(&OID_P384).map_err(der_error)?),
        ),
        PIV_ECC_P521 => (
            OID_EC_PUBLIC_KEY,
            Some(Any::encode_from(&OID_P521).map_err(der_error)?),
        ),
        PIV_SECP256K1 => (
            OID_EC_PUBLIC_KEY,
            Some(Any::encode_from(&OID_SECP256K1).map_err(der_error)?),
        ),
        PIV_SM2 => (
            OID_EC_PUBLIC_KEY,
            Some(Any::encode_from(&OID_SM2).map_err(der_error)?),
        ),
        PIV_ED25519 => (OID_ED25519, None),
        PIV_X25519 => (OID_X25519, None),
        PIV_MLDSA65 => (OID_MLDSA65, None),
        PIV_MLKEM768 => (OID_MLKEM768, None),
        _ => return Err("unsupported PIV public key algorithm".into()),
    };
    let spki = SubjectPublicKeyInfo {
        algorithm: AlgorithmIdentifier { oid, parameters },
        subject_public_key: BitString::from_bytes(&raw).map_err(der_error)?,
    }
    .to_der()
    .map_err(der_error)?;
    Ok(PivPublicKeyData {
        subject_public_key_info: spki,
        raw_public_key: raw,
    })
}

fn validate_raw_public_key(algorithm: u8, raw: &[u8]) -> Result<(), String> {
    match algorithm {
        PIV_ECC_P256 => p256::PublicKey::from_sec1_bytes(raw)
            .map(|_| ())
            .map_err(|_| "invalid P-256 public key".into()),
        PIV_ECC_P384 => p384::PublicKey::from_sec1_bytes(raw)
            .map(|_| ())
            .map_err(|_| "invalid P-384 public key".into()),
        PIV_ECC_P521 => p521::PublicKey::from_sec1_bytes(raw)
            .map(|_| ())
            .map_err(|_| "invalid P-521 public key".into()),
        PIV_SECP256K1 => k256::PublicKey::from_sec1_bytes(raw)
            .map(|_| ())
            .map_err(|_| "invalid secp256k1 public key".into()),
        PIV_SM2 => sm2::PublicKey::from_sec1_bytes(raw)
            .map(|_| ())
            .map_err(|_| "invalid SM2 public key".into()),
        PIV_ED25519 | PIV_X25519 if raw.len() == 32 => Ok(()),
        PIV_MLDSA65 if raw.len() == 1952 => Ok(()),
        PIV_MLKEM768 if raw.len() == 1184 => Ok(()),
        PIV_ED25519 | PIV_X25519 | PIV_MLDSA65 | PIV_MLKEM768 => {
            Err("invalid public key length".into())
        }
        _ => Err("unsupported PIV public key algorithm".into()),
    }
}

fn subject_name(
    common_name: String,
    organization: Option<String>,
    organizational_unit: Option<String>,
    country: Option<String>,
) -> Result<Name, String> {
    if common_name.is_empty() {
        return Err("common name is required".into());
    }
    let mut fields = vec![format!("CN={}", escape_dn_value(&common_name))];
    if let Some(value) = organization.filter(|value| !value.is_empty()) {
        fields.push(format!("O={}", escape_dn_value(&value)));
    }
    if let Some(value) = organizational_unit.filter(|value| !value.is_empty()) {
        fields.push(format!("OU={}", escape_dn_value(&value)));
    }
    if let Some(value) = country.filter(|value| !value.is_empty()) {
        if value.len() != 2 || !value.bytes().all(|byte| byte.is_ascii_alphabetic()) {
            return Err("country code must contain exactly two ASCII letters".into());
        }
        fields.push(format!("C={}", value.to_ascii_uppercase()));
    }
    Name::from_str(&fields.join(",")).map_err(|_| "invalid certificate subject".into())
}

fn escape_dn_value(value: &str) -> String {
    let chars: Vec<char> = value.chars().collect();
    let mut output = String::new();
    for (index, ch) in chars.iter().enumerate() {
        let edge_space = *ch == ' ' && (index == 0 || index + 1 == chars.len());
        if edge_space
            || (index == 0 && *ch == '#')
            || matches!(*ch, ',' | '+' | '"' | '\\' | '<' | '>' | ';' | '=')
        {
            output.push('\\');
        }
        output.push(*ch);
    }
    output
}

fn subject_alt_name_extension(subject: &Name, names: Vec<String>) -> Result<Extension, String> {
    let names = names
        .into_iter()
        .map(|name| {
            Ia5String::new(name.as_bytes())
                .map(GeneralName::DnsName)
                .map_err(der_error)
        })
        .collect::<Result<Vec<_>, _>>()?;
    SubjectAltName(names)
        .to_extension(subject, &[])
        .map_err(der_error)
}

fn signature_algorithm(algorithm: u8) -> Result<AlgorithmIdentifier, String> {
    let oid = match algorithm {
        PIV_RSA1024 | PIV_RSA2048 | PIV_RSA3072 | PIV_RSA4096 => {
            ObjectIdentifier::new_unwrap("1.2.840.113549.1.1.11")
        }
        PIV_ECC_P256 | PIV_SECP256K1 => ObjectIdentifier::new_unwrap("1.2.840.10045.4.3.2"),
        PIV_ECC_P384 => ObjectIdentifier::new_unwrap("1.2.840.10045.4.3.3"),
        PIV_ECC_P521 => ObjectIdentifier::new_unwrap("1.2.840.10045.4.3.4"),
        PIV_SM2 => ObjectIdentifier::new_unwrap("1.2.156.10197.1.501"),
        PIV_ED25519 => OID_ED25519,
        PIV_MLDSA65 => OID_MLDSA65,
        _ => return Err("unsupported certificate signature algorithm".into()),
    };
    Ok(AlgorithmIdentifier {
        oid,
        parameters: if is_rsa(algorithm) {
            Some(Any::null())
        } else {
            None
        },
    })
}

fn algorithm_from_spki(spki: &SubjectPublicKeyInfo) -> Result<u8, String> {
    match spki.algorithm.oid {
        OID_RSA_ENCRYPTION => {
            let rsa = rsa::RsaPublicKey::from_public_key_der(&spki.to_der().map_err(der_error)?)
                .map_err(|_| "invalid RSA subject public key info")?;
            match rsa.size() {
                128 => Ok(PIV_RSA1024),
                256 => Ok(PIV_RSA2048),
                384 => Ok(PIV_RSA3072),
                512 => Ok(PIV_RSA4096),
                _ => Err("unsupported RSA public key size".into()),
            }
        }
        OID_ED25519 => Ok(PIV_ED25519),
        OID_X25519 => Ok(PIV_X25519),
        OID_MLDSA65 => Ok(PIV_MLDSA65),
        OID_MLKEM768 => Ok(PIV_MLKEM768),
        OID_EC_PUBLIC_KEY => {
            let curve = spki
                .algorithm
                .parameters
                .as_ref()
                .ok_or("EC curve parameters are missing")?;
            let curve = curve
                .decode_as::<ObjectIdentifier>()
                .map_err(|_| "invalid EC curve parameters")?;
            match curve {
                OID_P256 => Ok(PIV_ECC_P256),
                OID_P384 => Ok(PIV_ECC_P384),
                OID_P521 => Ok(PIV_ECC_P521),
                OID_SECP256K1 => Ok(PIV_SECP256K1),
                OID_SM2 => Ok(PIV_SM2),
                _ => Err("unsupported EC curve".into()),
            }
        }
        _ => Err("unsupported subject public key algorithm".into()),
    }
}

fn normalize_signature(algorithm: u8, signature: &[u8]) -> Result<Vec<u8>, String> {
    let scalar_size = match algorithm {
        PIV_ECC_P256 | PIV_SECP256K1 | PIV_SM2 => Some(32),
        PIV_ECC_P384 => Some(48),
        PIV_ECC_P521 => Some(66),
        _ => None,
    };
    let Some(scalar_size) = scalar_size else {
        return Ok(signature.to_vec());
    };
    if let Ok(parsed) = EcSignature::from_der(signature) {
        if parsed.r.as_bytes().len() > scalar_size || parsed.s.as_bytes().len() > scalar_size {
            return Err("ECDSA signature scalar is too large".into());
        }
        return Ok(signature.to_vec());
    }
    if signature.len() != scalar_size * 2 {
        return Err("invalid ECDSA signature encoding".into());
    }
    EcSignature {
        r: Uint::new(&signature[..scalar_size]).map_err(der_error)?,
        s: Uint::new(&signature[scalar_size..]).map_err(der_error)?,
    }
    .to_der()
    .map_err(der_error)
}

fn rsa_pkcs1_v15_input(algorithm: u8, data: &[u8]) -> Result<Vec<u8>, String> {
    const SHA256_DIGEST_INFO_PREFIX: [u8; 19] = [
        0x30, 0x31, 0x30, 0x0D, 0x06, 0x09, 0x60, 0x86, 0x48, 0x01, 0x65, 0x03, 0x04, 0x02, 0x01,
        0x05, 0x00, 0x04, 0x20,
    ];
    let key_size = match algorithm {
        PIV_RSA1024 => 128,
        PIV_RSA2048 => 256,
        PIV_RSA3072 => 384,
        PIV_RSA4096 => 512,
        _ => return Err("unsupported RSA algorithm".into()),
    };
    let digest = Sha256::digest(data);
    let digest_info_size = SHA256_DIGEST_INFO_PREFIX.len() + digest.len();
    let padding_size = key_size - digest_info_size - 3;
    if padding_size < 8 {
        return Err("RSA key is too small for SHA-256 PKCS#1 v1.5".into());
    }
    let mut output = Vec::with_capacity(key_size);
    output.extend_from_slice(&[0, 1]);
    output.resize(2 + padding_size, 0xFF);
    output.push(0);
    output.extend_from_slice(&SHA256_DIGEST_INFO_PREFIX);
    output.extend_from_slice(&digest);
    Ok(output)
}

fn left_pad(bytes: &[u8], length: usize) -> Result<Vec<u8>, String> {
    if bytes.len() > length {
        return Err("private key component is too large".into());
    }
    let mut output = vec![0; length];
    output[length - bytes.len()..].copy_from_slice(bytes);
    Ok(output)
}

fn encode_tlv_length(length: usize, output: &mut Vec<u8>) -> Result<(), String> {
    match length {
        0..=0x7F => output.push(length as u8),
        0x80..=0xFF => output.extend_from_slice(&[0x81, length as u8]),
        0x100..=0xFFFF => {
            output.push(0x82);
            output.extend_from_slice(&(length as u16).to_be_bytes());
        }
        _ => return Err("TLV value is too large".into()),
    }
    Ok(())
}

fn tlv_value(data: &[u8], wanted_tag: u32) -> Result<&[u8], String> {
    let mut offset = 0;
    while offset < data.len() {
        let mut tag = data[offset] as u32;
        offset += 1;
        if tag & 0x1F == 0x1F {
            loop {
                let byte = *data.get(offset).ok_or("truncated TLV tag")?;
                offset += 1;
                tag = (tag << 8) | byte as u32;
                if byte & 0x80 == 0 {
                    break;
                }
            }
        }
        let first_length = *data.get(offset).ok_or("truncated TLV length")?;
        offset += 1;
        let length = if first_length & 0x80 == 0 {
            first_length as usize
        } else {
            let count = (first_length & 0x7F) as usize;
            if count == 0 || count > 3 || offset + count > data.len() {
                return Err("invalid TLV length".into());
            }
            let mut length = 0usize;
            for byte in &data[offset..offset + count] {
                length = (length << 8) | *byte as usize;
            }
            offset += count;
            length
        };
        let end = offset.checked_add(length).ok_or("invalid TLV length")?;
        if end > data.len() {
            return Err("truncated TLV value".into());
        }
        if tag == wanted_tag {
            return Ok(&data[offset..end]);
        }
        offset = end;
    }
    Err(format!("missing TLV tag {wanted_tag:X}"))
}

fn is_rsa(algorithm: u8) -> bool {
    matches!(
        algorithm,
        PIV_RSA1024 | PIV_RSA2048 | PIV_RSA3072 | PIV_RSA4096
    )
}

fn der_error(error: impl std::fmt::Display) -> String {
    error.to_string()
}

#[cfg(test)]
mod tests {
    use super::*;
    use ed25519_dalek::pkcs8::EncodePrivateKey as Ed25519EncodePrivateKey;
    use rsa::pkcs8::EncodePrivateKey;

    #[test]
    fn prepares_rsa_signing_input() {
        let input = prepare_piv_signing_input(PIV_RSA2048, b"abc".to_vec(), None).unwrap();
        assert_eq!(input.len(), 256);
        assert_eq!(&input[..2], &[0, 1]);
        assert_eq!(
            &input[input.len() - 32..],
            Sha256::digest(b"abc").as_slice()
        );
    }

    #[test]
    fn imports_rsa_pkcs8_with_fixed_width_components() {
        let key = RsaPrivateKey::new(&mut rsa::rand_core::OsRng, 1024).unwrap();
        let der = key.to_pkcs8_der().unwrap();
        let parsed = parse_piv_import_file(der.as_bytes().to_vec()).unwrap();
        let key = parsed.private_key.unwrap();
        assert_eq!(key.algorithm, PIV_RSA1024);
        assert_eq!(key.import_data.len(), 5 * (4 + 64));
        assert!(!key.subject_public_key_info.is_empty());
    }

    #[test]
    fn imports_ec_pkcs8_and_derives_matching_public_key() {
        let key = p256::SecretKey::from_slice(&[3; 32]).unwrap();
        let der = key.to_pkcs8_der().unwrap();
        let parsed = parse_piv_import_file(der.as_bytes().to_vec()).unwrap();
        let parsed = parsed.private_key.unwrap();
        assert_eq!(parsed.algorithm, PIV_ECC_P256);
        assert_eq!(&parsed.import_data[..2], &[0x06, 0x20]);
        let public =
            parse_piv_public_key_info(PIV_ECC_P256, parsed.subject_public_key_info.clone())
                .unwrap();
        assert_eq!(public.raw_public_key.len(), 65);

        let sec1 = key.to_sec1_der().unwrap();
        let parsed = parse_piv_import_file(sec1.to_vec()).unwrap();
        assert_eq!(parsed.private_key.unwrap().algorithm, PIV_ECC_P256);
    }

    #[test]
    fn imports_ed25519_pkcs8_seed() {
        let key = Ed25519SigningKey::from_bytes(&[5; 32]);
        let der = key.to_pkcs8_der().unwrap();
        let parsed = parse_piv_import_file(der.as_bytes().to_vec()).unwrap();
        let parsed = parsed.private_key.unwrap();
        assert_eq!(parsed.algorithm, PIV_ED25519);
        assert_eq!(&parsed.import_data[..2], &[0x06, 0x20]);
        assert_eq!(&parsed.import_data[2..], &[5; 32]);
    }

    #[test]
    fn converts_slot_and_generate_responses_to_the_same_spki() {
        let key = p256::SecretKey::from_slice(&[4; 32]).unwrap();
        let raw = key.public_key().to_sec1_point(false).as_bytes().to_vec();
        let mut slot = vec![0x86];
        encode_tlv_length(raw.len(), &mut slot).unwrap();
        slot.extend_from_slice(&raw);
        let mut generated = vec![0x7F, 0x49];
        encode_tlv_length(slot.len(), &mut generated).unwrap();
        generated.extend_from_slice(&slot);

        let metadata = build_piv_public_key(PIV_ECC_P256, slot, false).unwrap();
        let response = build_piv_public_key(PIV_ECC_P256, generated, true).unwrap();
        assert_eq!(
            metadata.subject_public_key_info,
            response.subject_public_key_info
        );
        assert_eq!(metadata.raw_public_key, raw);
    }

    #[test]
    fn normalizes_raw_and_rejects_malformed_der_signatures() {
        let raw = vec![1; 64];
        let der = normalize_signature(PIV_ECC_P256, &raw).unwrap();
        assert!(EcSignature::from_der(&der).is_ok());
        let mut trailing = der;
        trailing.push(0);
        assert!(normalize_signature(PIV_ECC_P256, &trailing).is_err());
    }

    #[test]
    fn builds_and_parses_csr() {
        let key = p256::SecretKey::from_slice(&[7; 32]).unwrap();
        let public = key.public_key().to_sec1_point(false).as_bytes().to_vec();
        let spki = public_key_data(PIV_ECC_P256, public)
            .unwrap()
            .subject_public_key_info;
        let info = prepare_piv_csr(
            "CanoKey, Test".into(),
            Some("CanoKey".into()),
            None,
            Some("CN".into()),
            spki,
            vec!["example.com".into()],
        )
        .unwrap();
        let pem = finish_piv_csr(info, PIV_ECC_P256, vec![1; 64]).unwrap();
        assert!(pem.starts_with("-----BEGIN CERTIFICATE REQUEST-----"));
    }

    #[test]
    fn rejects_csr_signature_algorithm_mismatches() {
        let key = p256::SecretKey::from_slice(&[7; 32]).unwrap();
        let public = key.public_key().to_sec1_point(false).as_bytes().to_vec();
        let spki = public_key_data(PIV_ECC_P256, public)
            .unwrap()
            .subject_public_key_info;
        let info = prepare_piv_csr("CanoKey".into(), None, None, None, spki, Vec::new()).unwrap();

        assert_eq!(
            finish_piv_csr(info, PIV_ECC_P384, vec![1; 96]).unwrap_err(),
            "CSR signature algorithm does not match public key"
        );
    }

    #[test]
    fn builds_parseable_self_signed_certificate() {
        let key = p256::SecretKey::from_slice(&[9; 32]).unwrap();
        let public = key.public_key().to_sec1_point(false).as_bytes().to_vec();
        let spki = public_key_data(PIV_ECC_P256, public)
            .unwrap()
            .subject_public_key_info;
        let tbs = prepare_self_signed_certificate(SelfSignedCertificateParams {
            common_name: "CanoKey".into(),
            organization: None,
            organizational_unit: None,
            country: Some("CN".into()),
            subject_public_key_info: spki,
            serial_number: vec![1],
            not_before: "2026-01-01T00:00:00Z".into(),
            not_after: "2027-01-01T00:00:00Z".into(),
            subject_alternative_names: vec!["example.com".into()],
        })
        .unwrap();
        let certificate = finish_self_signed_certificate(tbs, PIV_ECC_P256, vec![2; 64]).unwrap();
        let parsed = parse_x509_cert_from_der(certificate).unwrap();
        assert_eq!(parsed.raw_public_key.len(), 65);
        assert!(!parsed.subject_public_key_info.is_empty());
    }

    #[test]
    fn encodes_post_quantum_spki_and_certificate_with_standard_oid() {
        let public = public_key_data(PIV_MLDSA65, vec![0; 1952]).unwrap();
        let spki = SubjectPublicKeyInfo::from_der(&public.subject_public_key_info).unwrap();
        assert_eq!(spki.algorithm.oid, OID_MLDSA65);
        let tbs = prepare_self_signed_certificate(SelfSignedCertificateParams {
            common_name: "ML-DSA-65".into(),
            organization: None,
            organizational_unit: None,
            country: None,
            subject_public_key_info: public.subject_public_key_info,
            serial_number: vec![1],
            not_before: "2026-01-01T00:00:00Z".into(),
            not_after: "2027-01-01T00:00:00Z".into(),
            subject_alternative_names: vec![],
        })
        .unwrap();
        let certificate = finish_self_signed_certificate(tbs, PIV_MLDSA65, vec![0; 3309]).unwrap();
        assert!((5000..=6131).contains(&certificate.len()));
        assert!(parse_x509_cert_from_der(certificate).is_ok());
    }

    #[test]
    fn parses_multiple_pem_blocks() {
        let key = RsaPrivateKey::new(&mut rsa::rand_core::OsRng, 1024).unwrap();
        let pem = key
            .to_pkcs8_pem(rsa::pkcs8::LineEnding::LF)
            .unwrap()
            .to_string();
        let parsed = parse_piv_import_file(pem.into_bytes()).unwrap();
        assert_eq!(parsed.private_key.unwrap().algorithm, PIV_RSA1024);
    }

    #[test]
    fn validates_and_normalizes_country_code() {
        let valid = subject_name("CanoKey".into(), None, None, Some("cn".into())).unwrap();
        assert!(valid.to_string().contains("C=CN"));

        assert!(subject_name("CanoKey".into(), None, None, Some("China".into())).is_err());
        assert!(subject_name("CanoKey".into(), None, None, Some("C1".into())).is_err());
        assert!(subject_name("CanoKey".into(), None, None, Some("中国".into())).is_err());
    }

    #[test]
    fn rejects_invalid_private_key_in_certificate_pem_bundle() {
        let key = p256::SecretKey::from_slice(&[11; 32]).unwrap();
        let public = key.public_key().to_sec1_point(false).as_bytes().to_vec();
        let spki = public_key_data(PIV_ECC_P256, public)
            .unwrap()
            .subject_public_key_info;
        let tbs = prepare_self_signed_certificate(SelfSignedCertificateParams {
            common_name: "CanoKey".into(),
            organization: None,
            organizational_unit: None,
            country: None,
            subject_public_key_info: spki,
            serial_number: vec![1],
            not_before: "2026-01-01T00:00:00Z".into(),
            not_after: "2027-01-01T00:00:00Z".into(),
            subject_alternative_names: vec![],
        })
        .unwrap();
        let certificate = finish_self_signed_certificate(tbs, PIV_ECC_P256, vec![1; 64]).unwrap();
        let certificate_pem = x509_cert::Certificate::from_der(&certificate)
            .unwrap()
            .to_pem(der::pem::LineEnding::LF)
            .unwrap();
        let bundle = format!(
            "-----BEGIN PRIVATE KEY-----\nAA==\n-----END PRIVATE KEY-----\n{certificate_pem}"
        );

        let error = parse_piv_import_file(bundle.into_bytes()).err().unwrap();
        assert_eq!(error, "PEM contains an unsupported or invalid private key");
    }
}
