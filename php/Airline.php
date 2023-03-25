<?php

class Airline {
    public string $airline_name;
    public string $apple_identifier;
    public int $airline_id = -1;
    public ?string $airline_identifier;

    static ?Airline $current = null;

    static array $jsonKeys = ['airline_name' => 'string', 'apple_identifier' => 'string', 'airline_id' => 'integer', 'airline_identifier' => 'string'];
    static array $jsonValuesOptionalDefaults = ['airline_id' => -1, 'airline_identifier' => ''];

    function toJson() {
        return JsonHelper::toJson($this);
    }

    function sign($data) {
        // simple signature, just a sha256 hash of the secret + data
        // but should be good enough for our purpose
        $secret = Config::$shared['secret'];
        return hash('sha256', $secret . $data);
    }

    function verify($data, $signature) {
        return $signature == $this->sign($data);
    }

    static function fromJson($json) {
        return JsonHelper::fromJson($json, Airline::class);
    }

    // this is public static function because it will be use for example to create a new airline 
    // in the database, and we don't have an instance of the airline yet
    static function airlineIdentifierFromAppleIdentifier($identifier) : string {
        // use md5, this is not secure but here we are just looking
        // for a unique identifier
        return hash('sha1', $identifier);
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
