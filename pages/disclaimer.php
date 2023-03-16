<?php
// Array with language codes corresponding to the country codes

$languages_codes = array(
    'en' => ['US','GB','AU','CA','NZ'],
    'fr' => ['FR','BE','CA','CH','LU','MC','SN','TD','TG','TN','YT']
);

function language_has_disclaimer($language){
    if( file_exists("disclaimer_{$language}.html") ){
        return true;
    }
    return false;
}
// get language based on users choice or IP address
function get_chosen_language($languages_codes,$default_language='en'){


    if(isset($_GET['lang'])){
        $lang = $_GET['lang'];
    }else{
        $lang = substr($_SERVER['HTTP_ACCEPT_LANGUAGE'], 0, 2);
    }
    if(language_has_disclaimer($lang)){
        return $lang;
    }
    // get country code for the current IP address using ipwhois
    $ip = $_SERVER['REMOTE_ADDR'];
    $ipwhois = json_decode(file_get_contents("http://ipwho.is/{$ip}"));
    if(isset($ipwhois->country_code)){
        $country = $ipwhois->country_code;


        // check if the country code is in the array
        foreach($languages_codes as $key => $value){
            if(in_array($country,$value)){
                return $key;
            }
        }
    }
    return $default_language;
}

$chosen_language = get_chosen_language($languages_codes);

$disclaimer_file = "disclaimer_{$chosen_language}.html";
?>

<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Humorous Disclaimers</title>
<style>
body {
  font-family: Arial, sans-serif;
  line-height: 1.6;
  margin: 20px;
}

.disclaimer {
  background-color: #f1f1f1;
  border-radius: 5px;
  padding: 20px;
  margin-bottom: 20px;
}
.category {
    font-weight: bold;
}
.language-switcher {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 20px;
}

.language-switcher .logo {
    width: 100px;
    margin-right: 20px;
}
.language-buttons a {
    background-color: #f1f1f1;
    border-radius: 5px;
    padding: 10px;
    margin: 0 10px;
    text-decoration: none;
    color: #000;
}

.language-buttons a:hover {
    background-color: #ddd;
}

.logo-text {
    font-size: 2rem;
    font-weight: bold;
}

.logo-container {
    display: flex;
    align-items: center;
}

h2 {
  margin-bottom: 10px;
}

</style>
</head>
<body>

<div class="language-switcher">
    <div class="logo-container">
    <img src="../images/logo.png" alt="logo" width="100">
    <span class="logo-text">Fly Fun</span>
    </div>
    <div class="language-buttons">
        <a href="?lang=en">English</a>
        <a href="?lang=fr">Français</a>
    </div>
</div>

<div class="disclaimer">
<?php
if( file_exists($disclaimer_file) ){
    include($disclaimer_file);
}else{
    echo "No disclaimer available for this language {$chosen_language} {$disclaimer_file}.";
}
?>

</div>
