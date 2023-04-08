<?php

class Signature {
    var string $baseName;
    var string $publicKey;
    var string $privateKey;
    var string $secret;

    public function canSign() {
        return $this->privateKey != '';
    }
    public function canVerify() {
        return $this->publicKey != '';
    }

    public function __construct($baseName) {
        $this->baseName = $baseName;
        $this->secret = Config::$shared['secret'];
        $privateKeyFileName = Config::$shared['keys_path'] . '/' . $baseName . '.pem';
        $publicKeyFileName = Config::$shared['keys_path'] . '/' . $baseName . '.pub';
        // check if private key exists
        if(file_exists($privateKeyFileName) ){
            $this->privateKey = file_get_contents($privateKeyFileName);
        }else{
            $this->privateKey = '';
        }
        if( file_exists($publicKeyFileName)){
            $this->publicKey = file_get_contents($publicKeyFileName);
        }else{
            $this->publicKey = '';
        }
    }

    public static function create($baseName = null){
        $res = openssl_pkey_new([
            "private_key_bits" => 2048,
            "private_key_type" => OPENSSL_KEYTYPE_RSA,
        ]);
        openssl_pkey_export($res, $privateKey);
        $publicKeyDetails = openssl_pkey_get_details($res);
        $publicKey = $publicKeyDetails["key"];

        if($baseName == null) {
            $fileNameBase = hash('sha1', $publicKey);
        }else{
            $fileNameBase = $baseName;
        }

        $privateKeyFileName = Config::$shared['keys_path'] . '/' . $fileNameBase . '.pem';
        $publicKeyFileName = Config::$shared['keys_path'] . '/' . $fileNameBase . '.pub';

        // Save keys to files
        file_put_contents($privateKeyFileName, $privateKey);
        file_put_contents($publicKeyFileName, $publicKey);

        return new Signature($fileNameBase);
    }

    public function exportPublicJson() {
        return [
            'baseName' => $this->baseName,
            'publicKey' => $this->publicKey,
        ];
    }

    public function signDigest(string $data) {
        return [
            'hash' => $this->secretHash($data),
            'signature' => $this->sign($data)
        ];
    }

    public function verifyDigest(string $data, array $digest) {
        if( !isset($digest['hash'])){
            return false;
        }
        if( $digest['hash'] != $this->secretHash($data)){
            return false;
        }
        if( isset($digest['signature'])){
            return $this->verify($data, $digest['signature']);
        }
        return true;
    }

    public function sign($data) {
        if(!$this->canSign()) {
            return null;
        }
        openssl_sign($data, $signature, $this->privateKey, OPENSSL_ALGO_SHA256);
        return base64_encode($signature);
    }

    public function verify($data, $signature) {
        if(!$this->canVerify()) {
            return false;
        }
        $signature = base64_decode($signature);
        $result = openssl_verify($data, $signature, $this->publicKey, OPENSSL_ALGO_SHA256);
        return $result == 1;
    }

    public function secretHash($data) {
        $dataToHash = $this->secret . $data;
        $signature = hash('sha256', $dataToHash);
        return $signature;
    }

    public function verifySecretHash($data, $hash) {
        $signature = $this->secretHash($data);
        return $signature == $hash;
    }

    public function digest($data) {
        $rv = [ 'sign' => $this->sign($data), 'hash' => $this->secretHash($data) ];
        return $rv;
    }

}
