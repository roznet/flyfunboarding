<?php
include_once('../php/autoload.php');
$config = Config::$shared;
$sql = "SELECT * FROM airports_aip_details d, airports a WHERE a.ident = d.ident AND value IS NOT NULL AND value != '' AND value != 'NIL' AND (field LIKE '%Immigr%' OR alt_field LIKE '%Immigr%') ORDER BY ident";
$dbpath = Config::$shared['airport_db_path'];
$db = new PDO("sqlite:$dbpath");
$countries = $db->prepare($sql);
$countries->execute();
$result = $countries->fetchAll(PDO::FETCH_ASSOC);

$countries = [];
$fields = [];
$alt_fields = [];
foreach ($result as $row) {
    $iso_country = $row['iso_country'];
    $field = $row['field'];
    $value = $row['value'];
    $alt_field = $row['alt_field'];
    $alt_value = $row['alt_value'];
    if (array_key_exists($iso_country,$countries)) {
        $countries[$iso_country] = ['fields' => [$field=>1],
            'alt_fields' => [$alt_field=>1]];
    } else {
        $countries[$iso_country]['fields'][$field] = 1;
        $countries[$iso_country]['alt_fields'][$alt_field] = 1;
    }
}
if (isset($_GET['country'])) {
    $country = $_GET['country'];
} else {
    $country = 'FR';
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
$fields = $countries[$country]['fields'];
$fields = array_keys($fields)[0];
$alt_fields = $countries[$country]['alt_fields'];
if(count(array_keys($alt_fields))){
    $alt_fields = array_keys($alt_fields)[0];
} else {
    $alt_fields = null;
}
foreach ($countries as $c => $f) {
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
foreach ($result as $row) {
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
?>

</body>
