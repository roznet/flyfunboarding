<?php

class Airport {
	public string $icao;
	private static $db = null;
	public function __construct(string $icao) {
		// make icao uppercase
		$this->icao = strtoupper($icao);
		if (self::$db == null) {
			self::$db = new PDO('sqlite:../python/airports.db');
		}
	}

	public function getInfo() {
		// load airport info from sqlite database in table airports
		// return array with airport info
		//
		//
		// open sqlite database
		$sql = "SELECT * FROM airports WHERE ident = :icao";
		$sth = self::$db->prepare($sql);
		$sth->execute([':icao' => $this->icao]);
		$result = $sth->fetch(PDO::FETCH_ASSOC);
		return $result;
	}
}
?>	
