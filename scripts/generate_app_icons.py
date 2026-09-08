import os
from PIL import Image, ImageDraw, ImageFilter

SOURCE_IMG_PATH = r"C:\Users\DELL\.gemini\antigravity-ide\brain\dc25fe63-c01c-48ad-a5d4-8a749926384b\.user_uploaded\media_1788868865316.png"
PROJECT_ROOT = r"I:\LATEST TRACKER\u\budget_tracker"

def process_master_icon():
    print("Loading source image...")
    src = Image.open(SOURCE_IMG_PATH).convert("RGBA")
    w, h = src.size

    # Floodfill the 4 outer corners to pure white
    # Threshold accommodates the slight gray gradient from device screenshot
    for pt in [(0, 0), (w - 1, 0), (0, h - 1), (w - 1, h - 1),
               (2, 2), (w - 3, 2), (2, h - 3), (w - 3, h - 3),
               (5, 5), (w - 6, 5), (5, h - 6), (w - 6, h - 6),
               (10, 10), (w - 11, 10), (10, h - 11), (w - 11, h - 11)]:
        try:
            ImageDraw.floodfill(src, pt, (255, 255, 255, 255), thresh=45)
        except Exception:
            pass

    # Create a pristine 1024x1024 canvas with pure white background
    master = Image.new("RGBA", (1024, 1024), (255, 255, 255, 255))
    
    # Scale src to fit 1024x1024 cleanly with high-quality resampling
    src_upscaled = src.resize((1024, 1024), Image.Resampling.LANCZOS)
    
    # Composite onto white background
    master.paste(src_upscaled, (0, 0), src_upscaled)

    # Ensure corners are cleanly white in the master 1024x1024 image
    for pt in [(0, 0), (1023, 0), (0, 1023), (1023, 1023),
               (10, 10), (1013, 10), (10, 1013), (1013, 1013),
               (30, 30), (993, 30), (30, 993), (993, 993)]:
        try:
            ImageDraw.floodfill(master, pt, (255, 255, 255, 255), thresh=45)
        except Exception:
            pass

    return master

def main():
    master = process_master_icon()

    # 1. Save master icon to assets
    assets_dir = os.path.join(PROJECT_ROOT, "assets", "icon")
    os.makedirs(assets_dir, exist_ok=True)
    master_path = os.path.join(assets_dir, "app_icon.png")
    master.save(master_path, "PNG")
    print(f"Saved master icon: {master_path}")

    # 2. Android mipmap icons
    android_res = os.path.join(PROJECT_ROOT, "android", "app", "src", "main", "res")
    android_sizes = {
        "mipmap-mdpi": 48,
        "mipmap-hdpi": 72,
        "mipmap-xhdpi": 96,
        "mipmap-xxhdpi": 144,
        "mipmap-xxxhdpi": 192,
    }
    for folder, size in android_sizes.items():
        out_dir = os.path.join(android_res, folder)
        os.makedirs(out_dir, exist_ok=True)
        out_path = os.path.join(out_dir, "ic_launcher.png")
        resized = master.resize((size, size), Image.Resampling.LANCZOS)
        resized.save(out_path, "PNG")
        print(f"Saved Android icon ({size}x{size}): {out_path}")

    # 3. iOS AppIcon.appiconset
    ios_dir = os.path.join(PROJECT_ROOT, "ios", "Runner", "Assets.xcassets", "AppIcon.appiconset")
    ios_sizes = {
        "Icon-App-20x20@1x.png": 20,
        "Icon-App-20x20@2x.png": 40,
        "Icon-App-20x20@3x.png": 60,
        "Icon-App-29x29@1x.png": 29,
        "Icon-App-29x29@2x.png": 58,
        "Icon-App-29x29@3x.png": 87,
        "Icon-App-40x40@1x.png": 40,
        "Icon-App-40x40@2x.png": 80,
        "Icon-App-40x40@3x.png": 120,
        "Icon-App-60x60@2x.png": 120,
        "Icon-App-60x60@3x.png": 180,
        "Icon-App-76x76@1x.png": 76,
        "Icon-App-76x76@2x.png": 152,
        "Icon-App-83.5x83.5@2x.png": 167,
        "Icon-App-1024x1024@1x.png": 1024,
    }
    if os.path.exists(ios_dir):
        for fname, size in ios_sizes.items():
            out_path = os.path.join(ios_dir, fname)
            resized = master.resize((size, size), Image.Resampling.LANCZOS)
            resized.save(out_path, "PNG")
            print(f"Saved iOS icon ({size}x{size}): {out_path}")

    # 4. macOS AppIcon.appiconset
    macos_dir = os.path.join(PROJECT_ROOT, "macos", "Runner", "Assets.xcassets", "AppIcon.appiconset")
    macos_sizes = {
        "app_icon_16.png": 16,
        "app_icon_32.png": 32,
        "app_icon_64.png": 64,
        "app_icon_128.png": 128,
        "app_icon_256.png": 256,
        "app_icon_512.png": 512,
        "app_icon_1024.png": 1024,
    }
    if os.path.exists(macos_dir):
        for fname, size in macos_sizes.items():
            out_path = os.path.join(macos_dir, fname)
            resized = master.resize((size, size), Image.Resampling.LANCZOS)
            resized.save(out_path, "PNG")
            print(f"Saved macOS icon ({size}x{size}): {out_path}")

    # 5. Web icons
    web_icons_dir = os.path.join(PROJECT_ROOT, "web", "icons")
    web_dir = os.path.join(PROJECT_ROOT, "web")
    if os.path.exists(web_dir):
        favicon_path = os.path.join(web_dir, "favicon.png")
        master.resize((32, 32), Image.Resampling.LANCZOS).save(favicon_path, "PNG")
        print(f"Saved Web favicon: {favicon_path}")

    if os.path.exists(web_icons_dir):
        for fname, size in [
            ("Icon-192.png", 192),
            ("Icon-512.png", 512),
            ("Icon-maskable-192.png", 192),
            ("Icon-maskable-512.png", 512),
        ]:
            out_path = os.path.join(web_icons_dir, fname)
            master.resize((size, size), Image.Resampling.LANCZOS).save(out_path, "PNG")
            print(f"Saved Web icon ({size}x{size}): {out_path}")

    # 6. Windows app_icon.ico
    win_res = os.path.join(PROJECT_ROOT, "windows", "runner", "resources")
    if os.path.exists(win_res):
        win_ico_path = os.path.join(win_res, "app_icon.ico")
        ico_sizes = [(16, 16), (32, 32), (48, 48), (64, 64), (128, 128), (256, 256)]
        ico_imgs = [master.resize(s, Image.Resampling.LANCZOS) for s in ico_sizes]
        ico_imgs[0].save(win_ico_path, format="ICO", sizes=ico_sizes)
        print(f"Saved Windows ICO: {win_ico_path}")

    print("\nAll app icons successfully updated across Android, iOS, macOS, Web, and Windows!")

if __name__ == "__main__":
    main()
