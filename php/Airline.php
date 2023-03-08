<?php

class Airline {
    public string $airline_name;
    public string $apple_identifier;
    public int $airline_id = -1;

    static array $jsonKeys = ['airline_name' => 'string', 'apple_identifier' => 'string', 'airline_id' => 'integer'];
    static array $jsonValuesOptionalDefaults = ['airline_id' => -1];

    function toJson() {
        return JsonHelper::toJson($this);
    }

    static function fromJson($json) {
        return JsonHelper::fromJson($json, Airline::class);
    }

    function uniqueIdentifier() : array {
        return ['airline_id' => $this->airline_id];
    }

    function validate() : bool {
        $headers = apache_request_headers();
        if (!isset($headers['Authorization'])) {
            return false;
        }
        $bearer = str_replace("Bearer ", "", $headers['Authorization']);
        return $bearer == $this->apple_identifier;
    }


}
