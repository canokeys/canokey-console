use rxing::qrcode::QRCodeReader;
use rxing::ImmutableReader;
use image::ImageReader;

use once_cell::sync::Lazy;

static LAZY_STATIC_QR_READER: Lazy<QRCodeReader> = Lazy::new(QRCodeReader::default);

fn rgba_to_argb(rgba: &[u8]) -> Vec<u32> {
    let mut argb = Vec::with_capacity(rgba.len() / 4);
    for pixel in rgba.chunks_exact (4) {
        argb.push(((pixel[3] as u32) << 24) | ((pixel[2] as u32) << 16) | ((pixel[1] as u32) << 8) | pixel[0] as u32);
    }
    argb
}

#[flutter_rust_bridge::frb(sync)]
pub fn decode_png_qrcode(png_file: Vec<u8>) -> String {
    // decode png
    let reader = ImageReader::with_format(std::io::Cursor::new(png_file), image::ImageFormat::Png);
    let img = reader.decode().unwrap();
    let argb_buf = rgba_to_argb(img.to_rgba8().as_ref());
    
    // decode qrcode
    let ls = rxing::RGBLuminanceSource::new_with_width_height_pixels(img.width() as usize, img.height() as usize, argb_buf.as_slice());
    let bin = rxing::common::HybridBinarizer::new(ls);
    let mut bitmap: rxing::BinaryBitmap<rxing::common::HybridBinarizer<rxing::RGBLuminanceSource>> = rxing::BinaryBitmap::new(bin);
    let result = LAZY_STATIC_QR_READER.immutable_decode(&mut bitmap).unwrap();
    result.getText().into()
}

#[flutter_rust_bridge::frb(init)]
pub fn init_app() {
    flutter_rust_bridge::setup_default_user_utils();
}
