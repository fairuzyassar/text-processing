#MEMBUAT DAFTAR KATA UNIK PADA TAG <TEXT>
open(IN, 'korpus-tugas2.txt');
open(VOCAB, '>vocabulary_list.txt');

print("RUNNING PROCESS...\n");

my %words;
my $isLine = 0;
my $isText = 1;
while(my $line = <IN>){
    if($line =~ /<\/TEXT>/){
        $isLine = 0;
    }

    if($isLine){
        chomp $line;
        my $paragraph = $line;
        $paragraph =~ s/\W/ /g;
        $paragraph =~ s/\d+//g;
        $paragraph =~ s/\b\w\b//g;
        $paragraph =~ s/\b(?=[XVI])(X[CL]|L?X{0,3})(I[XV]|V?I{0,3})\b//g; #Menghapus angka romawi
        $paragraph =~ tr/A-Z/a-z/;
        $paragraph =~ s/\s+/ /g;
        $paragraph =~ s/^\s*//g;
        $paragraph =~ s/\s*$//g;

        foreach my $word(split(/\s+/, $paragraph)){
            $words{$word} = 1;  
        }
    }
    
    if ($line =~ /<TEXT>/){
        $isLine = 1;
    }
}


foreach my $str(keys %words){
    print VOCAB "$str\n";
}

close(IN);
close(VOCAB);

#MENCARI KATA YANG MEMILIKI KODE FONETIK YANG SAMA
open(VOCABULARY, 'vocabulary_list.txt');
open(SOUNDEX, '>soundex_result.txt');
my %commonSoundex;

while(my $vocab=<VOCABULARY>){
    chomp $vocab;
    my $fonetiCode = soundex($vocab);
    printf SOUNDEX "%-17s %s\n", $vocab, $fonetiCode;
    if(exists $commonSoundex{$fonetiCode}){
        push(@{ $commonSoundex{$fonetiCode} }, $vocab);
    } else {
        $commonSoundex{$fonetiCode} = [$vocab];
    }
}
close(VOCABULARY);
close(SOUNDEX);

#MENGHITUNG EDIT DISTANCE DAN LONGEST COMMON SUBSEQUNCE
open(VOCABULARY, 'vocabulary_list.txt');
open(RES, '>stemmer_result.txt');

while(my $vocab = <VOCABULARY>){
    chomp $vocab;
    foreach $fonetic(keys %commonSoundex){
        my %vocabMatrix;
        my $maxED = -1;
        my $minLCS = -1;

        #Menghitung nilai ED dan LCS terhadap masing-masing input
        foreach $word(@{$commonSoundex{$fonetic}}){
            my $ed = leveinstein_distance($word, $vocab);
            my $lcs = lcs($word, $vocab);
            my $firstRule = $ed + $lcs;

            #Mencari kata dengan nilai ED maksimum dan nilai LCS minimum
            if($firstRule == length($vocab) and $ed < $lcs){
                $vocabMatrix{$word} = [$ed, $lcs];
                if($ed > $maxED){
                    $maxED = $ed;
                    $minLCS = $lcs;
                } elsif ($ed == $maxED and $lcs < $minLCS){
                    $minLCS = $lcs;
                }
            }
        }

        
        if($maxED != -1 and $minLCS != -1){
            my @candidateWord;
            foreach $str(keys %vocabMatrix){
                if($maxED == $vocabMatrix{$str}[0] and $minLCS == $vocabMatrix{$str}[1]){
                    push(@candidateWord, $str);
                }
            }
            $candidateWordLen = @candidateWord;
            my $stem = $candidateWord[0];

            #Memilih kata yang memiliki panjang paling minimal diantara kata yang termasuk ED maksimum dan LCS minimum
            if($candidateWordLen > 1){
                foreach $strCandidate(@candidateWord){
                    if(length($strCandidate) < length($stem)){
                        $stem = $strCandidate;
                    }
                }
            }

            #Mencetak Hasil Stemming
            foreach $words(keys %vocabMatrix){
                printf RES "%-15s %s\n", $words, $stem;
            }
        }
    }    
}

