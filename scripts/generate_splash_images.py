#!/usr/bin/env python3
"""
Generate splash screen images for Servline app
Creates light and dark mode splash screens with gradient logo
"""

from PIL import Image, ImageDraw, ImageFont
import os

def create_gradient_circle(size, color1, color2):
    """Create a circular gradient background"""
    image = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)

    # Draw gradient circle
    for i in range(size // 2):
        # Interpolate between colors
        ratio = i / (size / 2)
        r = int(color1[0] + (color2[0] - color1[0]) * ratio)
        g = int(color1[1] + (color2[1] - color1[1]) * ratio)
        b = int(color1[2] + (color2[2] - color1[2]) * ratio)

        # Draw circle
        left = size // 2 - (size // 2 - i)
        top = size // 2 - (size // 2 - i)
        right = size // 2 + (size // 2 - i)
        bottom = size // 2 + (size // 2 - i)
        draw.ellipse([left, top, right, bottom], fill=(r, g, b, 255))

    return image

def draw_people_icon(draw, center_x, center_y, size, color):
    """Draw a simple people/queue icon"""
    # Scale factor
    scale = size / 200

    # Draw three people silhouettes
    for i, x_offset in enumerate([-30, 0, 30]):
        x = center_x + int(x_offset * scale)
        y = center_y + int((5 if i == 1 else 10) * scale)

        # Head
        head_radius = int(12 * scale)
        draw.ellipse(
            [x - head_radius, y - head_radius - int(20 * scale),
             x + head_radius, y - int(20 * scale) + head_radius],
            fill=color
        )

        # Body (simplified)
        body_width = int(20 * scale)
        body_height = int(30 * scale)
        draw.ellipse(
            [x - body_width, y - int(10 * scale),
             x + body_width, y + body_height],
            fill=color
        )

def create_splash_logo(output_path, is_dark=False):
    """Create splash screen logo with gradient and icon"""
    # Image size
    width, height = 1024, 1024

    # Colors
    if is_dark:
        bg_color = (30, 41, 59, 0)  # Transparent
        gradient_start = (99, 102, 241)  # Indigo-500
        gradient_end = (79, 70, 229)    # Indigo-600
        icon_color = (255, 255, 255)    # White
    else:
        bg_color = (255, 255, 255, 0)   # Transparent
        gradient_start = (59, 130, 246)  # Blue-500
        gradient_end = (37, 99, 235)     # Blue-600
        icon_color = (255, 255, 255)     # White

    # Create base image
    image = Image.new('RGBA', (width, height), bg_color)

    # Create gradient circle background
    circle_size = 800
    gradient = create_gradient_circle(circle_size, gradient_start, gradient_end)

    # Paste gradient circle in center
    paste_x = (width - circle_size) // 2
    paste_y = (height - circle_size) // 2
    image.paste(gradient, (paste_x, paste_y), gradient)

    # Draw people icon on top
    draw = ImageDraw.Draw(image)
    draw_people_icon(draw, width // 2, height // 2, 200, icon_color)

    # Save image
    image.save(output_path, 'PNG')
    print(f"Created: {output_path}")

def create_simple_logo(output_path, is_dark=False):
    """Create a simpler version for smaller displays"""
    width, height = 512, 512

    if is_dark:
        gradient_start = (99, 102, 241)
        gradient_end = (79, 70, 229)
        icon_color = (255, 255, 255)
    else:
        gradient_start = (59, 130, 246)
        gradient_end = (37, 99, 235)
        icon_color = (255, 255, 255)

    # Create gradient circle
    image = create_gradient_circle(width, gradient_start, gradient_end)

    # Draw icon
    draw = ImageDraw.Draw(image)
    draw_people_icon(draw, width // 2, height // 2, 150, icon_color)

    # Save
    image.save(output_path, 'PNG')
    print(f"Created: {output_path}")

if __name__ == "__main__":
    # Get script directory
    script_dir = os.path.dirname(os.path.abspath(__file__))
    assets_dir = os.path.join(script_dir, "..", "assets", "images")

    # Create assets directory if it doesn't exist
    os.makedirs(assets_dir, exist_ok=True)

    print("Generating splash screen images...")

    # Generate light mode splash
    create_splash_logo(
        os.path.join(assets_dir, "splash_logo.png"),
        is_dark=False
    )

    # Generate dark mode splash
    create_splash_logo(
        os.path.join(assets_dir, "splash_logo_dark.png"),
        is_dark=True
    )

    print("\nDone! Now run: flutter pub run flutter_native_splash:create")
