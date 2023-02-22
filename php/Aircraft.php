<?php

class Aircraft {
    public string $registration;
    public string $type;

    // create from json
    public static function fromJson($json) : Aircraft {
        $aircraft = new Aircraft();
        $aircraft->registration = $json['registration'];
        $aircraft->type = $json['type'];
        return $aircraft;
    }
}
?>
