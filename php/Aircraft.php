<?php

class Aircraft {
    public string $registration;
    public string $type;
    public int $aircraft_id;

    // create from json
    public static function fromJson($json) : Aircraft {
        $aircraft = new Aircraft();
        $aircraft->registration = $json['registration'];
        $aircraft->type = $json['type'];
        if (isset($json['aircraft_id'])) {
            $aircraft->aircraft_id = $json['aircraft_id'];
        }else{
            $aircraft->aircraft_id = -1;
        }
        return $aircraft;
    }

    function toJson() : array {
        
        $rv = [
            'registration' => $this->registration,
            'type' => $this->type
        ];
        if ($this->aircraft_id != -1) {
            $rv['aircraft_id'] = $this->aircraft_id;
        }
        return $rv;
    }

    function uniqueIdentifier() : string {
        return $this->registration;
    }

}
