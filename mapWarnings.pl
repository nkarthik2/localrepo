#!/usr/atria/bin/Perl

#########################
# Author : Karthik Nagarajan
# Date   : 02/01/2012
# Description:
# This script is used to assign new
# compiler warnings to the individual
# engineer who committed the activity to
# clearcase.
# This script gets called from fp1.0_build
# Jenikins job.
##########################
use File::Basename;
use Net::SMTP;

BEGIN {

    undef my $libdir;
    $libdir = "/view/tools_view/vob/adpscmtools/lib";
    require "$libdir/ADP.pm";
    require "$libdir/ADPcommon.pm";

    import ADP;
    import ADPcommon;
}

#my $fromUser = $ENV{LOGNAME};
#my $fromUser = "knagaraj";
#my $subject = "TEST";
#my $message = "TEST";
#my $ME = basename($0);

#     my $ref = {
#                   "mailhost"   => 'mail.hq.tellabs.com',
#                   "domain"     => 'tellabs.com',
#                   "to"         => [ "$fromUser\@tellabs.com" ],
#                   "reply-to"   => "$fromUser\@tellabs.com",
#                   "from-alias" => $ME,
#                   "from"       => "$fromUser\@tellabs.com",
#                   "subject"    => "$subject",
#                   "message"    => [ $message ],
#
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

my $configDir = "/scratch/Tools/knagaraj/jenkins/.jenkins/jobs/fp1.0_build/builds/$buildid";


my $changeLogFile = "$configDir/changelog.xml";

my $compilerWarnFile = "$configDir/compiler-warnings.xml";


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

#    print "I is $i \n";
    my $prevConfigDir = "/scratch/Tools/knagaraj/jenkins/.jenkins/jobs/fp1.0_build/builds/$i";
    my $prevCompilerWarnFile = "$prevConfigDir/compiler-warnings.xml";

    if( -f "$prevCompilerWarnFile" )
    {
#        print "Found it ... \n";
        @diffWarn = `diff -b $prevCompilerWarnFile $compilerWarnFile`;
        last;
    }
}

#foreach( @diffWarn )
#{
#    print "$_";
#}

my $CT="/usr/atria/bin/cleartool";

open(CL, "<$changeLogFile" );

my %changesHash = ();

my %warnHash = ();

my %userHash = ();

my @entry = ();

my @file = ();

my $activity = "";

my %reportHash = ();

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

my @warnLines = ();
my @warnList = ();

open(WARNF, "<$compilerWarnFile" );

my $lineNum = "";

my $fileName = "";

my $errMessage = "";

