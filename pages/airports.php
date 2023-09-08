<?php
include_once('../php/autoload.php');

class Link {
    private $url;
    private $info;
    private $controller;
    private $which;
    private $where;
    public $franceSpecialCase;
    private
        $whereDefs = [
            'customs' => "%Immigr%",
            'restaurants' => "%Restau%",
            'fuel' => "%Fuel%types",
            'hotels' => "H_tel%",
        ];
    static public $current = null;

    public function __construct()
    {
        $this->url = $_SERVER['REQUEST_URI'];
        $this->info = parse_url($this->url);
        $this->which = 'customs';
        $this->franceSpecialCase = false;

        if (isset($_GET['which'])) {
            $this->which = $_GET['which'];
        }
        if (array_key_exists($this->which,$this->whereDefs)) {
            $this->where = $this->whereDefs[$this->which];
            $this->controller = 'AIPTable';  
            if ($this->which == 'customs' && $this->country() == 'FR') {
                $this->franceSpecialCase = true;
            }
        } else if ($this->which == 'procedures') {
            $this->controller = 'Procedures';
            $this->where = null;
        } else {
            $airport = Airport::isAirport($this->which);
            if ($airport) {
                $this->where = $airport['ident'];
                $this->controller = 'Airport';
            } else {
                $this->controller = null;
                $this->where = null;
            }
        }
    }

    public function country() {
        if (isset($_GET['country'])) {
            return $_GET['country'];
        } else {
            return 'FR';
        }
    }

    public function controller(){
        return $this->controller;
    }

    private function query(){
        $query = $_GET;
        unset($query['which']);
        $query['country'] = $this->country();
        return http_build_query($query);
    }
    public function urlForController($controller){
        $path = $this->info['path'];
        $path = explode('/',$path);
        $path[count($path)-1] = $controller;
        $query = $this->query();
        $path = implode('/',$path);
        return "{$path}?{$query}";
    } 
    public function linkForAirport($ident) {
        $path = $this->info['path'];
        $path = explode('/',$path);
        $path[count($path)-1] = $ident;
        $path = implode('/',$path);
        $query = $this->query();
        return "<a href=\"{$path}?{$query}\">{$ident}</a>";
    }

    public function where(){
        return $this->where;
    }

    public function displaySelectionList(){
        $list = array_keys($this->whereDefs);
        array_push($list,'procedures');

        foreach ($list as $key) {
            if( $key != $this->which ){
                $target = Link::$current->urlForController($key);
                print("<a href=\"$target\">{$key}</a>".PHP_EOL);
            }
            else {
                print("<b>{$key}</b>".PHP_EOL);
            }
        }
    }
    public function displayCountryList($countries) {
        $sortedcountries = array_keys($countries);
        sort($sortedcountries);
        print('<p>Country: '.PHP_EOL); 
        $selected = null;
        if (isset($_GET['country'])) {
            $selected = $_GET['country'];
        }
        foreach ($sortedcountries as $c) {
            if ($c == $selected) {
                print("<b>{$c}</b>".PHP_EOL);
            } else {
                print("<a href=\"?country={$c}\">{$c}</a>".PHP_EOL);
            }
        }
        print('</p>'.PHP_EOL);
    }
    public function displayFilterInput(){
        print('<input type="text" id="filterInput" onkeyup="filterFunction()" placeholder="Search table...">'.PHP_EOL);
    }
}
Link::$current = new Link();

class Procedures {
    public $result;
    public $countries;
    public $country;

    public function __construct()
    {
        $sql = "SELECT * FROM runways r, runways_procedures p, airports a WHERE r.id = p.id AND r.airport_ident = a.ident ORDER BY ident";
        $dbpath = Config::$shared['airport_db_path'];
        $db = new PDO("sqlite:$dbpath");
        $countries = $db->prepare($sql);
        $countries->execute();
        $result = $countries->fetchAll(PDO::FETCH_ASSOC);
        $this->countries = [];
        $this->result = [];
        $this->country = Link::$current->country();
        foreach ($result as $row) {
            $iso_country = $row['iso_country'];
            $this->countries[$iso_country] = 1;
            if($iso_country == $this->country){
                array_push($this->result,$row);
            }
        }
    }
    public function display(){
        $country = $this->country;
        Link::$current->displayCountryList($this->countries);
        if(count($this->result) == 0){
            print("<p>No results for {$this->country}</p>");
            return;
        }
        print('<table class="styled-table">'.PHP_EOL);
        print('<thead>'.PHP_EOL);
        print('<tr>'.PHP_EOL);
        print('<th>ICAO</th>'.PHP_EOL);
        print('<th>Airport</th>'.PHP_EOL);
        print("<th>Runway</th>".PHP_EOL);
        print("<th>Direction</th>".PHP_EOL);
        print("<th>Instrument Procedures</th>".PHP_EOL);
        print('</tr>'.PHP_EOL);
        print('</thead>'.PHP_EOL);
        print('<tbody>'.PHP_EOL);
        foreach ($this->result as $row) {
            if ($row['iso_country'] != $country) {
                continue;
            }
            foreach (["le","he"] as $prefix){
                print('<tr>'.PHP_EOL);
                if ($prefix == "le") {
                    $runway = "{$row['length_ft']}x{$row['width_ft']} {$row['surface']}";
                    print("<td rowspan=2>{$row['ident']}</td>".PHP_EOL);
                    print("<td rowspan=2>{$row['name']}</td>".PHP_EOL);
                    print("<td rowspan=2>{$runway}</td>".PHP_EOL);
                }
                $f_i = "{$prefix}_ident";
                $f_p = "{$prefix}_procedures";

                $runway = "{$row[$f_i]}";
                print("<td>{$runway}</td>".PHP_EOL);
                $json = $row[$f_p];
                $procs = implode('<br>',json_decode($json));
                print("<td>{$procs}</td>".PHP_EOL);
                print('</tr>'.PHP_EOL);
            }
        }
        print('</tbody>'.PHP_EOL);
        print('</table>'.PHP_EOL);
    }
}
class AIPTable {
    public $result;
    public $countries;
    public $country;

