use image::ImageReader;
use once_cell::sync::Lazy;
use rxing::qrcode::QRCodeReader;
use rxing::ImmutableReader;

static LAZY_STATIC_QR_READER: Lazy<QRCodeReader> = Lazy::new(QRCodeReader::default);

fn rgba_to_argb(rgba: &[u8]) -> Vec<u32> {
    let mut argb = Vec::with_capacity(rgba.len() / 4);
    for pixel in rgba.chunks_exact(4) {
        argb.push(
            ((pixel[3] as u32) << 24)
                | ((pixel[2] as u32) << 16)
                | ((pixel[1] as u32) << 8)
                | pixel[0] as u32,
        );
    }
    argb
}

pub fn decode_png_qrcode(png_file: Vec<u8>) -> String {
    // decode png
    let reader = ImageReader::with_format(std::io::Cursor::new(png_file), image::ImageFormat::Png);
    let img = reader.decode().expect("Cannot decode png");
    log::info!(
        "Decoded PNG image with size {:?} x {:?}",
        img.width(),
        img.height()
    );
    let argb_buf = rgba_to_argb(img.to_rgba8().as_ref());
    log::info!("Converted to ARGB");

    // decode qrcode
    let ls = rxing::RGBLuminanceSource::new_with_width_height_pixels(
        img.width() as usize,
        img.height() as usize,
        argb_buf.as_slice(),
    );
    let bin = rxing::common::HybridBinarizer::new(ls);
    let mut bitmap = rxing::BinaryBitmap::new(bin);
    log::info!("Generated bitmap");
    let result = LAZY_STATIC_QR_READER
        .immutable_decode(&mut bitmap)
        .expect("cannot decode qrcode");
    let text: String = result.getText().into();
    log::info!("Decoded QR code: {:?}", text);

    text
}

#[flutter_rust_bridge::frb(init)]
pub fn init_app() {
    flutter_rust_bridge::setup_default_user_utils();
}