foreach(<WARNF>)
{

    chomp($_);

    my $line = $_;

    if( $line =~ /<warning>/ )
    {
        @warnLines = ();

        $lineNum = "";

        $fileName = "";

        $errMessage = "";
    }
    elsif( $line =~ /<\/warning>/ )
    {
        if( @warnLines )
        {
            my $filetmp = $fileName;
            my $fileKey = "";

            if( $filetmp =~ /^\/vob/ )
            {
                $fileKey = `basename $filetmp`;
                chomp($fileKey);
            }
            else
            {
                my @pathList = split( /\//,$filetmp);
                $fileKey = pop(@pathList);
            }

            ##print "warnHash : Adding $fileKey ...\n";

            if ( exists $warnHash{$fileKey} )
            {
                my @tmp = ();
                @tmp = @{ $warnHash{$fileKey} };
                push( @tmp, [ @warnLines ] );
                $warnHash{$fileKey} = [ @tmp ]; 
            }
            else
            {
                my @tmp = ();
                push( @tmp, [ @warnLines ] );
                $warnHash{$fileKey} = [ @tmp ]; 
            }
        }

    }
    else
    {
        if( $line =~ /<primaryLineNumber>/ )
        {

            $line =~ /<primaryLineNumber>([^<]+)<\/primaryLineNumber>/;
            $lineNum = $1;

            push(@warnLines, $lineNum ) if( $lineNum ne "" );

        }

        if( $line =~ /<fileName>/ )
        {

            $line =~ /<fileName>([^<]+)<\/fileName>/;
            $fileName = $1;

            push(@warnLines, $fileName ) if( $fileName ne "" );

        }

        if( $line =~ /<message>/ )
        {

            $line =~ /<message>([^<]+)<\/message>/;
            $errMessage = $1;

            push(@warnLines, $errMessage ) if( $errMessage ne "" );

        }
    }
}

close(WARNF);

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
        my @diff = ();
        my $file1 = "";

        if( -d "/view/knagaraj_master_fp1.0_build_hudson/$filetmp1" )
        {
            if($filetmp1 =~ /\@\@/ )
            {

                my $savfiletmp1 = $filetmp1;
                my($left,$right) = split(/\@\@/, $filetmp1 );

                my $base = `basename $right`;
                chomp($base);

                ##$filetmp1 = $left."/".$base;

                $file1 = $base;

                if( -d "/view/knagaraj_master_fp1.0_build_hudson/$savfiletmp1/$fileversion" )
                {
                    print "Element $savfiletmp1/$fileversion is a Directory, Skipping ... \n";
                    next;
                }
                print "FILE is $savfiletmp1/$fileversion \n";

                my $out = `$CT setview -exec "$CT describe -pred $savfiletmp1/$fileversion" knagaraj_master_fp1.0_build_hudson`;

                $out =~ /version:\s+(.*)$/;

                my $pred = $1;

                #print "PRED is $pred \n";

                @diff = `$CT setview -exec "diff -b $savfiletmp1/$pred $savfiletmp1/$fileversion" knagaraj_master_fp1.0_build_hudson`;
            }
            else
            {
                print "Element $filetmp1 is a Directory, Skipping ... \n";
                next;
            }

        }
        else
        {

            my $out = `$CT setview -exec "$CT describe -pred $filetmp1\@\@$fileversion" knagaraj_master_fp1.0_build_hudson`;

            $out =~ /version:\s+(.*)$/;

            my $pred = $1;

            #print "PRED is $pred \n";

            @diff = `$CT setview -exec "diff -b $filetmp1\@\@$pred $filetmp1\@\@$fileversion" knagaraj_master_fp1.0_build_hudson`;

            $file1 = `basename $filetmp1`;
            chomp($file1);
        }

        if ( $filetmp1 =~ /\s+/ )
        {
            print "FILE $filetmp1 has a space, skipping ... \n";
            next;
        }

        my @add_change_lines = ();

        foreach(@diff)
        {

            if( $_ =~ /([\d,]+)a([\d,]+)/ )
            {
                push (@add_change_lines, $2);
                #print "DIFF : a$2 \n";
            }

            if( $_ =~ /([\d,]+)c([\d,]+)/ )
            {
                push (@add_change_lines, $2);
                #print "DIFF : c$2 \n";
            }
        

        }

        ##my $file1 = `basename $filetmp1`;
        ##chomp($file1);

        #foreach( @warnList )
        if( exists $warnHash{$file1} )
        {

        #    my $ref = $_;
        #    my $filetmp = $_->[2];

            my $listref = $warnHash{$file1};

            foreach ( @{ $listref } )
            {

            my $ref = $_;

            my $filetmp = $ref->[2];
            my $file2 = "";

            if( $filetmp =~ /^\/vob/ )
            {
                $file2 = `basename $filetmp`;
                chomp($file2);
            }
            else
            {
                my @pathList = split( /\//,$filetmp);
                $file2 = pop(@pathList);
            }
#            print "FILE1 $file1 : FILE2 $file2 \n" if ($file2 eq "qosStats.c" );

            if( $file1 eq $file2 ) 
            {
                if( $file1 eq "Makefile" )
                {
                
                    next;
                }

                if( ! grep /\Q$file1\E/, @diffWarn )
                {

                    next;
                }

                foreach( @add_change_lines )
                {
#                    print "ADD/CHANGE : $_ \n";
                    if( $_ =~ /\,/ )
                    {
#                        print "MATCHES , \n";
                        my ($from, $to) = split(/\,/,$_);
                        if($ref->[1] >= $from && $ref->[1] <= $to )
                        {
                        
                            if( exists $reportHash{$activity} )
                            {

                                my @tmplist = @{ $reportHash{$activity} };

                                push(@tmplist, [ $filetmp, $ref->[1], $ref->[0] ] );
                                $reportHash{$activity} = [ @tmplist ]; 
                            }
                            else
                            {

                                my @tmplist = ();

                                push(@tmplist, [ $filetmp, $ref->[1], $ref->[0] ] );

                                $reportHash{$activity} = [ @tmplist ];
                            }

                            #print "Found MATCH: $ref->[0] , $ref->[1] , $ref->[2] \n";
                        }
                    }
                    else
                    {
                        if( $ref->[1] == $_ )
                        {
                            if( exists $reportHash{$activity} )
                            {

                                my @tmplist = @{ $reportHash{$activity} };

                                push(@tmplist, [ $filetmp, $ref->[1], $ref->[0] ] );
                                $reportHash{$activity} = [ @tmplist ]; 
                            }
                            else
                            {

                                my @tmplist = ();

                                push(@tmplist, [ $filetmp, $ref->[1], $ref->[0] ] );

                                $reportHash{$activity} = [ @tmplist ];
                            }

                            #print "Found MATCH: $ref->[0] , $ref->[1] , $ref->[2] \n";
                        }
                    }
                }
            }
        }

#        exit 0;

        } ## listref
    }

}

my $ME = basename($0);

my $fromUser=$ENV{LOGNAME};

foreach( keys %reportHash )
{

    my $message = "";

    my $subject = "";

    my $activity = $_;

    $subject = "$_ : PLEASE FIX NEW fp1.0 COMPILER WARNINGS";

    my $user = $userHash{$_};

    print "\n$_:$userHash{$_}\n";

    $message .= "\n$_:\n\n";

    @warnings = @{ $reportHash{$_} };

    foreach(@warnings)
    {

        my $warnRef = $_;
        my $priority = "Normal";

        $_->[2] =~ s/\&apos\;/\'/g;
        $_->[2] =~ s/\&quot\;/\"/g;

        foreach( keys %warningsPriorityMapping )
        {

            if( $warnRef->[2] =~ /$_/i )
            {

                #print "FOUND PRIORITY MATCH : $_ : $warningsPriorityMapping{$_} \n"; 
                $priority = $warningsPriorityMapping{$_};
            }

        }

        print "$_->[0]:$_->[1], Priority:$priority\n";

        $message .= "$_->[0]:$_->[1], Priority:$priority\n";

        print "$_->[2]\n";

        $message .= "$_->[2]\n";

        print "\n";

        $message .= "\n";

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
#                   "to"         => [ "$fromUser\@tellabs.com" ],
                   "to"         => [ @to ],
                   "reply-to"   => "$fromUser\@tellabs.com",
                   "from-alias" => "JenkinsCompilerWarnings",
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

       open(EFH, ">/scratch/Tools/knagaraj/compilerWarningSaveEmail/Email_"."$buildid"."_$fileact");
       print EFH "To:$user\@tellabs.com\n";
       print EFH "Subject:$subject\n";
       print EFH "Message:$message\n";

       close(EFH);
}
