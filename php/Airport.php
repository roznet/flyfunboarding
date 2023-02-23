<?php

class Airport {
    
	public string $icao;
    private static $db = null;

    private array $info = [];
	public function __construct(string $icao) {
		// make icao uppercase
		$this->icao = strtoupper($icao);
		if (self::$db == null) {
			self::$db = new PDO('sqlite:../python/airports.db');
		}
	}

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

    public function getCity() {
        $info = $this->getInfo();
        return $info['municipality'];
    }
    public function getCountry() {
        $info = $this->getInfo();
        return $info['iso_country'];
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
