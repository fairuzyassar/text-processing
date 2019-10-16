open(FILE, 'korpus-tugas2.txt');
#open(VOCAB, '>vocabulary.txt');

my %words;
my $readline = 0;
while($line = <FILE>){
    if(readline){
        chomp $line;
        $line =~ s/\W//g;
        $line =~ s/A-Z/a-z/g;
        $line =~ s/\s+/ /g;
        $line =~ s/^\s*//g;
        $line =~ s/\s*$//g;

        foreach my $word(split(/\s+/, $line)){
            print "$word\n";
            $words{$word} = 1;  
        }
    }

    if($line =~ /<TEXT>/){
        $readline = 1;
    } elsif($line =~ /<\/TEXT>/){
        $readline = 0;
    }
}

foreach my $str(keys %words){
    print "$str\n";
}

close(FILE);
#close(VOCAB);