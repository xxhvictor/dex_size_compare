#! /usr/bin/env bash
script_path=$(cd "$(dirname "$(readlink -e "${BASH_SOURCE[0]}")")" && pwd)

# utility functions
run() {
  echo "[ Exec] ${COLF_BLUE}${*}${COL_RESET}"
  "$@"
}

check_run() {
  run "$@"
  local ret=$?
  [[ $ret -eq 0 ]] && return 0
  echo "${BASH_SOURCE[1]}:${BASH_LINENO[0]}:${FUNCNAME[1]}: error: ${*}" >&2
  exit $ret
}

# 解析参数.
THIS="$(basename "$0")"
usage() {
  cat <<!
${THIS} [options]

1) 比较两个dex文件里面的class文件的size, 最后输出到一个csv文件中。
2) 比较方式是用dex1里面同名的class文件的size减去dex2里面同名的class文件的size。

最后输出的csv文件的格式是：
Class Name     Size Diff(dex1 - dex2)     Type(Diff,Add,Remove)
com.aa.bb      1                          Diff
com.aa.bc      -1                         Diff
com.aa.cc      2                          Add
com.aa.dd      -3                         Remove
csv文件说明：
第一条记录说明类com.aa.bb都存在于dex1和dex2中，且dex1中对应的class比dex2中对应的大1KB
第二条记录说明类com.aa.bc都存在于dex1和dex2中，且dex1中对应的class比dex2中对应的小1KB
第三条记录说明类com.aa.cc是dex1相对于dex2新增的类，且该类的size为2KB
第四条记录说明类com.aa.dd是dex1相对于dex2移除的类，且该类的siez为3KB


参数说明：
--dex1   设置用于比较的第一个dex文件
--map1   设置第一个dex文件的mapping文件，如果class文件没有被proguard，可以不设置
--dex2   设置用于比较的第二个dex文件
--map2   设置第二个dex文件的mapping文件，如果class文件没有被proguard，可以不设置
--result 设置输出的对比csv文件的路径
--type   设置文件大小类型：默认是class，即dex解码后的class文件的大小。dex：类在dex里面的
         大小；zip：类转化成dex后再压缩的大小。设置不同type可以从不同维度比较大小

举例比较zip压缩后的大小：
${THIS} --dex1 a.dex --map1 a.maping --dex2 b.dex --map2 b.mapping --type zip --result result.csv
!
}

BUILD_ARGS="$(getopt -o 'h' --long help,dex1:,map1:,dex2:,map2:,result:,type: -- "$@")"
[[ $? != "0" ]] && exit 1
eval set -- "$BUILD_ARGS"

dex_1_path=
dex_1_mapping=
dex_2_path=
dex_2_mapping=
result_file=
type="class"

while :; do
  case "$1" in
    -h|--help)
        usage; exit 0
        shift ;;
    --dex1)
        dex_1_path="$2"
        shift 2;;
    --map1)
        dex_1_mapping="$2"
        shift 2;;
    --dex2)
        dex_2_path="$2"
        shift 2;;
    --map2)
        dex_2_mapping="$2"
        shift 2;;
    --result)
        result_file="$2"
        shift 2;;
    --type)
        type="$2"
        shift 2;;
    --)
        shift; break;;
    *) usage; exit 0
  esac
done

if [ -z "$dex_1_path" -o -z "$dex_2_path" -o -z "$result_file" ]; then
    echo "必须设置参数:--dex1 --dex2 --result"
    exit 1
fi

# make working space
tmp_dir=`mktemp -d`

# clean working space when exit
clean_exit () {
  rm -r $tmp_dir
  trap "" EXIT
  exit $1
}
# Ensure clean exit on Ctrl-C or normal exit.
trap "clean_exit 1" INT HUP QUIT TERM
trap "clean_exit \$?" EXIT

# dex2jar
dex2jar="$script_path/dex2jar-2.0/d2j-dex2jar.sh"
check_run $dex2jar -o "$tmp_dir/dex1.jar" $dex_1_path
check_run $dex2jar -o "$tmp_dir/dex2.jar" $dex_2_path

# zip dex and get zipped size
check_run zip "$tmp_dir/dex1.zip" $dex_1_path
check_run zip "$tmp_dir/dex2.zip" $dex_2_path
dex1_zip_size=`stat --printf="%s" "$tmp_dir/dex1.zip"`
dex2_zip_size=`stat --printf="%s" "$tmp_dir/dex2.zip"`
echo $dex1_zip_size
echo $dex2_zip_size

