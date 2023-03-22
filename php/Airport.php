<?php

class Airport {
    
	public string $icao;
    private array $info = [];

    private static $db = null;

	public function __construct(string $icao = 'EGLL') {
		// make icao uppercase
		$this->icao = strtoupper($icao);
        if (self::$db == null) {
            $dbpath = Config::$shared['airport_db_path'];
			self::$db = new PDO("sqlite:$dbpath");
		}
    }

    public static $jsonKeys = ['icao' => 'string'];
    public static $jsonValuesOptionalDefaults = [];

    public function getInfo() {
        if (empty($this->info)) {
		// load airport info from sqlite database in table airports
		// return array with airport info
		//
		//
		// open sqlite database
		$sql = "SELECT * FROM airports WHERE ident = :icao";
		$sth = self::$db->prepare($sql);
		$sth->execute([':icao' => $this->icao]);
		$result = $sth->fetch(PDO::FETCH_ASSOC);
        $this->info = $result;
        }
        return $this->info;
    }

    public function getMapURL() {
        $info = $this->getInfo();
        return "https://www.google.com/maps/place/{$info['latitude_deg']},{$info['longitude_deg']}";
    }

    public function getCity() {
        $info = $this->getInfo();
        return $info['municipality'];
    }
    public function getCountry() {
        $info = $this->getInfo();
        return $info['iso_country'];
    }
    public function getLocation() {
        $info = $this->getInfo();
        if (empty($info['latitude_deg']) || empty($info['longitude_deg'])) {
            return null;
        }
        return [
            'latitude' => $info['latitude_deg'],
            'longitude' => $info['longitude_deg'],
        ];
    }
    public function getIcao() {
        return $this->icao;
    }
    public function getName() {
        $info = $this->getInfo();
        return $info['name'];
    }
    public function fitName(int $maxlen): string{
        $name = $this->getName();
        if (strlen($name) < $maxlen) {
            return $name;
        }else if (strlen($this->getCity()) < $maxlen) {
            return $this->getCity();
        }

        return $name;
    }

}
