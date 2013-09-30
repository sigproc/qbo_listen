#!/bin/bash
#
# Software License Agreement (GPLv2 License)
#
# Copyright (c) 2012-2013 TheCorpora SL
#
# This program is free software; you can redistribute it and/or 
# modify it under the terms of the GNU General Public License as 
# published by the Free Software Foundation; either version 2 of
# the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of 
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. 
# See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License 
# along with this program; if not, write to the Free Software 
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, 
# MA 02110-1301, USA.
#
# Authors: Sergio Merino <s.merino@openqbo.com>;

# Search the ROS package path for the qbo_listen package
while IFS=':' read -ra _base; do
  if [ -d "$_base/qbo_listen/" ]; then
    dir="$_base/qbo_listen/"
  fi
done <<< "$ROS_PACKAGE_PATH"

acousticdir="/usr/share/qbo-julius-model/"
tmpfile=/var/tmp/juliusdialog.tmp
amdir=$acousticdir
lmdir=$dir/config/LM/
tmpfile="/tmp/tmpfile"
gengram=$dir/config/bin/gen_grammar.py

Ramdir=$acousticdir
Rlmdir=LM/

preconfigfile=$dir/config/configfile/default.jconf

finalconfigfile=$dir/config/julius.jconf

function createConfFile {
IFS=$'\n'
> $tmpfile
languages=`find $lmdir -mindepth 1 -maxdepth 1 -type d`
for line_ in $languages; do
	line=`basename $line_`
        echo "-AM $line" >> $tmpfile
#        echo "-ssload noiseSpec" >> $tmpfile
        echo "-h $Ramdir$line/hmmdefs" >> $tmpfile
        echo "-hlist $Ramdir$line/tiedlist" >> $tmpfile
	echo "" >> $tmpfile
	LMs=`find $lmdir/$line -mindepth 1 -maxdepth 1 -type d`
        for lm_ in $LMs; do
		lm=`basename $lm_`
		echo "-LM $line$lm" >> $tmpfile

#		if [ $lm != "default" ]
#		then
		#	echo "-gram $Rlmdir$line/default/default" >> $tmpfile
#		fi

		echo "-gram $Rlmdir$line/$lm/$lm" >> $tmpfile
		echo "" >> $tmpfile
		echo "-SR "$line"_"$lm" "$line" "$line$lm >> $tmpfile
		echo "" >> $tmpfile
	done
        echo "" >> $tmpfile
        echo "" >> $tmpfile

done

cat $preconfigfile $tmpfile > $finalconfigfile
}



function compileLMs {
IFS=$'\n'

languages=`find $amdir -mindepth 1 -maxdepth 1 -type d`
for line_ in $languages; do
	line=`basename $line_`
	LMs=`find $lmdir/$line -mindepth 1 -maxdepth 1 -type d`
	for lm_ in $LMs; do
		lm=`basename $lm_`
		echo "---------------------------------------------------------------------------------------------------------------"
		echo "Next To Process:"
		echo "  Language: $line"
		echo "  Grammar:  $lm"
                echo "---------------------------------------------------------------------------------------------------------------"
		YN="Null"
		while [ $YN = "Null" ]
		do
                        if [ "$1" == "force" ]; then
                            YN="y"
                        else
                            echo "Do you want to compile this grammar?(y/n)"
       			    read YN
                        fi
			if [ "$YN" = "y" -o "$YN" = "Y" ]
			then
				$gengram $lmdir$line/$lm/sentences.conf $amdir$line/phonems $amdir$line/tiedlist $lmdir$line/$lm/$lm
			elif [ "$YN" = "n" -o "$YN" = "N" ]
			then
				echo "Continue with the next grammar..."
			else
				echo "Error"
				YN="Null"
			fi
		done
	done

done
}


cd "$dir/config/bin"
if [ "$1" == "-f" ]; then
    compileLMs "force"
else
    compileLMs
fi
createConfFile