# unzip
dex1_unzip_class_dir="$tmp_dir/classes1"
check_run unzip "$tmp_dir/dex1.jar" -d "$dex1_unzip_class_dir" > /dev/null
dex2_unzip_class_dir="$tmp_dir/classes2"
check_run unzip "$tmp_dir/dex2.jar" -d "$dex2_unzip_class_dir" > /dev/null

# get kinds of size
# zip dex and get zipped size
dex1_size=`stat --printf="%s" "$dex_1_path"`
dex2_size=`stat --printf="%s" "$dex_2_path"`
# get dex size
check_run zip "$tmp_dir/dex1.zip" $dex_1_path
check_run zip "$tmp_dir/dex2.zip" $dex_2_path
dex1_zip_size=`stat --printf="%s" "$tmp_dir/dex1.zip"`
dex2_zip_size=`stat --printf="%s" "$tmp_dir/dex2.zip"`
# get decoded class size
dex1_class_size=`"$script_path/get_unzip_total_size.py" "$dex1_unzip_class_dir"`
dex2_class_size=`"$script_path/get_unzip_total_size.py" "$dex2_unzip_class_dir"`
echo "================================================"
echo "dex1_size:" $dex1_size
echo "dex2_size:" $dex2_size
echo "dex1_zip_size:" $dex1_zip_size
echo "dex2_zip_size:" $dex2_zip_size
echo "dex1_class_size:" $dex1_class_size
echo "dex2_class_size:" $dex2_class_size
echo "================================================"

# rename classes file name
dex1_rename_class_dir="$dex1_unzip_class_dir"
if [ ! -z "$dex_1_mapping" ]; then
    cat "$dex_1_mapping" | grep "^[_a-zA-Z]" > "$tmp_dir/dex_1_mapping_simple.txt"
    dex1_rename_class_dir="$tmp_dir/classes1_renamed"
    check_run python "$script_path/rename_with_mapping_file.py" \
        "$dex1_unzip_class_dir" "$tmp_dir/dex_1_mapping_simple.txt" "$dex1_rename_class_dir"
fi

dex2_rename_class_dir="$dex2_unzip_class_dir"
if [ ! -z "$dex_2_mapping" ]; then
    cat "$dex_2_mapping" | grep "^[_a-zA-Z]" > "$tmp_dir/dex_2_mapping_simple.txt"
    dex2_rename_class_dir="$tmp_dir/classes2_renamed"
    check_run python "$script_path/rename_with_mapping_file.py" \
        "$dex2_unzip_class_dir" "$tmp_dir/dex_2_mapping_simple.txt" "$dex2_rename_class_dir"
fi

# get classes size
dex1_file_size_scale="1"
dex2_file_size_scale="1"
if [ "$type" == "dex" ]; then
    dex1_file_size_scale=`awk 'BEGIN{printf "%.3f\n",('$dex1_size'/'$dex1_class_size')}'`
    dex2_file_size_scale=`awk 'BEGIN{printf "%.3f\n",('$dex2_size'/'$dex2_class_size')}'`
elif [ "$type" == "zip" ]; then
    dex1_file_size_scale=`awk 'BEGIN{printf "%.3f\n",('$dex1_zip_size'/'$dex1_class_size')}'`
    dex2_file_size_scale=`awk 'BEGIN{printf "%.3f\n",('$dex2_zip_size'/'$dex2_class_size')}'`
elif [ "$type" == "class" ]; then
    dex1_file_size_scale="1"
    dex2_file_size_scale="1"
else
    echo "Cann't find right compare type, and will exit"
    exit 1
fi
echo "dex1_file_size_scale:" $dex1_file_size_scale
echo "dex2_file_size_scale:" $dex2_file_size_scale

check_run python "$script_path/export_file_size.py" "$dex1_rename_class_dir" "$tmp_dir/dex1_file_size.csv" "$dex1_file_size_scale"
check_run python "$script_path/export_file_size.py" "$dex2_rename_class_dir" "$tmp_dir/dex2_file_size.csv" "$dex2_file_size_scale"

# export classes size diff
check_run python "$script_path/export_file_size_diff.py" "$tmp_dir/dex1_file_size.csv" "$tmp_dir/dex2_file_size.csv" "$tmp_dir/dex1_minus_dex2.csv"
check_run cp "$tmp_dir/dex1_minus_dex2.csv" "$result_file"
echo "*** Open file:$result_file to get result ***"
echo "*** Succeed!!! ***"