    public function __construct() {
        $where = Link::$current->where();
        $sql = "SELECT * FROM airports_aip_details d, airports a WHERE a.ident = d.ident AND value IS NOT NULL AND value != '' AND value != 'NIL' AND (field LIKE '{$where}' OR alt_field LIKE '{$where}') ORDER BY ident";
        $dbpath = Config::$shared['airport_db_path'];
        $db = new PDO("sqlite:$dbpath");
        $res = $db->prepare($sql);
        $res->execute();
        $result = $res->fetchAll(PDO::FETCH_ASSOC);

        $this->countries = [];
        $this->result = [];
        $this->country = Link::$current->country();
        foreach ($result as $row) {
            $iso_country = $row['iso_country'];
            $field = $row['field'];
            $alt_field = $row['alt_field'];
            if (array_key_exists($iso_country,$this->countries)) {
                $this->countries[$iso_country] = ['fields' => [$field=>1],
                    'alt_fields' => [$alt_field=>1]];
            } else {
                $this->countries[$iso_country]['fields'][$field] = 1;
                $this->countries[$iso_country]['alt_fields'][$alt_field] = 1;
            }
            if($iso_country == $this->country){
                array_push($this->result,$row);
            }
        }
        if( Link::$current->franceSpecialCase ){
            $sql = "SELECT * FROM frppf ";
            $res = $db->prepare($sql);
            $res->execute();
            $result = $res->fetchAll(PDO::FETCH_ASSOC);
            $ppf = []; 
            foreach ($result as $row) {
                $ppf[$row['ident']] = $row;
            }
            $rv = [];
            foreach ($this->result as $row) {
                $ident = $row['ident'];
                if(array_key_exists($ident,$ppf)){
                    array_push($rv,$row);
                }
            }
            usort($rv, function($a, $b) use ($ppf) {
                $ra = $ppf[$a['ident']]['rank'];
                $rb = $ppf[$b['ident']]['rank'];
                return $ra - $rb;
            });
            $this->result = $rv;
        }
    }
    function display() {
        $country = $this->country;
        Link::$current->displayCountryList($this->countries);
        Link::$current->displayFilterInput();
        if(count($this->result) == 0){
            print("<p>No results for {$country}</p>");
            return;
        }
        $fields = $this->countries[$country]['fields'];
        $fields = array_keys($fields)[0];
        $alt_fields = $this->countries[$country]['alt_fields'];
        if(count(array_keys($alt_fields))){
            $alt_fields = array_keys($alt_fields)[0];
        } else {
            $alt_fields = null;
        }
        print('</p>'.PHP_EOL);
        print('<table class="styled-table" id="displayTable">'.PHP_EOL);
        print('<thead>'.PHP_EOL);
        print('<tr>'.PHP_EOL);
        print('<th>ICAO</th>'.PHP_EOL);
        print('<th>Airport</th>'.PHP_EOL);
        print("<th>{$fields}</th>".PHP_EOL);
        if( $alt_fields ){
            print("<th>{$alt_fields}</th>".PHP_EOL);
        }
        print('</tr>'.PHP_EOL);
        print('</thead>'.PHP_EOL);
        print('<tbody>'.PHP_EOL);
        foreach ($this->result as $row) {
            if ($row['iso_country'] != $country) {
                continue;
            }
            $airportLink = Link::$current->linkForAirport($row['ident']);
            print('<tr>'.PHP_EOL);
            print("<td>{$airportLink}</td>".PHP_EOL);
            print("<td>{$row['name']}</td>".PHP_EOL);
            print("<td>{$row['value']}</td>".PHP_EOL);
            if( $alt_fields ){
                print("<td>{$row['alt_value']}</td>".PHP_EOL);
            }
            print('</tr>'.PHP_EOL);
        }
        print('</tbody>'.PHP_EOL);
        print('</table>'.PHP_EOL);
    }
}

