<?php

// Database table structure:
//      Tickets:    ticket_id, passenger_id, flight_id, json_data 
//      Passengers: passenger_id, json_data
//      Flights:    flight_id, aircraft_id, json_data
//      BoardingPasses: boarding_pass_id, ticket_id, json_data
//      Aircrafts:  aircraft_id, registration, json_data
//
//      
class MyFlyFunDb {

    const MISSING_ID = -1;

    public static $shared = null;
    public $db;
    public function __construct() {
        $config = Config::$shared;
        $this->db = mysqli_connect( $config['db_host'], $config['db_username'], $config['db_password'], $config['database'] );
    }

    public function setup() {
        $this->createTableIfNecessary();
    }
    public function forceSetup() {
        $this->dropTables();
        $this->createTableIfNecessary();
    }

    public function dropTables(){
        $tables = [
            "Flights",
            "Passengers",
            "Tickets",
            "BoardingPasses",
            "Aircrafts",
        ];

        foreach ($tables as $table) {
            mysqli_query($this->db, "DROP TABLE IF EXISTS $table");
        }
    }

    public function createTableIfNecessary() {
        // refactor current function to create tables from an array of string of queries
        $queries = [
            "CREATE TABLE IF NOT EXISTS Flights (flight_id INT NOT NULL AUTO_INCREMENT, aircraft_id INT NOT NULL, json_data JSON, PRIMARY KEY (flight_id))",
            "CREATE TABLE IF NOT EXISTS BoardingPasses (boarding_pass_id INT NOT NULL AUTO_INCREMENT, ticket_id INT NOT NULL, json_data JSON, PRIMARY KEY (boarding_pass_id))",
            "CREATE TABLE IF NOT EXISTS Passengers (passenger_id INT NOT NULL AUTO_INCREMENT, json_data JSON, PRIMARY KEY (passenger_id))",
            "CREATE TABLE IF NOT EXISTS Tickets (ticket_id INT NOT NULL AUTO_INCREMENT, passenger_id INT NOT NULL, flight_id INT NOT NULL, seat VARCHAR(10), PRIMARY KEY (ticket_id))",
            "CREATE TABLE IF NOT EXISTS Aircrafts (aircraft_id INT NOT NULL AUTO_INCREMENT, registration VARCHAR(32) UNIQUE, json_data JSON, PRIMARY KEY (aircraft_id))",
        ];

        foreach ($queries as $query) {
            mysqli_query($this->db, $query);
            if (mysqli_errno($this->db)) {
                die("Error creating table: " . mysqli_error($this->db));
            }
        }
    }

    // Aircrafts
    //
    public function createOrUpdateAircraft(Aircraft $aircraft) {
        $json = json_encode($aircraft->toJson());
        $stmt = mysqli_prepare($this->db, "INSERT INTO Aircrafts (registration, json_data) VALUES (?, ?) ON DUPLICATE KEY UPDATE json_data = VALUES(json_data)");
        $stmt->bind_param("ss", $aircraft->registration, $json);
        $stmt->execute();
    }
    public function listAircrafts() : array {
        $result = mysqli_query($this->db, "SELECT * FROM Aircrafts");
        $aircrafts = [];
        while ($row = mysqli_fetch_assoc($result)) {
            $aircraft = Aircraft::fromJson(json_decode($row['json_data'], true));
            $aircraft->aircraft_id = $row['aircraft_id'];
            $aircrafts[] = $aircraft->toJson();
        }
        return $aircrafts;
    }
    public function getAircraft($aircraft_id) {
        $stmt = mysqli_prepare($this->db, "SELECT * FROM Aircrafts WHERE aircraft_id = ?");
        $stmt->bind_param("i", $aircraft_id);
        $stmt->execute();
        $result = $stmt->get_result();
        if ($result->num_rows == 0) {
            return null;
        }
        $row = $result->fetch_assoc();
        $aircraft = Aircraft::fromJson(json_decode($row['json_data'], true));
        $aircraft->aircraft_id = $row['aircraft_id'];
        return $aircraft;
    }

    // Passengers
    public function createOrUpdatePassenger(Passenger $passenger) {
        $json = json_encode($passenger->toJson());
        $stmt = mysqli_prepare($this->db, "INSERT INTO Passengers (json_data) VALUES (?) ON DUPLICATE KEY UPDATE json_data = VALUES(json_data)");
        $stmt->bind_param("s",  $json);
        $stmt->execute();
    }

    public function listPassengers() : array {
        $result = mysqli_query($this->db, "SELECT * FROM Passengers");
        $passengers = [];
        while ($row = mysqli_fetch_assoc($result)) {
            $passenger = Passenger::fromJson(json_decode($row['json_data'], true));
            $passenger->passenger_id = $row['passenger_id'];
            $passengers[] = $passenger->toJson();
        }
        return $passengers;
    }

    public function getPassenger($passsenger_id) {
        $stmt = mysqli_prepare($this->db, "SELECT * FROM Passengers WHERE passenger_id = ?");
        $stmt->bind_param("i", $passsenger_id);
        $stmt->execute();
        $result = $stmt->get_result();
        if ($result->num_rows == 0) {
            return null;
        }
        $row = $result->fetch_assoc();
        $passenger = Passenger::fromJson(json_decode($row['json_data'], true));
        $passenger->passenger_id = $row['passenger_id'];
        return $passenger;
    }

}
if (is_null(MyFlyFunDb::$shared)) {
    MyFlyFunDb::$shared = new MyFlyFunDb();
}
