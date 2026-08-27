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

pub fn decode_png_qrcode(png_file: Vec<u8>) -> Result<String, String> {
    // decode png
    let reader = ImageReader::with_format(std::io::Cursor::new(png_file), image::ImageFormat::Png);
    let img = reader
        .decode()
        .map_err(|error| format!("Cannot decode PNG: {error}"))?;
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
    )
    .map_err(|error| format!("Cannot create QR luminance source: {error}"))?;
    let bin = rxing::common::HybridBinarizer::new(ls);
    let mut bitmap = rxing::BinaryBitmap::new(bin);
    log::info!("Generated bitmap");
    let result = LAZY_STATIC_QR_READER
        .immutable_decode(&mut bitmap)
        .map_err(|error| format!("Cannot decode QR code: {error}"))?;
    let text: String = result.getText().into();
    log::info!("Decoded QR code: {:?}", text);

    Ok(text)
}

#[cfg(test)]
mod tests {
    use super::decode_png_qrcode;
    use image::{DynamicImage, ImageFormat, RgbaImage};
    use std::io::Cursor;

    #[test]
    fn invalid_png_returns_error() {
        let error = decode_png_qrcode(b"not a png".to_vec()).unwrap_err();

        assert!(error.starts_with("Cannot decode PNG:"));
    }

    #[test]
    fn png_without_qr_code_returns_error() {
        let image = RgbaImage::from_pixel(64, 64, image::Rgba([255, 255, 255, 255]));
        let mut png = Cursor::new(Vec::new());
        DynamicImage::ImageRgba8(image)
            .write_to(&mut png, ImageFormat::Png)
            .unwrap();

        let error = decode_png_qrcode(png.into_inner()).unwrap_err();

        assert!(error.starts_with("Cannot decode QR code:"));
    }
}
