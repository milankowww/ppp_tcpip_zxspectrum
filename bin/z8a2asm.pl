#!/usr/bin/perl

while (<>) {
	if (m/^.{23}\;.*?$/) {
		print substr($_, 23);
	} elsif (m/^.{23}\*.*?$/) {
		print ("; Assembler directive: ", substr($_,23), "\n");
	} elsif (m/^\d/) {
		$label = substr($_, 23, 7);
		$insn = substr($_, 30, 5);
		$param = substr($_, 35, 20);
		$rem = substr($_, 55);
		$label =~ s/\s//g;
		$insn =~ s/\s//g;
		$rem =~ s/\s*$//g;
		$param =~ s/\s*$//g;
		$param =~ s/\#([0-9a-fA-F]+)/#0x$1/g;
		$param =~ s/(^|[^\w\#])(\d+)/$1\#$2/g;
		$param =~ s/\$/\#\./g;
	# $param =~ s///g;
		print ($label,":")
			if $label ne '';
		print ("\t", $insn);
		print ("\t", $param);
		print ("\t\t; ", $rem)
			if $rem ne '';
		print "\n";
	} else {
		print ("; ", $_);
	}
}

