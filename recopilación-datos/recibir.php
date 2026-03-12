<?php

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    die("Metodo no permitido");
}

$companyRaw = $_POST['company'] ?? "empresa";

$companySafe = preg_replace('/[^a-zA-Z0-9_-]/','_', strtolower(trim($companyRaw)));

if(empty($companySafe)){
    die("Empresa invalida");
}

$services = $_POST['services'] ?? [];

$pillar = [];

$pillar['empresa'] = $companyRaw;

if(in_array("wireguard",$services)){
    $pillar['wireguard'] = $_POST['wireguard'];
}

if(in_array("firewall",$services)){
    $pillar['firewall'] = $_POST['firewall'];
}

if(in_array("dhcp",$services)){

    $dhcp = $_POST['dhcp'];

    $dhcp['log'] = isset($dhcp['log']);

    if(!empty($_POST['dhcp']['gateway'])){
        $dhcp['options']['gateway'] = array_map(
            'trim',
            explode(',',$_POST['dhcp']['gateway'])
        );
    }

    if(!empty($_POST['dhcp']['dns'])){
        $dhcp['options']['dns'] = array_map(
            'trim',
            explode(',',$_POST['dhcp']['dns'])
        );
    }

    unset($dhcp['gateway']);
    unset($dhcp['dns']);

    $pillar['dhcp']=$dhcp;
}

if(in_array("web",$services)){
    $pillar['web-server']=$_POST['web'];
}

if(in_array("pkica",$services)){
    $pillar['pkica']=$_POST['pkica'];
}



function arrayToYaml($data,$indent=0){

    $yaml="";
    $prefix=str_repeat("  ",$indent);

    foreach($data as $key=>$value){

        if(is_array($value)){

            $isList = array_keys($value)===range(0,count($value)-1);

            if($isList){

                $yaml.=$prefix.$key.":\n";

                foreach($value as $item){
                    $yaml.=$prefix."  - ".$item."\n";
                }

            }else{

                $yaml.=$prefix.$key.":\n";
                $yaml.=arrayToYaml($value,$indent+1);

            }

        }else{

            if(is_bool($value)){
                $value=$value?'true':'false';
            }

            $yaml.=$prefix.$key.": ".$value."\n";

        }
    }

    return $yaml;
}


$yaml=arrayToYaml($pillar);

$directory="/srv/pillar/customers";

$filepath=$directory."/".$companySafe.".sls";

if(file_put_contents($filepath,$yaml)!==false){

    echo "<h2>Pillar creado correctamente</h2>";
    echo "<pre>".$yaml."</pre>";

}else{

    echo "Error al guardar el archivo";

}
