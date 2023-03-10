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
    public $airline_id = -1;

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
    static $standardTables = [
            "Flights" => [ "link" => [ "Aircrafts" ] ],
            "Passengers" => [],
            "Tickets" => [ "link" => [ "Passengers", "Flights" ] ],
            "Aircrafts" => []
    ];

    private function tableToId($table) {
        return substr(strtolower($table), 0, -1) . '_id';
    }
    private function tableToIdentifier($table) {
        return substr(strtolower($table), 0, -1) . '_identifier';
    }
    private function tableToClass($table) {
        return ucfirst(substr($table, 0, -1));
    }

    public function dropTables(){
        $tables = MyFlyFunDb::$standardTables;

        foreach (array_keys($tables) as $table ) {
            mysqli_query($this->db, "DROP TABLE IF EXISTS $table");
        }

        mysqli_query($this->db, "DROP TABLE IF EXISTS Airlines");
    }

    public function createTableIfNecessary() {
        // refactor current function to create tables from an array of string of queries
        $queries = [];
        $queries = [ "CREATE TABLE IF NOT EXISTS Airlines (airline_id INT NOT NULL AUTO_INCREMENT, json_data JSON, apple_identifier VARCHAR(1024), PRIMARY KEY (airline_id))" ];
        foreach (MyFlyFunDb::$standardTables as $table => $tableInfo) {
            // generate id name: lowercase table name without the last character if it's an s
            $table_id =  $this->tableToId($table);
            $identifier = $this->tableToIdentifier($table);
            $links = [];
            if (isset($tableInfo['link'])) {
                $links = $tableInfo['link'];
            }
            $columns = [ $table_id . " INT NOT NULL AUTO_INCREMENT", $identifier . " VARCHAR(255) UNIQUE" ];
            foreach( $links as $link ) {
                $link_id = $this->tableToId($link);
                $columns[] = $link_id . " INT NOT NULL";
            }
            $columns[] = "json_data JSON";
            $columns[] = "airline_id INT NOT NULL";
            $columns[] = "PRIMARY KEY ({$table_id})" ;
            $columns[] = "FOREIGN KEY (airline_id) REFERENCES Airlines(airline_id)";
            $queries[] = "CREATE TABLE IF NOT EXISTS $table (" . implode(", ", $columns) . ")";
        }

        foreach ($queries as $query) {
            echo $query . PHP_EOL;
            mysqli_query($this->db, $query);
            if (mysqli_errno($this->db)) {
                die("Error creating table: " . mysqli_error($this->db));
            }
        }
    }

    private function validateAirline() {
        if( $this->airline_id == -1 ) {
            die("Airline not set");
        }
    }
    private function uniqueIdentifier(string $identifier) : string {
        return $this->airline_id . '.' . $identifier;
    }
    private function createOrUpdate($table, $object) {
        $this->validateAirline();
        $json = json_encode($object->toJson());

        $table_id = $this->tableToId($table);
        $identifier = $this->tableToIdentifier($table);
    
        $tableInfo = MyFlyFunDb::$standardTables[$table];
        $links = [];
        if (isset($tableInfo['link'])) {
            $links = $tableInfo['link'];
        }

        $types =  ['si'];
        $values = [$json, $this->airline_id];
        $cols = ['json_data','airline_id'];

        foreach( $links as $link ) {
            $link_id = $this->tableToId($link);
            $types[] = "i";
            $values[] = $object->$link_id;
            $cols[] = $link_id;
        }
        
        if( $object->$table_id == MyFlyFunDb::MISSING_ID ) {
            foreach ($object->uniqueIdentifier() as $key => $value) {
                if( $key == $identifier ) {
                    $types[] = "s";
                    $values[] = $this->uniqueIdentifier($value);
                    $cols[] = $key;
                }
            }

            $sql = "INSERT INTO $table (" . implode(", ", $cols) . ") VALUES (" . implode(", ", array_fill(0, count($cols), "?")) . ") ON DUPLICATE KEY UPDATE json_data = VALUES(json_data)";
            $stmt = mysqli_prepare($this->db, $sql);
            $stmt->bind_param(implode("", $types), ...$values);
            $stmt->execute();
            $object->$table_id = mysqli_insert_id($this->db);
        }else{
            $types[] = "i";
            $values[] = $object->$table_id;

            $sql = "UPDATE $table SET " . implode(", ", array_map(function($col) { return $col . " = ?"; }, $cols)) . " WHERE $table_id = ?";
            $stmt = mysqli_prepare($this->db, $sql);
            $stmt->bind_param(implode("", $types), ...$values);
            $stmt->execute();
        }
        
        if (mysqli_errno($this->db)) {
            http_response_code(500);
            die("Error creating table: " . mysqli_error($this->db));
        }
        return $object;
    }

    private function addLinks($table, $object, $row) {
        $tableInfo = MyFlyFunDb::$standardTables[$table];
        if (isset($tableInfo['link'])) {
            foreach ($tableInfo['link'] as $link) {
                $link_id = $this->tableToId($link);
                $object->$link_id = $row[$link_id];
            }
        }
    }

    private function list($table, $where = []) : array {
        $this->validateAirline();
        $sql = "SELECT * FROM $table";
        $clause = [ 'airline_id = ' . $this->airline_id];
        if( count($where) > 0 ) {
            foreach( $where as $key => $value ) {
                $clause[] = $key . ' = ' . $value;
            }
        }
        $sql .= ' WHERE ' . implode(' AND ', $clause);

        $result = mysqli_query($this->db, $sql);
        $objects = [];
        while ($row = mysqli_fetch_assoc($result)) {
            $json = json_decode($row['json_data'], true);
            $object = JsonHelper::fromJson($json, $this->tableToClass($table));
            $tableId = $this->tableToId($table);
            $object->$tableId = $row[$tableId];
            $this->addLinks($table, $object, $row);
            $objects[] = $object->toJson();
        }
        return $objects;
    }

    private function get($table,$id,$returnJson) {
        $this->validateAirline();
        $stmt = mysqli_prepare($this->db, "SELECT * FROM $table WHERE " . $this->tableToId($table) . " = ? AND airline_id = ?" );
        $stmt->bind_param("ii", $id, $this->airline_id);
        $stmt->execute();
        $result = $stmt->get_result();
        if ($result->num_rows == 0) {
            return null;
        }
        $row = $result->fetch_assoc();
        $json = json_decode($row['json_data'], true);
        $object = JsonHelper::fromJson($json, $this->tableToClass($table));
        $tableId = $this->tableToId($table);
        $object->$tableId = $row[$tableId];
        $this->addLinks($table, $object, $row);
        if( $returnJson ) {
            return $object->toJson();
        }else{
            return $object;
        }
    }

    // Airlines
    // creation and update of airline is special because we need to check for existing airline on the apple_identifier
    public function createOrUpdateAirline($json) {
        $airline = JsonHelper::fromJson($json, Airline::class);
        $existing = $this->getAirlineByAppleIdentifier($airline->apple_identifier);
        if( $existing != null ) {
            $airline->airline_id = $existing->airline_id;
            $sql = 'UPDATE Airlines SET json_data = ? WHERE airline_id = ?';
            $stmt = mysqli_prepare($this->db, $sql);
            $json_str = json_encode($json);
            $stmt->bind_param("si", $json_str, $airline->airline_id);
            $stmt->execute();
            return $airline;
        }else{
            $sql = 'INSERT INTO Airlines (apple_identifier, json_data) VALUES (?, ?) ON DUPLICATE KEY UPDATE json_data = VALUES(json_data)';
            $stmt = mysqli_prepare($this->db, $sql);
            $json_str = json_encode($json);
            $stmt->bind_param("ss", $airline->apple_identifier, $json_str);
            $stmt->execute();
            $airline->airline_id = mysqli_insert_id($this->db);
            return $airline;
        }
    }

    public function getAirlineByAppleIdentifier($apple_identifier){
        $sql = "SELECT * FROM Airlines WHERE apple_identifier = ?";
        $stmt = mysqli_prepare($this->db, $sql);
        $stmt->bind_param("s", $apple_identifier);
        $stmt->execute();
        $result = $stmt->get_result();
        if ($result->num_rows == 0) {
            return null;
        }
        $row = $result->fetch_assoc();
        $object = JsonHelper::fromJson(json_decode($row['json_data'], true), Airline::class);
        $object->airline_id = $row['airline_id'];
        return $object;
    }
    public function getAirline($airline_id){
        $sql = "SELECT * FROM Airlines WHERE airline_id = ?";
        $stmt = mysqli_prepare($this->db, $sql);
        $stmt->bind_param("i", $airline_id);
        $stmt->execute();
        $result = $stmt->get_result();
        if ($result->num_rows == 0) {
            return null;
        }
        $row = $result->fetch_assoc();
        $object = JsonHelper::fromJson(json_decode($row['json_data'], true), Airline::class);
        $object->airline_id = $row['airline_id'];
        return $object;
    }

    // Aircrafts
    //
    public function createOrUpdateAircraft(Aircraft $aircraft) {
        return $this->createOrUpdate("Aircrafts", $aircraft);
    }
    public function listAircrafts() : array {
        return $this->list("Aircrafts");
    }
    public function getAircraft($aircraft_id, $returnJson = true) {
        return $this->get("Aircrafts", $aircraft_id, $returnJson);
    }

    // Passengers
    public function createOrUpdatePassenger(Passenger $passenger) {
        return $this->createOrUpdate("Passengers", $passenger);
    }

    public function listPassengers() : array {
        return $this->list("Passengers");
    }

    public function getPassenger($passsenger_id, $json = true) {
        return $this->get("Passengers", $passsenger_id, $json);
    }

    // Flights
    public function createOrUpdateFlight(Flight $flight) {
        return $this->createOrUpdate("Flights", $flight);
    }

    public function listFlights(int $aircraft_id = -1) : array {
        if( $aircraft_id != -1 ) {
            return $this->list("Flights", ["aircraft_id" => $aircraft_id]);
        }
        return $this->list("Flights");
    }

    public function getFlight($flight_id, $json = true) {
        return $this->get("Flights", $flight_id, $json);
    }

    // Tickets
    public function createOrUpdateTicket(Ticket $ticket) {
        return $this->createOrUpdate("Tickets", $ticket);
    }

    public function getTicket($ticket_id, $json = true) {
        return $this->get("Tickets", $ticket_id, $json);
    }

    public function listTickets($flight_id = -1) {
        if( $flight_id != -1 ) {
            return $this->list("Tickets", ["flight_id" => $flight_id]);
        }
        return $this->list("Tickets");
    }

}
if (is_null(MyFlyFunDb::$shared)) {
    MyFlyFunDb::$shared = new MyFlyFunDb();
}
