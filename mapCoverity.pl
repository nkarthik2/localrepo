#!/usr/atria/bin/Perl

########################
# Author : Karthik Nagarajan
# Date   : 02/15/2012
# Description :
# This script is used to assign new
# coverity defects to the individual engineer
# who committed the activity to clearcase
# This script uses the Coverity web services API to get
# new coverity defects since the last coverity Jenkins run.
# This script gets called from fp1.0_coverity.
##########################
#use lib "/scratch/Tools/knagaraj/lib/perl5/site_perl/5.8.6";
use File::Basename;
use Net::SMTP;
#use SOAP::Lite;

BEGIN {

    undef my $libdir;
    $libdir = "/view/tools_view/vob/adpscmtools/lib";
    require "$libdir/ADP.pm";
    require "$libdir/ADPcommon.pm";

    import ADP;
    import ADPcommon;
}

#my $fromUser = "knagaraj";
#my $fromUser = "knagaraj";
#my $subject = "TEST";
#my $message = "TEST";
#my $ME = basename($0);

#     my $ref = {
#                   "mailhost"   => 'mail.hq.tellabs.com',
#                   "domain"     => 'tellabs.com',
#                   "to"         => [ "$fromUser\@tellabs.com" ],
#                   "reply-to"   => "$fromUser\@tellabs.com",
#                   "from-alias" => "TEST",
#                   "from"       => "$fromUser",
#                   "subject"    => "$subject",
#                   "message"    => [ $message ],

#                 };

#      eval {
#      my $stat = &common_EmailMsg($ref);

#      if( $stat )
#      {

#          print "Failure to send mail \n";
#      }

#      };

#      if($@)
#      {

#          print "EXCEPTION : $@ \n";
#      }

#exit(0);

my $buildid = $ARGV[0];

my $prevBuild = $buildid - 1;

my $configDir = "/scratch/Tools/knagaraj/jenkins/.jenkins/jobs/fp1.0_coverity/builds/$buildid";


my $changeLogFile = "$configDir/changelog.xml";

#my $compilerWarnFile = "$configDir/compiler-warnings.xml";

my $buildFile = "$configDir/build.xml";

my $prevBuildFile = "";


my @diffWarn = ();

my %warningsPriorityMapping = (

    	"-Wunused-variable"			=> "Low",
	"-Wunused-function" 			=> "Low",
	"-Wimplicit-function-declaration" 	=> "High",
	"-Wunused-value" 			=> "Normal",
	"-Wdeprecated-declarations" 		=> "Low",
	"-Wreturn-type"				=> "High",
	"-Waddress"				=> "High",
	"-Wparentheses"				=> "Normal",
	"-Wformat"				=> "High",
	"-Wformat-extra-args"			=> "High",
	"-Wformat-zero-length"			=> "High",
	"-Wuninitialized"			=> "High",
	"-Wstrict-aliasing"			=> "High",
	"-Woverflow"				=> "High",
	"-Warray-bounds"			=> "High",
	"-Wunknown-pragmas"			=> "Low",
	"-Wunused-label"			=> "Low",
	"-Wpointer-to-int-cast"			=> "Normal",	
	"assignment makes pointer from integer without a cast"	=> "High",
	"missing braces around initializer"			=> "Normal",
	"assignment makes integer from pointer without a cast"	=> "Normal",
	"assignment from incompatible pointer type"		=> "High",
	"excess elements in array initializer"			=> "High",
	"pointer targets in assignment differ in signedness"	=> "Normal",
	"pointer targets in initialization differ in signedness"	=> "Normal",
	"pointer targets in passing argument \\\d+ of \'.*?\' differ in signedness" => "Normal",
	"unused variable \'.*?\'"			=> "Low",
	"nested extern declaration of \'.*?\'"	=> "Normal",
	"passing argument \\\d+ of \'.*?\' discards qualifiers from pointer target type" => "High",
	"passing argument \\\d+ of \'.*?\' from incompatible pointer type" => "High",
	"value computed is not used" 		=> "Low",
	"\".*?\" redefined" 			=> "Normal",
	"imported module .*? not used"		=> "Low",

);    

