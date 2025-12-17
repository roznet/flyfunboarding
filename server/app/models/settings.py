"""
Settings domain model.

Matches PHP Settings class structure and JSON serialization.
"""
from typing import Optional
from app.models.base import BaseJsonModel


class Settings(BaseJsonModel):
    """
    Settings model matching PHP Settings class.

    Default values match PHP Settings constructor:
    - backgroundColor: str (default 'rgb(189,144,71)')
    - foregroundColor: str (default 'rgb(0,0,0)')
    - labelColor: str (default 'rgb(255,255,255)')
    - customLabel: str (default 'Boarding Group')
    - customLabelEnabled: bool (default True)
    """
    background_color: str = "rgb(189,144,71)"
    foreground_color: str = "rgb(0,0,0)"
    label_color: str = "rgb(255,255,255)"
    custom_label: str = "Boarding Group"
    custom_label_enabled: bool = True

    def to_hex(self, color: str) -> Optional[str]:
        """
        Convert color to hex format.
        
        Matches PHP: Settings->toHex()
        
        Args:
            color: RGB string (e.g., 'rgb(189,144,71)') or hex (e.g., '#bd9047')
            
        Returns:
            Hex color string (e.g., '#bd9047'), or None if invalid
        """
        import re
        
        # If already hex format
        if color.startswith("#"):
            return color
        
        # Check if RGB format: rgb(r, g, b)
        match = re.match(r"rgb\((\d+),\s*(\d+),\s*(\d+)\)", color)
        if match:
            r, g, b = int(match.group(1)), int(match.group(2)), int(match.group(3))
            return f"#{r:02x}{g:02x}{b:02x}"
        
        return None

    def to_rgb(self, color: str) -> Optional[str]:
        """
        Convert color to RGB format.
        
        Matches PHP: Settings->toRgb()
        
        Args:
            color: Hex string (e.g., '#bd9047') or RGB (e.g., 'rgb(189,144,71)')
            
        Returns:
            RGB color string (e.g., 'rgb(189,144,71)'), or None if invalid
        """
        # If already RGB format
        if color.startswith("rgb"):
            return color
        
        # Check if hex format: #rrggbb
        if len(color) == 7 and color.startswith("#"):
            try:
                r, g, b = int(color[1:3], 16), int(color[3:5], 16), int(color[5:7], 16)
                return f"rgb({r}, {g}, {b})"
            except ValueError:
                return None
        
        return None

