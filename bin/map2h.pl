#!/usr/bin/perl -F

sub nazov {

}

# * .. 0 a viac
# + .. 1 a viac
# ? .. 0 alebo 1

# ? na druhom mieste - gravitacia

	while (<>) {
		if ((m/^\s*(\w+)\s+(\w+)\s*$/) && $1!="Value") {
			print(uc($2),"\t=\t0x",$1,"\n");
		}
	}

