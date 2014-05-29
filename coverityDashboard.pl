#!/usr/bin/perl

use CGI;

$FUSION_CHARTS_URL = "http://adp.ca.tellabs.com/FusionCharts_Intranet";

$q = new CGI;

print $q->header;

our $Release = $q->param('Release') || $ARGV[0];

if( $Release eq "" )
{
    $Release = "1.0";
}

print $q->start_html ( -title => "9200 $Release Coverity Dashboard");

our %mgrCountHash = ();
our %mgrListHash = ();
our %mgrString = ();
our %mgrChartHash = ();
our %empHash = ();

my @tmpF = `ls -tr /data/scripts/coveritycharts/$Release/coverity.dump.all*`;

my $trendDir = "/data/scripts/coveritycharts/$Release"."_trend/coverity.dump.all*";
my @tmpF1 = glob("$trendDir");

my @tmp = ();

my $i = 0;

my $index = 0;

foreach( @tmpF )
{

    my $file = $_;

    chomp($file);

    if( $file =~ /07-19-12/ )
    {
        $index = $i;
    }

    $i++;
}

my $len = $#tmpF - $index;

my @tmpF2 = splice(@tmpF, $index, $len + 1 ); 

##push(@tmp, @tmpF1);

push(@tmp, @tmpF2);

our @Patterns3rdparty = ( "/vob/9200/software/3rdparty",
"/vob/9200_packetcore/packetcore/nsm/routing/metaswitch/TSM",
"/vob/9200_packetcore/packetcore/nsm/climap",
"/vob/9200_packetcore/packetcore/infra/yang/routing/climap",
"/vob/9200/software/common/infra/transemu",
"/vob/9200/software/common/infra/confd_passwd",
"/vob/9200/software/common/debugshell/lib/perl5",
"/vob/9200/software/common/debugshell/lib/lib64/perl5",
"/vob/9200/software/common/debugshell/lib64/perl5",
"/vob/9200/software/common/timing/zarlink",
"/vob/9200/software/common/drivers/ELC/NP4/EZdriver",
"/vob/9200/software/common/drivers/ELC/NP4/np4ucode",
"/vob/9200/software/common/drivers/ELC/NP4/utils",
"/vob/9200/software/common/drivers/ELC/Octeon/u-boot",
"/vob/9200/software/common/drivers/ELC/Octeon/ContentMgmt/nb-fxp",
"/vob/9200/software/common/drivers/ELC/Octeon/ContentMgmt/firehawk",
"/vob/9200/software/common/drivers/ELC/pcf",
"/vob/9200/software/common/drivers/ELC/zli2c/i2c.c",
"/vob/9200/software/common/drivers/SXC/bnx2x",
"/vob/9200/software/common/drivers/SXC/fe600/fe600_6.8",
"/vob/9200/software/common/drivers/SXC/petra/petra_b_7.0",
"/vob/9200/software/common/drivers/SXC/plx",
"/vob/9200/software/common/drivers/SXC/zl",
"/vob/9200/software/common/drivers/common/bnx2",
"/vob/9200_packetcore/packetcore/infra/tail-f/confD3",
"/vob/9200_packetcore/packetcore/infra/tail-f/src",
"/vob/9200_packetcore/packetcore/mgbl/sqlite",
"/vob/9200_packetcore/packetcore/nsm/routing/metaswitch",
"/vob/9200_dist/dist/ipnet-6.7",
"/vob/9200_dist/dist/layers/drivers/dist/intel_igb/intel_igb",
"/vob/9200_syshw/syshw/development/drivers",
);

our $chartDataRef = Get_Charts_Data(\@tmp);

our $chartWidth = scalar(@{ $chartDataRef } ) * 20;

our $XML_StringCoverity = Get_XML_String_For_Charts($chartDataRef);

our $XML_StringCoverityPie = Get_XML_String_For_ChartsPie($chartDataRef);

&Get_Manager_List();