class Airport {
    private $result;
    public $ident;
    function __construct() {
        $ident = Link::$current->where();
        if (!Airport::validAirport($ident)){
            throw new Exception("Invalid airport identifier: {$ident}");
        }
        $dbpath = Config::$shared['airport_db_path'];
        $db = new PDO("sqlite:$dbpath");
        $sql = "SELECT * FROM airports WHERE ident = '{$ident}'";
        $airport = $db->prepare($sql);
        $airport->execute();
        $result = $airport->fetchAll(PDO::FETCH_ASSOC);
        $this->result = $result[0];
        $this->ident = $ident;
    }
    function display(){
        print('<table class="styled-table">'.PHP_EOL);
        print('<thead>'.PHP_EOL);
        print('<tr>'.PHP_EOL);
        print('<th>Field</th>'.PHP_EOL);
        print('<th>Value</th>'.PHP_EOL);
        print('</tr>'.PHP_EOL);
        print('</thead>'.PHP_EOL);
    
        print('<tbody>'.PHP_EOL);
        $skip = ['id','ident','latitude_deg','longitude_deg','elevation_ft'];

        foreach($this->result as $key => $value){
            if(in_array($key,$skip)){
                continue;
            }
            print('<tr>'.PHP_EOL);
            print("<td>{$key}</td>".PHP_EOL);
            if(str_starts_with($value,'http')){
                $value = "<a href=\"{$value}\">{$value}</a>";
            }
            print("<td>{$value}</td>".PHP_EOL);
            print('</tr>'.PHP_EOL);
        }
        print('</tbody>'.PHP_EOL);
        print('</table>'.PHP_EOL);

        print('<pre>');
        print('</pre>');
    }

    static function validAirport($which){
        if (preg_match('/^[A-Z0-9]{4}$/',strtoupper($which))){
            return true;
        } else {
            return false;
        }
    }

    static function isAirport($which){
        if (Airport::validAirport($which)){
            $dbpath = Config::$shared['airport_db_path'];
            $ident = strtoupper($which);
            $db = new PDO("sqlite:$dbpath");
            $sql = "SELECT * FROM airports WHERE ident = '{$ident}'";
            $airport = $db->prepare($sql);
            $airport->execute();
            $result = $airport->fetchAll(PDO::FETCH_ASSOC);
            if(count($result)){
                return $result[0];
            }
            return null;
        } else {
            return null;
        }
    }
}

?>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Airports</title>
    <link rel="stylesheet" href="css/style.css">
</head>
<script>
function filterFunction() {
  var input, filter, table, tr, td, i, txtValue;
  input = document.getElementById("filterInput");
  filter = input.value.toUpperCase();
  table = document.getElementById("displayTable");
  tr = table.getElementsByTagName("tr");

  // Loop through all table rows, and hide those who don't match the search query
  for (i = 0; i < tr.length; i++) {
      found = false;
      for(j = 0; j < tr[i].getElementsByTagName("td").length; j++){
          td = tr[i].getElementsByTagName("td")[j];
          if (td) {
              txtValue = td.textContent || td.innerText;
              if (txtValue.toUpperCase().indexOf(filter) > -1) {
                  found = true;
              }
          }
      }
    if (found) {
        tr[i].style.display = "";
      } else {
        tr[i].style.display = "none";
      }
  }
}
</script>
<style>
p {
    font-family: sans-serif;
    font-size: 0.9em;
}
.styled-table {
    border-collapse: collapse;
    margin: 25px 0;
    font-size: 0.9em;
    font-family: sans-serif;
    min-width: 400px;
    box-shadow: 0 0 20px rgba(0, 0, 0, 0.15);
}
.styled-table thead tr {
    background-color: #009879;
    color: #ffffff;
    text-align: left;
}
.styled-table th,
.styled-table td {
    padding: 12px 15px;
}
.styled-table tbody tr {
    border-bottom: 1px solid #dddddd;
}

.styled-table tbody tr:nth-of-type(even) {
    background-color: #f3f3f3;
}

.styled-table tbody tr:last-of-type {
    border-bottom: 2px solid #009879;
}

filterInput {
    font-size: 0.9em;
    font-family: sans-serif;
    min-width: 400px;
    box-shadow: 0 0 20px rgba(0, 0, 0, 0.15);
}
</style>
<body>
<h3>Information from AIPs</h3>
<pre>
<?php
#print_r(Link::$current);
?>
</pre>
<?php
$controller = Link::$current->controller();
print("<p>Field: ");
Link::$current->displaySelectionList();
print("</p>");
if ($controller == 'AIPTable') {
    $custom = new AIPTable();
    $custom->display();
}else if ($controller == 'Procedures'){
    $procedures = new Procedures();
    $procedures->display();
}else if ($controller == 'Airport'){
    $airport = Link::$current->where();
    if( Airport::isAirport($airport)){
        $airport = new Airport();
        $airport->display();
    }
}
?>

</body>
