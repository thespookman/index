#!/bin/sh -

green=`tput setaf 2`
red=`tput setaf 1`
rest=`tput sgr0`
width=`tput cols`
tab_size=$(((width*3)/4))

fails=0
check () {
	str=$1
	res=$2
	printf '%s\t%s%s%s\n' "$str" \
		`[ "$res" = pass ] && echo $green || echo $red` \
		`[ "$res" = pass ] && echo ✔ || echo ✘` \
		| expand -t$tab_size
	if [ -z "$res" ];
	then
		fails=$((fails+1))
		echo "$output" | xargs printf '\t%s\n'
	fi
	printf $rest
}

temp () {
	mktemp -up $working_dir
}

working_dir=`mktemp -d`
trap "rm -r $working_dir" EXIT

birds=`mktemp -p $working_dir`
mammals=`mktemp -p $working_dir`
insects=`mktemp -p $working_dir`

cat > $birds <<-EOF
	grey-backed gull
	herring gull
	crow
	magpie
	bluetit
	blackbird
	starling
EOF

cat > $mammals <<-EOF
	hedgehog
	fox
	squirrel
	rabbit
	mouse
	rat
EOF

cat > $insects <<-EOF
	ant
	ladybird
	bluebottle
	harvester spider
	house fly
	hover fly
	wasp
	bumblebee
EOF

empty_index=`temp`
./index -f $empty_index -c
check \
	'Creates an index file' \
	$( \
		[ -f $empty_index ] \
		&& echo pass
	)

output=$(
		echo "blackbird" \
		| ./index -f`temp` -c \
			-kbirds -t$birds -i \
			-t- -s
		)
check \
	'Indexes and searches tokens' \
	`[ "$output" = birds ] && echo pass`

output=$(
		./index -f`temp` -c \
			-kbirds -t$birds -i \
			-kmammals -t$mammals -i \
			-kinsects -t$insects -i \
			-l
		)
check \
	'Lists all keys' \
	$( \
		[ "$output" = "`printf '%s\n' birds insects mammals`" ] \
		&& echo pass
	)

output=$(
		./index -f`temp` -c \
			-kbirds -t$birds -i \
			-kmammals -t$mammals -i \
			-kinsects -t$insects -i \
			-kbirds -r \
			-l
		)
check \
	'Removes keys' \
	$( \
		[ "$output" = "`printf '%s\n' insects mammals`" ] \
		&& echo pass
	)
		
output=$(
		printf '%s\n' squirrel rabbit ant \
		| ./index -f`temp` -c \
			-kmammals -t$mammals -i \
			-kinsects -t$insects -i \
			-t- -s
		)
check \
	'Prefers multiple matches over repeated' \
	`[ "$output" = mammals ] && echo pass`

exit $fails
