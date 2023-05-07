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

    function signer() {
        $rv = Signature::retrieveOrCreate($this->apple_identifier);
        return $rv;
    }
    function publicKeys() {
        return $this->signer()->exportPublicKeys();
    }
    function signatureDigest($data) {
        $signer = $this->signer();
        return $signer->signatureDigest($data);
    }

    function verifySignatureDigest($data, $signature) {
        $signer = $this->signer();
        if( is_array($signature) ) {
            return $signer->verifySignatureDigest($data, $signature);
        }else{
            return $signer->verifySecretHash($data, $signature);
        }
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