our $Summary_Table = Get_Summary_Table(\%mgrCountHash);

print <<EOF;

        <head>
                <title> 9200 $Release Coverity Dashboard </title>

                <script type="text/javascript" src="$FUSION_CHARTS_URL/Charts/FusionCharts.js">

                </script>
                <script language="javascript" type="text/javascript"> 
                <!--

                function popitup(mgrName) {

                    var myArray = {
EOF
                    foreach(keys %mgrString )
                    {
                         print "$_:\'$mgrString{$_}\',\n";
                    }
                     
print <<EOF;
                    }
EOF
print <<EOF;
                    var myArrayMgr = {
EOF
                    foreach(keys %mgrChartHash )
                    {
                         my $XML_String = Get_XML_String_For_ChartsMgr($mgrChartHash{$_},$_);
                         print "$_:$XML_String,\n";
                    }

print <<EOF;
                    }
                    newwindow2=window.open('','name2','height=500,width=800,scrollbars=yes');
                    var tmp = newwindow2.document;
                    tmp.write('<html>');
                    tmp.write('<link href="http://adp.ca.tellabs.com/webdocs/jswidgets/xloadtree/local/webfxlayout.css" rel="stylesheet" rev="stylesheet" type="text/css" media="screen" />');
                    tmp.write('<link href="http://adp.ca.tellabs.com/webdocs/coveritycharts.css/popup.css" rel="stylesheet" type="text/css">');
                    tmp.write('<head><title>Open Coverity Defects:' + mgrName + '</title>');
                    tmp.write('<script type="text/javascript" src="$FUSION_CHARTS_URL/Charts/FusionCharts.js">');

                    tmp.write('</script>');
                    tmp.write('</head><body>');

                    tmp.write('<h4>Open High Impact Coverity Defects By Engineer:' + mgrName + '</h4>');
                    tmp.write('<table border=0 class="sofT" cellpadding=3 cellspacing=0 width="80%">');
                    tmp.write('<tr>');
                    tmp.write('<th class=helpHed bgcolor=yellow>Engineer</th>');
                    tmp.write('<th class=helpHed bgcolor=yellow>Open High Impact Defect Count</th>');
                    tmp.write('<th class=helpHed bgcolor=yellow>Coverity Defects Link</th>');
                    tmp.write('</tr>');
                    tmp.write(myArray[mgrName]); 
                    tmp.write('<table border=0 width=90%>');
                    tmp.write('<tr><td>');
                    tmp.write('<div style="width:800px;height:500px" id="chartContainerCoverityMgr"> Loading Execution Data... </div>');
                    tmp.write('<script type="text/javascript">');


                    tmp.write('var myChartCoverityMgr = new FusionCharts ( "$FUSION_CHARTS_URL/Charts/MSLine.swf", "myCoverityChartIdMgr", "800", "400", "0", "1");');
                    tmp.write('myChartCoverityMgr.setXMLData(' + myArrayMgr[mgrName] + ');');


                    tmp.write('myChartCoverityMgr.render("chartContainerCoverityMgr");');


                    tmp.write('</script>');
                    tmp.write('</td></tr></table>');
                    tmp.write('</body></html>');
                    tmp.close();
                    if (window.focus) {newwindow2.focus()}
                    return false;
                 }
                 // -->
                 </script>

        </head>

<body>
        <div >
        <small><u><i> Right Click on Chart to Save </i></u></small>
        </div>
        <table border=0 width=90%>

        <tr>
        <td>
        <div style="width:45%;min-width:600px" id="chartContainerCoverityPie"> Loading Execution Data... </div>

        <script type="text/javascript">


                var myChartCoverityPie = new FusionCharts ( "$FUSION_CHARTS_URL/Charts/Pie3D.swf",
                                                        "myCoverityChartIdPie", "600", "600", "0", "1");
                myChartCoverityPie.setXMLData($XML_StringCoverityPie);


                myChartCoverityPie.render("chartContainerCoverityPie");


        </script>
        </td>
        <td>
        <div style="width:45%;min-width:700px" id="chartContainerCoverity"> Loading Execution Data... </div>

        <script type="text/javascript">


                var myChartCoverity = new FusionCharts ( "$FUSION_CHARTS_URL/Charts/StackedColumn2DLine.swf",
                                                        "myCoverityChartId", "$chartWidth", "500", "0", "1");
                myChartCoverity.setXMLData($XML_StringCoverity);


                myChartCoverity.render("chartContainerCoverity");


        </script>
        </td>
        </tr>
        <tr><div>$Summary_Table</div></tr>
        </body>

