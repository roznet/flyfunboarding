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
        mysqli_query($this->db, "DROP TABLE IF EXISTS Flights");
        mysqli_query($this->db, "DROP TABLE IF EXISTS Passengers");
        mysqli_query($this->db, "DROP TABLE IF EXISTS Tickets");
        mysqli_query($this->db, "DROP TABLE IF EXISTS BoardingPasses");
        mysqli_query($this->db, "DROP TABLE IF EXISTS Aircrafts");
    }

    public function createTableIfNecessary() {
        // create flight table and check error
        mysqli_query($this->db, "CREATE TABLE IF NOT EXISTS Flights (flight_id INT NOT NULL AUTO_INCREMENT, aircraft_id INT NOT NULL, json_data JSON, PRIMARY KEY (flight_id))");
        if (mysqli_errno($this->db)) {
            die("Error creating Flights table: " . mysqli_error($this->db));
        }

        // create passenger table and check error
        mysqli_query($this->db, "CREATE TABLE IF NOT EXISTS Passengers (passenger_id INT NOT NULL AUTO_INCREMENT, json_data JSON, PRIMARY KEY (passenger_id))");
        if (mysqli_errno($this->db)) {
            die("Error creating Passengers table: " . mysqli_error($this->db));
        }

        // create ticket table and check error
        mysqli_query($this->db, "CREATE TABLE IF NOT EXISTS Tickets (ticket_id INT NOT NULL AUTO_INCREMENT, passenger_id INT NOT NULL, flight_id INT NOT NULL, seat VARCHAR(10), PRIMARY KEY (ticket_id))");
        if (mysqli_errno($this->db)) {
            die("Error creating Tickets table: " . mysqli_error($this->db));
        }

        // create aircraft table and check error
        mysqli_query($this->db, "CREATE TABLE IF NOT EXISTS Aircrafts (aircraft_id INT NOT NULL AUTO_INCREMENT, registration VARCHAR(32) UNIQUE, json_data JSON, PRIMARY KEY (aircraft_id))");
        if (mysqli_errno($this->db)) {
            die("Error creating Aircrafts table: " . mysqli_error($this->db));
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

    // Passengers
    public function createOrUpdatePassenger(Passenger $passenger) {
        $json = json_encode($passenger->toJson());
        $stmt = mysqli_prepare($this->db, "INSERT INTO Passengers (passenger_id, json_data) VALUES (?, ?) ON DUPLICATE KEY UPDATE json_data = VALUES(json_data)");
        $stmt->bind_param("is", $passenger->passenger_id, $json);
        $stmt->execute();
    }

}
if (is_null(MyFlyFunDb::$shared)) {
    MyFlyFunDb::$shared = new MyFlyFunDb();
}
