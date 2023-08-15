<?php
include_once('../php/autoload.php');


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
        $this->result = $countries->fetchAll(PDO::FETCH_ASSOC);
        $this->countries = [];
        
        foreach ($this->result as $row) {
            $iso_country = $row['iso_country'];
            $this->countries[$iso_country] = 1;
        }
        if (isset($_GET['country'])) {
            $this->country = $_GET['country'];
        } else {
            $this->country = 'FR';
        }
    }
    public function display(){
        $country = $this->country;
        $sortedcountries = array_keys($this->countries);
        sort($sortedcountries);
        foreach ($sortedcountries as $c) {
            print("<a href=\"?country={$c}\">{$c}</a>".PHP_EOL);
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
class Custom {
    public $result;
    public $countries;
    public $country;

    public function __construct($where = "%Immigr%") {
        $sql = "SELECT * FROM airports_aip_details d, airports a WHERE a.ident = d.ident AND value IS NOT NULL AND value != '' AND value != 'NIL' AND (field LIKE '{$where}' OR alt_field LIKE '{$where}') ORDER BY ident";
        $dbpath = Config::$shared['airport_db_path'];
        $db = new PDO("sqlite:$dbpath");
        $countries = $db->prepare($sql);
        $countries->execute();
        $this->result = $countries->fetchAll(PDO::FETCH_ASSOC);

        $this->countries = [];
        foreach ($this->result as $row) {
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
        }
        if (isset($_GET['country'])) {
            $this->country = $_GET['country'];
        } else {
            $this->country = 'FR';
        }
    }
    function display() {
        $country = $this->country;
        $fields = $this->countries[$country]['fields'];
        $fields = array_keys($fields)[0];
        $alt_fields = $this->countries[$country]['alt_fields'];
        if(count(array_keys($alt_fields))){
            $alt_fields = array_keys($alt_fields)[0];
        } else {
            $alt_fields = null;
        }
        $sortedcountries = array_keys($this->countries);
        sort($sortedcountries);
        foreach ($sortedcountries as $c) {
            print("<a href=\"?country={$c}\">{$c}</a>".PHP_EOL);
        }
        print('<table class="styled-table">'.PHP_EOL);
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
            print('<tr>'.PHP_EOL);
            print("<td>{$row['ident']}</td>".PHP_EOL);
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

?>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Airports</title>
    <link rel="stylesheet" href="css/style.css">
</head>
<style>
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
</style>
<body>
<pre>
<?php
#print_r($countries[$country]);
#print_r($result[0]);
?>
</pre>
<?php
if (isset($_GET['which'])) {
    $which = $_GET['which'];
} else {
    $which = 'customs';
}
$whereDefs = [
    'customs' => "%Immigr%",
    'restaurants' => "%Restau%",
    'fuel' => "%Fuel%types",
    'hotels' => "H_tel%",
    'procedures' => null,
];
if (array_key_exists($which,$whereDefs)) {
    $where = $whereDefs[$which];
} else {
    $where = null;
}
$url = $_SERVER['REQUEST_URI'];
print("<p>");
foreach ($whereDefs as $key => $value) {
    if( $key != $which ){
        $target = str_replace("/{$which}?","/{$key}?",$url);
    }
    else {
        $target = $url;
    }
    print("<a href=\"$target\">{$key}</a>".PHP_EOL);
}
print("</p>");
if ($where) {
    $custom = new Custom($where);
    $custom->display();
}else if ($which == 'procedures'){
    $procedures = new Procedures();
    $procedures->display();
}
?>

</body>