for( $i=$prevBuild ; $i>=0 ; $i-- )
{

    #print "I is $i \n";
    my $prevConfigDir = "/scratch/Tools/knagaraj/jenkins/.jenkins/jobs/fp1.0_coverity/builds/$i";
#    my $prevCompilerWarnFile = "$prevConfigDir/compiler-warnings.xml";

     $prevBuildFile = "$prevConfigDir/build.xml";

    if( -f "$prevBuildFile" )
    {
        #print "Found it ... \n";
#        @diffWarn = `diff -b $prevCompilerWarnFile $compilerWarnFile`;
        last;
    }

}

#foreach( @diffWarn )
#{
#    print "$_";
#}

#print "Getting snapshot ID \n";

#print SOAP::Lite
#    -> proxy('http://lnxsccov01.ca.tellabs.com:8080')
#    -> uri('http://lnxsccov01.ca.tellabs.com:8080/ws/v4/defectservice')
#    -> getSnapshotsForStream('fp1.0-jenkins-continous-integ')
#    -> result;

my $CT="/usr/atria/bin/cleartool";

open(CL, "<$changeLogFile" );

my %changesHash = ();

my %userHash = ();

my @entry = ();

my @file = ();

my $activity = "";

my %reportHash = ();

my %fileAct = ();

foreach( <CL> )
{

    my $line = $_ ;

    chomp($line);

    if( $line =~ /<entry>/ )
    {
        @entry = ();

    }
    elsif( $line =~ /<\/entry>/ )
    {
        $changesHash{$activity} = [ @entry ];
    }
    else
    {

        if( $line =~ /<headline>/i )
        {

            $line =~ /^\s*<headline>([^<]+)<\/headline>\s*$/;

            $activity = $1;

        }

        if( $line =~ /<user>/i )
        {

            $line =~ /^\s*<user>([^<]+)<\/user>\s*$/;

            $user = $1;

            push( @entry, $user );

        }

        if( $line =~ /<file>/i )
        {
            @file = ();
            #print "Init file \n";

        }
        elsif( $line =~ /<\/file>/i )
        {
            push(@entry, [ @file ] ); 
        }
        else
        {

            if( $line =~ /<name>/i )
            {
                $line =~ /<name>([^<]+)<\/name>/i;

                my $fileName = $1;
                #print "Pushing $fileName \n";
                push(@file, $fileName);

                my $tmpF = "/"."$fileName";
                my $baseF = `basename $tmpF`; 

                chomp($baseF);
                my $key = "$baseF"."_"."$activity";
                $fileAct{$key} += 1;
            }
            elsif( $line =~ /<version>/i )
            {
                $line =~ /<version>([^<]+)<\/version>/i;

                my $version = $1;
                #print "Pushing $version \n";
                push(@file, $version);
            }
        }
    }


}

close(CL);

my @coverityLines = ();

open(BUILDF, "<$prevBuildFile");    

foreach( <BUILDF> )
{

    chomp($_);

    my $line = $_;

    if( $line =~ /<defectIds>/ )
    {
        @coverityLines = ();
    }
    elsif( $line =~ /<\/defectIds>/ )
    {
        last;

    }
    else
    {

            if( $line =~ /<long>([^<]+)<\/long>/i )
            {
                $line =~ /<long>([^<]+)<\/long>/i;
                my $coverityDefect = $1;

                push(@coverityLines, $coverityDefect ) if( $coverityDefect ne "" );
            }


    }

}

close(BUILDF);


foreach( @coverityLines )
{


    #print "COVERITY DEFECT $_ \n";


}

#my $tmpDate = `date +"%m/%d/%y_%H:%M"`;