print "PROCESS DONE\n";
close(VOCABULARY);
close(RES);


sub soundex {
    my ($word) = @_;
    
    #Mempertahankan karakter pertama
    my $firstletter = substr($word, 0, 1);
    my $restletter = substr($word, 1);

    #Mengubah huruf menjadi angka
    $restletter =~ s/[aiueoyhw]/0/sg;
    $restletter =~ s/[bfpv]/1/sg;
    $restletter =~ s/[cgjkqsxz]/2/sg;
    $restletter =~ s/[dt]/3/sg;
    $restletter =~ s/l/4/sg;
    $restletter =~ s/[mn]/5/sg;
    $restletter =~ s/r/6/sg;

    #Menghapus angka yang berurutan
    my $lastChar = "";
    my $sdxCode = "";
    foreach $ctr(split(//, $restletter)){
        my $currentChar = $ctr;
        if($currentChar eq $lastChar){
            $sdxCode .= "";
        } else {
            $sdxCode .= $currentChar;
            $lastChar = $currentChar;
        }
    }

    #Menghapus angka nol
    $sdxCode =~ s/0//sg;

    #menambahkan angka nol jika kode digit kurang dari 3 dan mengambil 3 digit pertama
    my $digitLength = length($sdxCode);
    if($digitLength == 2){
        $sdxCode .= "0";
    } elsif($digitLength == 1){
        $sdxCode .= "00";
    } elsif($digitLength == 0){
        $sdxCode .= "000";
    } elsif($digitLength > 3){
        $sdxCode = substr($sdxCode,0, 3)
    }

    $firstletter = uc $firstletter;

    $soundexCode = "$firstletter$sdxCode";
    return($soundexCode);
}

use List::Util qw(min);
sub leveinstein_distance {
    my ($word1, $word2) = @_;
    my ($lenWord1, $lenWord2) = (length($word1), length($word2));

    my @matrix;
    for(my $x=0;$x <= $lenWord1;$x++){
        $matrix[$x][0] = $x;
    }
    for(my $y=0;$y <= $lenWord2;$y++){
        $matrix[0][$y] = $y;
    }

    for(my $i=1;$i <= $lenWord1+1;$i++){
        for(my $j=1;$j <= $lenWord2+1;$j++){
            if(substr($word1,$i-1,1) eq substr($word2,$j-1,1)){
                $matrix[$i][$j] = min($matrix[$i-1][$j]+1, $matrix[$i-1][$j-1], $matrix[$i][$j-1]+1);
            } else {
                $matrix[$i][$j] = min($matrix[$i-1][$j]+1, $matrix[$i-1][$j-1]+1, $matrix[$i][$j-1]+1);
            } 
        }
    }

    return($matrix[$lenWord1][$lenWord2]);
}

use List::Util qw(max);
sub lcs {
    my ($firstWord, $secondWord) = @_;
    my ($lenFirstWord, $lenSecondWord) = (length($firstWord), length($secondWord));

    my @tabulationmatrix;
    for (my $i=0;$i <= $lenFirstWord+1;$i++){
        for (my $j=0;$j <= $lenSecondWord+1;$j++){
            if($i == 0 or $j == 0 ){ 
                $tabulationmatrix[$i][$j] = 0;
            } elsif(substr($firstWord, $i-1, 1) eq substr($secondWord, $j-1, 1)) {
                $tabulationmatrix[$i][$j] = $tabulationmatrix[$i-1][$j-1] + 1;
            } else {
                $tabulationmatrix[$i][$j] = max($tabulationmatrix[$i-1][$j], $tabulationmatrix[$i][$j-1]);
            }
        }
    }
    return($tabulationmatrix[$lenFirstWord][$lenSecondWord]);
}