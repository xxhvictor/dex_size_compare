# dex_size_compare
dex_compare.sh [options]

1) 比较两个dex文件里面的class文件的size, 最后输出到一个csv文件中。
2) 比较方式是用dex1里面同名的class文件的size减去dex2里面同名的class文件的size。

最后输出的csv文件的格式是:
Class Name     Size Diff(dex1 - dex2)     Type(Diff,Add,Remove)
com.aa.bb      1                          Diff
com.aa.bc      -1                         Diff
com.aa.cc      2                          Add
com.aa.dd      -3                         Remove
csv文件说明:
第一条记录说明类com.aa.bb都存在于dex1和dex2中，且dex1中对应的class比dex2中对应的大1KB
第二条记录说明类com.aa.bc都存在于dex1和dex2中，且dex1中对应的class比dex2中对应的小1KB
第三条记录说明类com.aa.cc是dex1相对于dex2新增的类，且该类的size为2KB
第四条记录说明类com.aa.dd是dex1相对于dex2移除的类，且该类的siez为3KB

参数说明:
--dex1   设置用于比较的第一个dex文件
--map1   设置第一个dex文件的mapping文件，如果class文件没有被proguard，可以不设置
--dex2   设置用于比较的第二个dex文件
--map2   设置第二个dex文件的mapping文件，如果class文件没有被proguard，可以不设置
--result 设置输出的对比csv文件的路径
--type   设置文件大小类型：默认是class，即dex解码后的class文件的大小。dex：类在dex里面的
         大小；zip：类转化成dex后再压缩的大小。设置不同type可以从不同维度比较大小

举例比较zip压缩后的大小:<br/>
dex_compare.sh --dex1 a.dex --map1 a.maping --dex2 b.dex --map2 b.mapping --type zip --result result.csv