my $month = `date +"%m"`;

chomp($month);

my $day = `date +"%d"`;

chomp($day);

my $year = `date +"%y"`;

chomp($year);

my $hour = `date +"%H"`;

chomp($hour);

my $minute = `date +"%M"`;

chomp($minute);

#$day = $day - 2;

my $hour1 = $hour - 6;

$day1 = $day - 1;

my @d=localtime time()-21600; # get the date and time for past 6 hours. Just calculate seconds such as 3600*6

$d[5] += 1900;
$d[4]++;
$d[5]  =~ s/20//g;
$d[4]  = sprintf("%02d", $d[4]);
$d[3]  = sprintf("%02d", $d[3]);
$d[2]  = sprintf("%02d", $d[2]);
$d[1]  = sprintf("%02d", $d[1]);
$d[0]  = sprintf("%02d", $d[0]);

my $date1 = "$d[4]/$d[3]/$d[5]"."_"."$d[2]:$d[1]";

##my $date1 = "$month/$day/$year"."_"."$hour1:$minute";

#my $date1 = "$month/$day1/$year"."_"."$hour:$minute";

my $date2 = "$month/$day/$year"."_"."$hour:$minute";

#$date1 = "07/02/12_22:07";

#$date2 = "07/03/12_03:07";

print "$date1\n";

print "$date2\n";

##exit 0;

my @coverityLines1 = `cd /scratch/Tools/knagaraj/coverity_examples/cim_api_example; /scratch/Tools/knagaraj/coverity_examples/cim_api_example/runDefect.sh lnxsccov01.ca.tellabs.com:8080 coverity $date1 $date2`;

my %covDefect = ();

foreach( @coverityLines1 )
{
    my $line = $_;

    chomp($line);

    if( $line =~ /^compiling.../ )
    {

        next;
    }

    if( $line =~ /^running.../ )
    {

        next;
    }

    my ($defect,$file,$checker,$lineNum,$defectInst,$desc) = split(/:;:;/, $line);

    chomp($file);
    chomp($checker);
    chomp($lineNum);
    chomp($defectInst);
    chomp($desc);

    $covDefect{$defect} = [ $file, $checker, $lineNum, $defectInst, $desc ];
}

foreach( keys %covDefect )
{

    #print "DEFECT: $_, FILE: $covDefect{$_}->[0], CHECKER:$covDefect{$_}->[1] \n";

}
#exit 0;

#my @warnLines = ();
#my @warnList = ();

#open(WARNF, "<$compilerWarnFile" );

#foreach(<WARNF>)
#{

#    chomp($_);

#    my $line = $_;

#    my $lineNum = "";

#    my $fileName = "";

#    my $errMessage = "";

#    if( $line =~ /<warning>/ )
#    {
#        @warnLines = ();
#    }
#    elsif( $line =~ /<\/warning>/ )
#    {
#        push( @warnList, [ @warnLines ] ) if( @warnLines ); 

#    }
#    else
#    {
#        if( $line =~ /<primaryLineNumber>/ )
#        {

#            $line =~ /<primaryLineNumber>([^<]+)<\/primaryLineNumber>/;
#            $lineNum = $1;

#            push(@warnLines, $lineNum ) if( $lineNum ne "" );

#        }

#        if( $line =~ /<fileName>/ )
#        {

#            $line =~ /<fileName>([^<]+)<\/fileName>/;
#            $fileName = $1;

#            push(@warnLines, $fileName ) if( $fileName ne "" );
#
#        }
#
#        if( $line =~ /<message>/ )
#        {
#
#            $line =~ /<message>([^<]+)<\/message>/;
#            $errMessage = $1;
#
#            push(@warnLines, $errMessage ) if( $errMessage ne "" );
#
#        }
#    }
#}

#close(WARNF);