</html>

EOF

sub Get_Charts_Data { 

        my $dataref = shift;

        my @dateList = ();

        my $k = 0;

        my $dataDir = "/data/scripts/coveritycharts/$Release/*data";
        my @dataFiles = glob("$dataDir");

        foreach(@dataFiles)
        {
            my $dataFile = $_;

            my $mgrName = $dataFile;

            $mgrName =~ s/\.data//g;

            my @mgrList = split(/\//,$mgrName);

            $mgrName = pop(@mgrList);

            my @engineers = ();

            my @contractors = ();
            open(DF, "<$dataFile");

            foreach(<DF>)
            {

                chomp($_);
                if( $_ =~ /^Engineers/ )
                {
                    my ( $left, $right ) = split(/:/, $_);

                    $right =~ s/^\s+//g;

                    @engineers = split(/\,/,$right);
                }

                if( $_ =~ /^Contractors/ )
                {
                    my ( $left, $right ) = split(/:/, $_);

                    $right =~ s/^\s+//g;

                    @contractors = split(/\,/,$right);
                }

            }

            close(DF);

            my @allEmployees = ();

            push(@allEmployees, @engineers);
            push(@allEmployees, @contractors);

            $empHash{$mgrName} = [ @allEmployees ];

        }

        my @countV = @{ $dataref };

        foreach( @{ $dataref } )
        {

            my $covFile = $_;

            chomp($covFile);

            my $fixStr = "";
            my $dismissStr = "";
            my $extraCount = 0;

            if( $covFile =~ /\.csv/ )
            {
                $fixStr = "Fixed,";
                $dismissStr = "Dismissed,";
                $extraCount = 1;
            }
            else
            {
                $fixStr = "Fixed";
                $dismissStr = "Dismissed";
                $extraCount = 2;
            }

            $_ =~ s/coverity.dump.all.//g;
            $_ =~ s/.csv//g;

            my $dateV = `basename $_`;

            chomp($dateV);
            my $total = 0;
            my $totalOpen = 0;
            my $total3rdpartyOpen = 0;
            my $totalnon3rdpartyOpen = 0;

            my @tmp = ();

            foreach(@Patterns3rdparty)
            {
                my $pattern = $_;

                my @tmp1 = `grep $pattern $covFile`;
                push(@tmp, @tmp1);

            }

            my @tmp2 = `grep /vob/9200_packetcore/packetcore/nsm/routing/metaswitch $covFile`;

            my @tmp3 = `grep /vob/9200_packetcore/packetcore/infra/tail-f $covFile`;
            my @tmp4 = `grep /vob/9200_packetcore/packetcore/nsm/routing/metaswitch/TSM $covFile`;
            my @tmp5 = `grep /vob/9200_packetcore/packetcore/nsm/climap $covFile`;
            my @tmp6 = `grep /vob/9200_packetcore/packetcore/infra/yang/routing/climap $covFile`;
            my @tmp7 = `grep /vob/9200/software/common/infra/transemu $covFile`;
            my @tmp8 = `grep /vob/9200/software/common/infra/confd_passwd $covFile`;

            push(@tmp3,@tmp4);
            push(@tmp3,@tmp5);
            push(@tmp3,@tmp6);
            push(@tmp3,@tmp7);
            push(@tmp3,@tmp8);


            my @tmp_drivers = `grep /vob/9200_drivers/drivers $covFile`;
            my @tmp_infra = `grep /vob/9200_infra/infra $covFile`;
            my @tmp_lvpls = `grep packetcore_lvpls $covFile`;
            my @tmp_svpls = `grep packetcore_svpls $covFile`;

            my @tmp_vpls = ();

            push(@tmp_vpls,@tmp_lvpls);
            push(@tmp_vpls,@tmp_svpls);

            my @tmp_mpls = `grep packetcore_mpls $covFile`;

            my @fix = grep(/$fixStr/, @tmp );
            my @dismiss = grep(/$dismissStr/, @tmp );

            my @fix2 = grep(/$fixStr/, @tmp2 );
            my @dismiss2 = grep(/$dismissStr/, @tmp2 );

            my @fix3 = grep(/$fixStr/, @tmp3 );
            my @dismiss3 = grep(/$dismissStr/, @tmp3 );

            my @fix_infra = grep(/$fixStr/, @tmp_infra );
            my @dismiss_infra = grep(/$dismissStr/, @tmp_infra );

            my @fix_drivers = grep(/$fixStr/, @tmp_drivers );
            my @dismiss_drivers = grep(/$dismissStr/, @tmp_drivers );

            my @fix_mpls = grep(/$fixStr/, @tmp_mpls );
            my @dismiss_mpls = grep(/$dismissStr/, @tmp_mpls );

            my @fix_vpls = grep(/$fixStr/, @tmp_vpls );
            my @dismiss_vpls = grep(/$dismissStr/, @tmp_vpls );

            $total = `cat $covFile | wc -l`;

            my @fixTotal = `grep $fixStr $covFile`;
            my @dismissTotal = `grep $dismissStr $covFile`;

            chomp($total);
            $totalOpen = $total - $extraCount - ( $#fixTotal + 1 + $#dismissTotal + 1);
            $total3rdpartyOpen = $#tmp + 1 - ( $#fix + 1 + $#dismiss + 1 );
            $totalMetaswitchOpen = $#tmp2 + 1 - ( $#fix2 + 1 + $#dismiss2 + 1 );
            $totalTailfOpen = $#tmp3 + 1 - ( $#fix3 + 1 + $#dismiss3 + 1 );
            $totalInfraOpen = $#tmp_infra + 1 - ( $#fix_infra + 1 + $#dismiss_infra + 1 );
            $totalDriversOpen = $#tmp_drivers + 1 - ( $#fix_drivers + 1 + $#dismiss_drivers + 1 );
            $totalVplsOpen = $#tmp_vpls + 1 - ( $#fix_vpls + 1 + $#dismiss_vpls + 1 );
            $totalMplsOpen = $#tmp_mpls + 1 - ( $#fix_mpls + 1 + $#dismiss_mpls + 1 );


            $total3rdpartyOpenOther = $total3rdpartyOpen - $totalMetaswitchOpen - $totalTailfOpen;

            $totalnon3rdpartyOpen = $totalOpen - $total3rdpartyOpen;

            $totalnon3rdpartyOpenOther = $totalnon3rdpartyOpen - $totalInfraOpen - $totalDriversOpen - $totalVplsOpen - $totalMplsOpen;

            push(@dateList,"$dateV:$totalnon3rdpartyOpen:$total3rdpartyOpen:$totalOpen:$totalMetaswitchOpen:$totalTailfOpen:$total3rdpartyOpenOther:$totalInfraOpen:$totalDriversOpen:$totalVplsOpen:$totalMplsOpen:$totalnon3rdpartyOpenOther");

            foreach(keys %empHash)
            {

                my $mgrName = $_;

                my @allEmployees = @{ $empHash{$_} };

                my @totLow = ();
                my @totMed = ();
                my @totHigh = ();
                my @totOpen = ();

                my %engrHash = ();      

                foreach(@allEmployees)
                {

                    my @empList = `grep $_ $covFile`; 
                    my @openList = grep(! /Fixed|Dismissed/, @empList );
                    my @lowList = grep ( /Low/, @openList);
                    my @medList = grep ( /Medium/, @openList);
                    my @highList = grep ( /High/, @openList);

                    if( $k == $#countV )
                    {
                        $engrHash{$_} = [ @highList ];
                    }

                    push( @totLow, @lowList);
                    push( @totMed, @medList );
                    push( @totHigh,@highList );
                    push( @totOpen,@openList );
                }

                my @tmp = ();

                foreach(@Patterns3rdparty)
                {
                    my $pattern = $_;

                    my @tmp1 = grep ( /$pattern/, @totOpen);
                    push(@tmp, @tmp1);

                }

                my $count1 = $#tmp + 1;
                my $count2 = $#totOpen + 1;

                if ( exists $mgrChartHash{$mgrName} )
                {
                    my @tmp2 = @{ $mgrChartHash{$mgrName} } ; 

                    push(@tmp2,"$dateV:$count1:$count2" );

                    $mgrChartHash{$mgrName} = [ @tmp2 ];
                }
                else
                {
                    my @tmp2 = ();

                    push(@tmp2,"$dateV:$count1:$count2" );

                    $mgrChartHash{$mgrName} = [ @tmp2 ];
                }

                my $H = $#totHigh+1;
                my $M = $#totMed+1;
                my $L = $#totLow+1;

                if( $k == $#countV )
                {
                    $mgrCountHash{$mgrName} = "$H:$M:$L";

                    $mgrListHash{$mgrName} = \%engrHash; 
                }
            }

            $k++;
        }

        return \@dateList;

}

sub Get_Manager_List {


        foreach( keys %mgrListHash )
        {

            my $outString = "";

            my $mgrName = $_;
            my $empHashRef = $mgrListHash{$_};

            foreach( sort keys %{ $empHashRef } )
            {
                my @defectList = @{$empHashRef->{$_}};
                my $defectNum = $#defectList + 1;

                my $string = "";
                my $count = 0;

                foreach(@defectList)
                {
                    my $output_br = "";

                    my @defectIdList = split(/:;:;/,$_);
                    my $defectId = shift(@defectIdList);

                    if( $count == 20 )
                    {

                        $output_br = "<br>";
                        $count = 0;
                    }
                    $string .= "<a href=http://lnxsccov01.ca.tellabs.com:8080/sourcebrowser.htm?projectId=10044#mergedDefectId=$defectId target=\\\"_blank\\\">$defectId</a>,$output_br";

                    $count++;
                 }

                 $outString .= "<tr>";
                 $outString .= "<td class=helpBod>$_</td>";
                 $outString .=  "<td class=helpBod>$defectNum</td>";
                 $outString .=  "<td class=helpBod align=\\\"left\\\">$string</td>";
                 $outString .=  "</tr>";
            }

            $outString .= "</table>";

            $mgrString{$mgrName} = $outString;
        }

}

sub Get_Summary_Table {

    my $dataRef = shift;


     $str = "<table style=\"text-align: left; width: 450px; height: 196px;\"
      border=\"0\" cellpadding=\"2\" cellspacing=\"4\" >\n";
     $str .= "<caption style=\"background-color: rgb(255, 204, 0);\"><span
 style=\"font-weight: bold;\">Open Defects By Manager</span></caption>\n";

     $str .= "<tr><th style=\"background-color: rgb(204, 255, 255); font-weight: bold;\">Manager Name </th>
	<th style=\"background-color: rgb(204, 255, 255); font-weight: bold;\">High</th> 
	<th style=\"background-color: rgb(204, 255, 255);font-weight: bold;\">Med</th> 
	<th style=\"background-color: rgb(204, 255, 255);font-weight: bold;\">Low</th></tr>\n";
     foreach ( keys( %{$dataRef} ) ) {

            my ($High, $Med, $Low) = split(/:/, $dataRef->{$_});

            $str .= "<tr><td style=\"background-color: rgb(204, 255, 255);\" ><a href=\"\" onclick=\"return popitup('$_')\">$_</a></td>
<td style=\"background-color: rgb(228, 228, 228);\">$High</td>
<td style=\"background-color: rgb(204, 255, 255);\">$Med</td>
<td style=\"background-color: rgb(228, 228, 228);\">$Low</td></tr>\n";

     }

     $str .= "</table>\n";

     return $str; 
}

sub Get_XML_String_For_ChartsPie {

        my($dataRef) = shift;

        my @dateList = @{ $dataRef };


        my $lastValue = pop(@dateList);

        my ($dateV,$totalnon3rdpartyOpen,$total3rdpartyOpen,$totalOpen,$total3rdpartyOpenMetaswitch, $total3rdpartyOpenTailf, $total3rdpartyOpenOther, $totalnon3rdpartyOpenInfra, $totalnon3rdpartyOpenDrivers, $totalnon3rdpartyOpenVpls, $totalnon3rdpartyOpenMpls, $totalnon3rdpartyOpenOther ) = split(/:/,$lastValue);

        my $XML = "
\"<chart caption='9200 $Release Coverity Open Defects Pie Chart' \"+
\"showValues='0' showLabels='0' showLegend='1'  legendPosition='RIGHT' chartrightmargin='40' \"+
\"bgcolor='ECF5FF' bgalpha='70' bordercolor='C6D2DF' \"+
\"basefontcolor='2F2F2F' basefontsize='11' showpercentvalues='1' \" +
\"exportEnabled='1' exportAtClient='0' exportAction='download'\" +
\" exportHandler='$FUSION_CHARTS_URL/ExportHandlers/PHP/FCExporter.php' exportFileName='Chart$$' \" +
\"bgratio='0' startingangle='200' animation='1' >\" + \n";

        $XML .= " \"<set value='$total3rdpartyOpenOther' label='3rdparty Defects Other' color='1160B8'/>\"+\n";
        $XML .= " \"<set value='$total3rdpartyOpenMetaswitch' label='3rdparty Defects Metaswitch'  color='F2AC0C'/>\"+\n";
        $XML .= " \"<set value='$total3rdpartyOpenTailf' label='3rdparty Defects Tailf' color='BF0000'/>\"+\n";
        $XML .= " \"<set value='$totalnon3rdpartyOpenOther' label='Apps Defects Other' color='00247C'/>\"+\n";
        $XML .= " \"<set value='$totalnon3rdpartyOpenDrivers' label='Apps Defects Drivers' color='008900'/>\"+\n";
        $XML .= " \"<set value='$totalnon3rdpartyOpenInfra' label='Apps Defects Infra' color='E95D0F'/>\"+\n";
        $XML .= " \"<set value='$totalnon3rdpartyOpenMpls' label='Apps Defects MPLS' color='429EAD'/>\"+\n";
        $XML .= " \"<set value='$totalnon3rdpartyOpenVpls' label='Apps Defects VPLS' color='C2780D'/>\"+\n";
        $XML .= "\"</chart>\"\n";
        return $XML;


}

        
sub Get_XML_String_For_Charts {

        my($dataRef) = shift;

        my @dateList = @{ $dataRef };

        my $XML = "
\"<chart caption='9200 $Release Coverity Open Defects Trend (last 60 days)' \"+
\"xAxisName='Date' YAxisName='# Coverity Defects' paletteColors='#6CC417,#C34A2C,#151B8D' useRoundEdges='1' \"+
\"baseFontSize ='11' baseFontColor ='2F2F2F'\" + \"legendPosition='RIGHT'\"+
\"exportEnabled='1' exportAtClient='0' exportAction='download'\" +
\" exportHandler='$FUSION_CHARTS_URL/ExportHandlers/PHP/FCExporter.php' exportFileName='Chart$$'\" +
\"exportHandler='$FUSION_CHARTS_URL/ExportHandlers/PHP/FCExporter.php' exportFileName='Chart$$'\" +
\"outCnvBaseFontSize ='11'  outCnvBaseFontColor ='2F2F2F'>\" +\n";

        $XML .= "\"<categories>\"+";

        foreach my $str ( @dateList )
        {
            my ($date, $c1, $c2, $c3, $c4, $c5, $c6, $c7, $c8, $c9, $c10, $c11 ) = split(/:/,$str);

            $XML .= "          \"<category Label='$date'/>\"+\n";
        }
         $XML .= "       \"</categories>\"+\n";

                foreach my $set ("non3rdparty", "3rdparty", "total") {

                        if( $set eq "non3rdparty" )
                        {
                            $XML .= "       \"<dataset seriesName='$set' >\"+\n";
                        }elsif( $set eq "3rdparty" )
                        {

                            $XML .= "       \"<dataset seriesName='$set' >\"+\n";

                        }
                       elsif( $set eq "total" )
                        {

                            $XML .= "       \"<dataset seriesName='$set' renderAs='Line' >\"+\n";
                        }

                foreach my $str ( @dateList ) {

                        my ($date , $c_non3rdparty, $c_3rdparty, $total ) = split(/:/,$str );
                        if( $set eq "non3rdparty" )
                        {
                                $XML .= "          \"<set value='$c_non3rdparty' showValue='0'/>\"+\n";
                        }elsif( $set eq "3rdparty" )
                        {

                                $XML .= "          \"<set value='$c_3rdparty' showValue='0'/>\"+\n";

                        }
                        elsif( $set eq "total" )
                        {

                                $XML .= "          \"<set value='$total' showValue='0'/>\"+\n";
                        }


                }
                $XML .= "       \"</dataset>\"+\n";

        }

        $XML .= "\"</chart>\"\n";
        return $XML;


}

sub Get_XML_String_For_ChartsMgr {

        my($dataRef) = shift;

        my $mgrName = shift;

        my @dateList = @{ $dataRef };

        my $XML = " 
\"<chart caption='Open Coverity Defects By Manager: $mgrName' \"+
\"xAxisName='Date' YAxisName='# Coverity Defects' paletteColors='#6CC417,#C34A2C,#151B8D' \"+
\"baseFontSize ='11' baseFontColor ='2F2F2F' \" + \"legendPosition='RIGHT' \"+
\"exportEnabled='1' exportAtClient='0' exportAction='download' \" +
\"exportHandler='$FUSION_CHARTS_URL/ExportHandlers/PHP/FCExporter.php' exportFileName='Chart$$' \" +
\"outCnvBaseFontSize ='11'  outCnvBaseFontColor ='2F2F2F'>\" +\n";

        $XML .= "\"<categories>\"+";

        foreach my $str ( @dateList )
        {
            my ($date, $c1, $c2 ) = split(/:/,$str);

            $XML .= "          \"<category Label='$date'/>\"+\n";
        }
         $XML .= "       \"</categories>\"+\n";

                foreach my $set ("3rdparty", "non3rdparty") {

                        if( $set eq "non3rdparty" )
                        {
                            $XML .= "       \"<dataset seriesName='$set' >\"+\n";
                        }elsif( $set eq "3rdparty" )
                        {

                            $XML .= "       \"<dataset seriesName='$set' >\"+\n";

                        }

                foreach my $str ( @dateList ) {

                        my ($date , $c_3rdparty, $c_non3rdparty ) = split(/:/,$str );
                        if( $set eq "non3rdparty" )
                        {
                                $XML .= "          \"<set value='$c_non3rdparty' showValue='0'/>\"+\n";
                        }elsif( $set eq "3rdparty" )
                        {

                                $XML .= "          \"<set value='$c_3rdparty' showValue='0'/>\"+\n";

                        }

                }
                $XML .= "       \"</dataset>\"+\n";

        }

        $XML .= "\"</chart>\"\n";
        return $XML;


}
