<?php

class Settings {

    var $json;

    function __construct(array $info) {
        $this->json = [ 
            'backgroundColor' => 'rgb(189,144,71)', 
            'foregroundColor' => 'rgb(0,0,0)', 
            'labelColor' => 'rgb(255,255,255)' 
        ];
        $this->update($info);
    }

    function update(array $info) {
        foreach($info as $key => $value) {
            if( isset($this->json[$key]) ){
                $this->json[$key] = $value;
            }
        }
    }

    function backgroundColor() {
        return $this->json['backgroundColor'];
    }
    function foregroundColor() {
        return $this->json['foregroundColor'];
    }
    function labelColor() {
        return $this->json['labelColor'];
    }

    function toHex(string $color) : ?string {
        // If the color is already in hex format
        if (strpos($color, '#') === 0) {
            return $color;
        }
      
        // Check if it's in "rgb(r, g, b)" format
        if (preg_match("/rgb\((\d+),\s*(\d+),\s*(\d+)\)/", $color, $matches)) {
            return sprintf("#%02x%02x%02x", $matches[1], $matches[2], $matches[3]);
        }
      
        // Return null if the color is not a valid RGB or hex color
        return null;
    }

    function toRgb(string $color) : ?string {
        // If the color is already in RGB format
        if (strpos($color, 'rgb') === 0) {
            return $color;
        }

        // Ensure the hex color is 6 characters long
        if(strlen($color) == 7) {
            list($r, $g, $b) = sscanf($color, "#%02x%02x%02x");
            return "rgb($r, $g, $b)";
        }
        
        // Return null if the color is not a valid RGB or hex color
        return null;
    }

} 