foreach (keys %changesHash )
{

    my $activity = $_;

    #print "ACTIVITY : $_ \n";

    if( $activity =~ /revert/ )
    {

        print "Skipping revert activity: $activity ...\n";

        next;
    }

    my @list = @{ $changesHash{$_} };

    my $user = shift @list;

    #if( $#list > 50 )
    #{
    #    print "WARN: Number of elements in activity $activity is > 50, skipping ... \n";
    #    next;
    #}
    $userHash{$activity} = $user;
    #print "\tUSER: $user \n";

#    my $fileref = shift @list;

    foreach ( @list )
    {


        my $fileref = $_;
        #print "\t$fileref->[0] , $fileref->[1] \n";

        my $filetmp1 = "/"."$fileref->[0]";
        my $fileversion = $fileref->[1];

        if ( $filetmp1 =~ /\s+/ )
        {
            print "FILE $filetmp1 has a space, skipping ... \n";
            next;
        }

        if( -d "/view/knagaraj_master_fp1.0_coverity_hudson"."$filetmp1" )
        {

            if($filetmp1 =~ /\@\@/ ) 
            {
                my($left,$right) = split(/\@\@/, $filetmp1 ); 
                $filetmp1 = $right;
            }
            else 
            {
                print "ELEMENT $filetmp1 is a directory, skipping ... \n";
                next;
            }
        }

        #my $out = `$CT setview -exec "$CT describe -pred $filetmp1\@\@$fileversion" knagaraj_master_fp1.0_coverity_hudson`;

        #$out =~ /version:\s+(.*)$/;

        #my $pred = $1;

        #print "PRED is $pred \n";

        #my @diff = `$CT setview -exec "diff -b $filetmp1\@\@$pred $filetmp1\@\@$fileversion" knagaraj_master_fp1.0_coverity_hudson`;

        #my @add_change_lines = ();

        #foreach(@diff)
        #{

        #    if( $_ =~ /([\d,]+)a([\d,]+)/ )
        #    {
        #        push (@add_change_lines, $2);
                #print "DIFF : a$2 \n";
        #    }

        #    if( $_ =~ /([\d,]+)c([\d,]+)/ )
        #    {
        #        push (@add_change_lines, $2);
                #print "DIFF : c$2 \n";
        #    }
        

        #}

        my $file1 = `basename $filetmp1`;

        chomp($file1);
        foreach( keys %covDefect )
        {

            my $defect = $_;
            my $ref = $covDefect{$_};
            my $filetmp = $ref->[0];

            #print "FILETMP is $filetmp \n";

            if( $filetmp eq "" || $filetmp eq "null")
            {
                next;
            }

            my $file2 = `basename $filetmp`;

            if( ( $? >> 8 ) != 0 )
            {

                print "$filetmp \n";
            }

            chomp($file2);

#            print "FILE1 $file1 : FILE2 $file2 \n" if ($file2 eq "qosStats.c" );

            if( $file1 eq $file2 ) 
            {

                my @acts = ();

                #if( $file1 eq "statsd_cfg.c" )
                #{

                #    print "MATCHED FILE statsd_cfg.c \n";

                #}

                foreach(  keys %fileAct )
                {
                    #print "FILE ACT $_ ...\n"; 
                    if( $_ =~ /^\Q$file1\E/ )
                    {
                        #print "PUSHING to acts ... \n";
                        push(@acts, $_ );
                    }
                }

                if( $#acts > 0 )
                {
                    print "FILE $file1 in more than 1 act ...\n"; 
                    foreach(@acts)
                    {

                        print "$_\n";
                    }
                    next;
                }

                if( $file1 eq "Makefile" )
                {
                
                    next;
                }

                #my $testFile="tss_dbg_cmd.c";
                #if( grep /\Q$testFile\E/, @diffWarn )
                #{
                #    print "Found tss_dbg_cmd.c \n";
                #}

                #if( ! grep /\Q$file1\E/, @diffWarn )
                #{
                #
                #    next;
                #}

                #foreach( @add_change_lines )
                #{
#                    print "ADD/CHANGE : $_ \n";
                #    if( $_ =~ /\,/ )
                #    {
#                        print "MATCHES , \n";
                #        my ($from, $to) = split(/\,/,$_);
                #        if($ref->[1] >= $from && $ref->[1] <= $to )
                #        {
                        
                            if( exists $reportHash{$activity} )
                            {

                                my @tmplist = @{ $reportHash{$activity} };

                                push(@tmplist, [ $defect, $filetmp, $ref->[1], $ref->[2], $ref->[3], $ref->[4] ] );
                                $reportHash{$activity} = [ @tmplist ]; 
                            }
                            else
                            {

                                my @tmplist = ();

                                push(@tmplist, [ $defect, $filetmp, $ref->[1] , $ref->[2], $ref->[3], $ref->[4] ] );

                                $reportHash{$activity} = [ @tmplist ];
                            }

                #            #print "Found MATCH: $ref->[0] , $ref->[1] , $ref->[2] \n";
                #        }
                #    }
                #    else
                #    {
                #        if( $ref->[1] == $_ )
                #        {
                #            if( exists $reportHash{$activity} )
                #            {

                #                my @tmplist = @{ $reportHash{$activity} };

                #                push(@tmplist, [ $filetmp, $ref->[1], $ref->[0] ] );
                #                $reportHash{$activity} = [ @tmplist ]; 
                #            }
                #            else
                #            {

                #                my @tmplist = ();

            #                    push(@tmplist, [ $filetmp, $ref->[1], $ref->[0] ] );

            #                    $reportHash{$activity} = [ @tmplist ];
            #                }

            #                #print "Found MATCH: $ref->[0] , $ref->[1] , $ref->[2] \n";
            #            }
            #        }
            #    }
            }
        }

#        exit 0;


    }


}

my $ME = basename($0);

my $fromUser=$ENV{LOGNAME};

foreach( keys %reportHash )
{

    my $message = "";

    my $subject = "";

    my $activity = $_;

    #if( $activity !~ /176511/ )
    #{
    #    next;
    #}

    $subject = "$_ : PLEASE FIX NEW fp1.0 COVERITY DEFECTS";

    my $user = $userHash{$_};

    $message = "Coverity URL : http://lnxsccov01.ca.tellabs.com:8080\n";

    $message .= "\nPlease use your Windows username/password to login to Coverity. \n";

    print "\n$_:$userHash{$_}\n";

    $message .= "\n$_:\n\n";

    @covDefects = @{ $reportHash{$_} };

    foreach(@covDefects)
    {

        my $defectRef = $_;
        #my $priority = "Normal";

        my $lineNum = $_->[3];
        my $defectInst = $_->[4];
        my $desc = $_->[5];

        #if ( grep( /$_->[0]/, @coverityLines ) )
        #{
        #
        #    print "DEFECT ALREADY EXISTS IN PREVIOUS BUILD : $_->[0] ...\n";
        #
        #}

        # $_->[2] =~ s/\&apos\;/\'/g;
        # $_->[2] =~ s/\&quot\;/\"/g;

        #foreach( keys %warningsPriorityMapping )
        #{

        #    if( $warnRef->[2] =~ /$_/i )
        #    {

                #print "FOUND PRIORITY MATCH : $_ : $warningsPriorityMapping{$_} \n"; 
        #        $priority = $warningsPriorityMapping{$_};
        #    }

        #}

        #print "$_->[0]:$_->[1], Priority:$priority\n";

        print "Coverity Defect: http://lnxsccov01.ca.tellabs.com:8080/sourcebrowser.htm?projectId=10044#mergedDefectId=$_->[0]&defectInstanceId=$defectInst\n$_->[1]:$lineNum, Coverity Checker:$_->[2]\n\nDefect Description: $desc\n";

        #$message .= "$_->[0]:$_->[1], Priority:$priority\n";

        $message .= "Coverity Defect: http://lnxsccov01.ca.tellabs.com:8080/sourcebrowser.htm?projectId=10044#mergedDefectId=$_->[0]&defectInstanceId=$defectInst\n$_->[1]:$lineNum, Coverity Checker:$_->[2]\n\nDefect Description: $desc\n";

        #print "$_->[2]\n";

        #$message .= "$_->[2]\n";

        print "\n";

        $message .= "\n";

        my $out = `/home/sunwicc01/wicc/coverity/cov-sa/bin/cov-manage-im --mode defects --update --stream fp1.0-jenkins-continous-integ --cid $_->[0] --set owner:$user --user admin --password coverity --host "lnxsccov01.ca.tellabs.com" 2>&1`;


        if( $out =~ /Update FAILED/ )
        {

            print "UPDATE FAILED adding user and retrying in coverity ... \n";

            `cd /scratch/Tools/knagaraj/coverity_examples/cim_api_example;./runUpdateUsers.sh lnxsccov01.ca.tellabs.com:8080 coverity $user`;

             my $out = `/home/sunwicc01/wicc/coverity/cov-sa/bin/cov-manage-im --mode defects --update --stream fp1.0-jenkins-continous-integ --cid $_->[0] --set owner:$user --user admin --password coverity --host "lnxsccov01.ca.tellabs.com"`;

         }
    }

     my $mgrOut = `/view/tools_view/vob/adpscmtools/adpdashboard/bin/ldapuser.pl -uid=$user -attrs=manager 2>&1`;

     my @to = ();

     push(@to , "$user\@tellabs.com");
     push(@to , "knagaraj\@tellabs.com");
     push(@to , "ptuano\@tellabs.com");
     push(@to , "srao\@tellabs.com");

     if ( $mgrOut !~ /goner/ )
     {
         my @mgrList = split(/,/, $mgrOut);

         my $mgrName = shift(@mgrList);

         my ($cn, $mName) = split(/=/,$mgrName);

         push(@to,"$mName\@tellabs.com") if( $mName ne "" );

     }
     else
     {

         my $uidContractorOut=`/view/tools_view/vob/adpscmtools/adpdashboard/bin/ldapuser.pl -uid=$user -attrs=\"tellabsContractorContact\"`;

         $uidContractorOut =~ s/^\s+//g;
         $uidContractorOut =~ s/\s+$//g;

         $uidContractorOut =~ s/CN=([^,]+),.*/$1/;

         my $mName = $uidContractorOut;

         push(@to,"$mName\@tellabs.com") if( $mName ne "" );
     }

     my $ref = {
                   "mailhost"   => 'mail.hq.tellabs.com',
                   "domain"     => 'tellabs.com',
#                   "to"         => [ "$user\@tellabs.com", "knagaraj\@tellabs.com", "ptuano\@tellabs.com", "srao\@tellabs.com" ],
                   "to"         => [ @to ],
#                   "to"         => [ "$fromUser\@tellabs.com" ],
                   "reply-to"   => "$fromUser\@tellabs.com",
                   "from-alias" => "JenkinsCoverityDefects",
                   "from"       => "$fromUser",
                   "subject"    => "$subject",
                   "message"    => [ $message ],

                 };

       my $fileact = $activity;

       if( $fileact =~ /deliver/ )
       {
           $fileact =~ s/\s+/_/g;
           $fileact =~ s/\./_/g;
           $fileact =~ s/:/_/g;
           $fileact =~ s/\//_/g;
       }

       my $stat = &common_EmailMsg($ref);

       open(EFH, ">/scratch/Tools/knagaraj/coverityDefectSaveEmail/Email_"."$buildid"."_$fileact");
       print EFH "To:$user\@tellabs.com\n";
       print EFH "Subject:$subject\n";
       print EFH "Message:$message\n";

       close(EFH);
}
